<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Pass;
use App\Models\Scan;
use App\Services\QrSignatureService;
use Illuminate\Http\Request;

class QrValidationController extends Controller
{
    public function verify(Request $request, QrSignatureService $signatureService)
    {
        $validated = $request->validate([
            'qr_data' => ['required', 'string'],
            'device_uuid' => ['required', 'string'],
        ]);

        $parts = explode('|', $validated['qr_data']);

        if (count($parts) !== 3 || $parts[0] !== 'GPX1') {
            return response()->json([
                'valid' => false,
                'message' => 'Invalid QR code format',
            ]);
        }

        $passUid = $parts[1];
        $signature = $parts[2];

        $pass = Pass::where('pass_uid', $passUid)->with('event', 'passType')->first();

        if (! $pass) {
            return response()->json([
                'valid' => false,
                'message' => 'Pass not found',
            ]);
        }

        $device = Device::where('uuid', $validated['device_uuid'])
            ->where('status', 'approved')
            ->first();

        $validResult = true;
        $message = 'Pass is valid';

        if (! $signatureService->validateSignature($passUid, $signature, $pass->event->event_secret)) {
            $validResult = false;
            $message = 'Invalid pass signature';
        } elseif ($pass->status !== 'active') {
            $validResult = false;
            $message = 'Pass status is '.$pass->status;
        } elseif ($pass->passType && $pass->scan_count >= $pass->passType->entry_limit) {
            $validResult = false;
            $message = 'Pass entry limit reached';
        }

        $scanResult = $validResult ? 'valid' : 'invalid';

        $scan = Scan::create([
            'pass_id' => $pass->id,
            'device_id' => $device?->id,
            'scan_result' => $scanResult,
            'scanned_at' => now(),
        ]);

        if ($validResult) {
            $pass->increment('scan_count');
        }

        return response()->json([
            'valid' => $validResult,
            'pass' => $pass->load('passType'),
            'message' => $message,
            'scan_id' => $scan->id,
        ]);
    }
}
