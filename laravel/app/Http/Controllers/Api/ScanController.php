<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Pass;
use App\Models\Scan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ScanController extends Controller
{
    public function index(Request $request)
    {
        $query = Scan::with('pass', 'device');

        if ($request->user()->role === 'organizer') {
            $query->whereHas('pass', function ($q) use ($request) {
                $q->whereHas('event', function ($q) use ($request) {
                    $q->where('organization_id', $request->user()->organization_id);
                });
            });
        } elseif ($request->user()->role === 'gateman') {
            $query->whereHas('device', function ($q) use ($request) {
                $q->where('user_id', $request->user()->id);
            });
        }

        if ($request->filled('pass_id')) {
            $query->where('pass_id', $request->pass_id);
        }

        if ($request->filled('device_id')) {
            $query->where('device_id', $request->device_id);
        }

        if ($request->filled('event_id')) {
            $query->whereHas('pass', function ($q) use ($request) {
                $q->where('event_id', $request->event_id);
            });
        }

        if ($request->filled('scan_result')) {
            $query->where('scan_result', $request->scan_result);
        }

        if ($request->filled('date_from')) {
            $query->where('scanned_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->where('scanned_at', '<=', $request->date_to);
        }

        return response()->json($query->latest('scanned_at')->paginate(25));
    }

    public function show(Scan $scan)
    {
        $this->authorize('view', $scan);

        return response()->json($scan->load('pass', 'device'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'pass_uid' => ['required', 'string'],
            'device_uuid' => ['required', 'string'],
            'scan_result' => ['required', 'in:valid,invalid,duplicate,error'],
            'scanned_at' => ['required', 'date'],
            'location_zone' => ['nullable', 'string'],
            'metadata' => ['nullable', 'array'],
        ]);

        $pass = Pass::where('pass_uid', $validated['pass_uid'])->first();

        if (! $pass) {
            return response()->json([
                'message' => 'Pass not found',
            ], 404);
        }

        $device = Device::where('uuid', $validated['device_uuid'])
            ->where('status', 'approved')
            ->first();

        if (! $device) {
            return response()->json([
                'message' => 'Approved device not found',
            ], 404);
        }

        $scan = Scan::create([
            'pass_id' => $pass->id,
            'device_id' => $device->id,
            'scan_result' => $validated['scan_result'],
            'scanned_at' => $validated['scanned_at'],
            'location_zone' => $validated['location_zone'] ?? null,
            'metadata' => $validated['metadata'] ?? null,
        ]);

        if ($validated['scan_result'] === 'valid') {
            $pass->increment('scan_count');
        }

        return response()->json([
            'message' => 'Scan recorded successfully',
            'scan' => $scan->load('pass', 'device'),
        ], 201);
    }

    public function batchStore(Request $request)
    {
        $validated = $request->validate([
            'scans' => ['required', 'array', 'max:100'],
            'scans.*.pass_uid' => ['required', 'string'],
            'scans.*.device_uuid' => ['required', 'string'],
            'scans.*.scan_result' => ['required', 'in:valid,invalid,duplicate,error'],
            'scans.*.scanned_at' => ['required', 'date'],
            'scans.*.location_zone' => ['nullable', 'string'],
            'scans.*.metadata' => ['nullable', 'array'],
        ]);

        $recorded = 0;

        DB::transaction(function () use ($validated, &$recorded) {
            foreach ($validated['scans'] as $payload) {
                $pass = Pass::where('pass_uid', $payload['pass_uid'])->first();
                $device = Device::where('uuid', $payload['device_uuid'])
                    ->where('status', 'approved')
                    ->first();

                if (! $pass || ! $device) {
                    continue;
                }

                $scan = Scan::create([
                    'pass_id' => $pass->id,
                    'device_id' => $device->id,
                    'scan_result' => $payload['scan_result'],
                    'scanned_at' => $payload['scanned_at'],
                    'location_zone' => $payload['location_zone'] ?? null,
                    'metadata' => $payload['metadata'] ?? null,
                ]);

                if ($payload['scan_result'] === 'valid') {
                    $pass->increment('scan_count');
                }

                $recorded++;
            }
        });

        return response()->json([
            'message' => "{$recorded} scans recorded successfully",
            'recorded_count' => $recorded,
        ]);
    }

    public function destroy(Scan $scan, Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $scan->delete();

        return response()->json([
            'message' => 'Scan deleted successfully',
        ]);
    }
}
