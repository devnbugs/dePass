<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Event;
use App\Models\Pass;
use App\Models\Scan;
use App\Services\EventPackageService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DeviceSyncController extends Controller
{
    public function profile(Request $request)
    {
        $device = Device::where('user_id', $request->user()->id)
            ->where('status', 'approved')
            ->with('user')
            ->first();

        if (! $device) {
            return response()->json([
                'message' => 'No approved device found',
            ], 404);
        }

        return response()->json([
            'device' => $device,
            'user' => $request->user()->makeHidden(['password', 'passkey_public_key']),
            'sync_status' => 'ready',
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function sync(Request $request)
    {
        $validated = $request->validate([
            'last_synced_at' => ['nullable', 'date'],
            'scans' => ['nullable', 'array'],
            'scans.*.pass_uid' => ['required_with:scans', 'string'],
            'scans.*.device_uuid' => ['required_with:scans', 'string'],
            'scans.*.scan_result' => ['required_with:scans', 'in:valid,invalid,duplicate,error'],
            'scans.*.scanned_at' => ['required_with:scans', 'date'],
            'scans.*.location_zone' => ['nullable', 'string'],
            'scans.*.metadata' => ['nullable', 'array'],
        ]);

        $recorded = 0;

        if (! empty($validated['scans'])) {
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
        }

        return response()->json([
            'server_time' => now()->toIso8601String(),
            'device_status' => 'active',
            'pending_updates' => [],
            'synced' => true,
            'scans_recorded' => $recorded,
        ]);
    }

    public function downloadPackage(Request $request, EventPackageService $packageService)
    {
        $device = Device::where('user_id', $request->user()->id)
            ->where('status', 'approved')
            ->first();

        if (! $device) {
            return response()->json([
                'message' => 'No approved device found',
            ], 404);
        }

        $events = Event::whereHas('organization', function ($q) use ($request) {
            $q->where('id', $request->user()->organization_id);
        })->where('status', 'active')->get();

        $packages = [];

        foreach ($events as $event) {
            $packages[] = [
                'event_id' => $event->id,
                'event_name' => $event->name,
                'package' => $packageService->buildPackage($event, $device),
            ];
        }

        return response()->json([
            'packages' => $packages,
            'format' => 'encrypted',
        ]);
    }
}
