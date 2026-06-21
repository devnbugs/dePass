<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Pass;
use App\Models\PassType;
use App\Services\QrWizardService;
use Illuminate\Http\Request;

class QrWizardController extends Controller
{
    public function __construct(
        private readonly QrWizardService $wizardService,
    ) {}

    public function themes()
    {
        return response()->json([
            'themes' => $this->wizardService->getThemes(),
        ]);
    }

    public function generate(Request $request)
    {
        $validated = $request->validate([
            'event_id' => ['required', 'exists:events,id'],
            'pass_type_id' => ['required', 'exists:pass_types,id'],
            'attendee_name' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'company' => ['nullable', 'string', 'max:255'],
            'metadata' => ['nullable', 'array'],
            'theme' => ['nullable', 'string', 'in:classic,neon,gold,ocean'],
        ]);

        $event = Event::findOrFail($validated['event_id']);
        $this->authorize('update', $event);

        $passType = PassType::where('id', $validated['pass_type_id'])
            ->where('event_id', $event->id)
            ->firstOrFail();

        $theme = $validated['theme'] ?? 'classic';
        $serial = $this->wizardService->getNextSerial();
        $gpid = $this->wizardService->generateGpid($serial);

        $qrResult = $this->wizardService->generateQrData($gpid, $event->event_secret);

        $pass = Pass::create([
            'event_id' => $event->id,
            'pass_type_id' => $passType->id,
            'pass_uid' => $gpid,
            'signature' => $qrResult['signature'],
            'attendee_name' => $validated['attendee_name'] ?? null,
            'company' => $validated['company'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'metadata' => array_merge($validated['metadata'] ?? [], [
                'theme' => $theme,
                'serial' => $serial,
                'gpid' => $gpid,
            ]),
            'scan_count' => 0,
            'status' => 'active',
        ]);

        $qrImage = $this->wizardService->generateQrImage($qrResult['qr_data'], $theme);

        return response()->json([
            'message' => 'QR code generated successfully',
            'pass' => $pass,
            'gpid' => $gpid,
            'qr_data' => $qrResult['qr_data'],
            'qr_image' => $qrImage,
            'theme' => $theme,
        ], 201);
    }

    public function bulkGenerate(Request $request)
    {
        $validated = $request->validate([
            'event_id' => ['required', 'exists:events,id'],
            'pass_type_id' => ['required', 'exists:pass_types,id'],
            'count' => ['required', 'integer', 'min:1', 'max:500'],
            'prefix' => ['nullable', 'string', 'max:10'],
            'theme' => ['nullable', 'string', 'in:classic,neon,gold,ocean'],
            'attendee_name' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'metadata' => ['nullable', 'array'],
        ]);

        $event = Event::findOrFail($validated['event_id']);
        $this->authorize('update', $event);

        $passType = PassType::where('id', $validated['pass_type_id'])
            ->where('event_id', $event->id)
            ->firstOrFail();

        $theme = $validated['theme'] ?? 'classic';
        $prefix = $validated['prefix'] ?? 'GPX';

        $entries = [];
        $passes = [];

        for ($i = 0; $i < $validated['count']; $i++) {
            $serial = $this->wizardService->getNextSerial();
            $gpid = $this->wizardService->generateGpid($serial, $prefix);

            $name = $validated['attendee_name'] ?? null;
            if ($name && $validated['count'] > 1) {
                $name = $name.' #'.($i + 1);
            }

            $qrResult = $this->wizardService->generateQrData($gpid, $event->event_secret);
            $qrImage = $this->wizardService->generateQrImage($qrResult['qr_data'], $theme);

            $pass = Pass::create([
                'event_id' => $event->id,
                'pass_type_id' => $passType->id,
                'pass_uid' => $gpid,
                'signature' => $qrResult['signature'],
                'attendee_name' => $name,
                'company' => null,
                'phone' => $validated['phone'] ?? null,
                'metadata' => array_merge($validated['metadata'] ?? [], [
                    'theme' => $theme,
                    'serial' => $serial,
                    'gpid' => $gpid,
                ]),
                'scan_count' => 0,
                'status' => 'active',
            ]);

            $passes[] = $pass;

            $entries[] = [
                'gpid' => $gpid,
                'name' => $name ?? '',
                'phone' => $validated['phone'] ?? '',
                'theme' => $theme,
                'qr_data' => $qrResult['qr_data'],
                'qr_image_base64' => $qrImage,
            ];
        }

        if ($validated['count'] === 1) {
            return response()->json([
                'message' => 'QR code generated successfully',
                'pass' => $passes[0],
                'gpid' => $entries[0]['gpid'],
                'qr_data' => $entries[0]['qr_data'],
                'qr_image' => $entries[0]['qr_image_base64'],
                'theme' => $theme,
            ], 201);
        }

        $zipPath = $this->wizardService->buildZip($entries, $prefix);

        return response()->download($zipPath, $prefix.'_qrcodes.zip', [
            'Content-Type' => 'application/zip',
        ])->deleteFileAfterSend();
    }
}
