<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Pass;
use App\Models\PassTemplate;
use App\Models\PassType;
use App\Services\PrintPassService;
use App\Services\QrSignatureService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PassController extends Controller
{
    public function index(Event $event, Request $request)
    {
        $this->authorize('view', $event);

        $query = $event->passes()->with('passType');

        return response()->json($query->paginate(15));
    }

    public function store(Event $event, Request $request, QrSignatureService $signatureService)
    {
        $this->authorize('update', $event);

        $validated = $request->validate([
            'pass_type_id' => ['required', 'exists:pass_types,id'],
            'attendee_name' => ['nullable', 'string'],
            'company' => ['nullable', 'string'],
            'phone' => ['nullable', 'string'],
            'metadata' => ['nullable', 'array'],
        ]);

        $passType = PassType::where('id', $validated['pass_type_id'])
            ->where('event_id', $event->id)
            ->firstOrFail();

        $passUid = Str::upper(Str::random(16));
        $signature = $signatureService->generateSignature($passUid, $event->event_secret);

        $pass = Pass::create([
            'event_id' => $event->id,
            'pass_type_id' => $passType->id,
            'pass_uid' => $passUid,
            'signature' => $signature,
            'attendee_name' => $validated['attendee_name'] ?? null,
            'company' => $validated['company'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'metadata' => $validated['metadata'] ?? null,
            'scan_count' => 0,
            'status' => 'active',
        ]);

        return response()->json([
            'message' => 'Pass generated successfully',
            'pass' => $pass,
            'qr_data' => sprintf('GPX1|%s|%s', $passUid, $signature),
        ], 201);
    }

    public function show(Pass $pass)
    {
        $this->authorize('view', $pass->event);

        return response()->json($pass->load('passType'));
    }

    public function update(Request $request, Pass $pass)
    {
        $this->authorize('update', $pass->event);

        $validated = $request->validate([
            'attendee_name' => ['sometimes', 'nullable', 'string'],
            'company' => ['sometimes', 'nullable', 'string'],
            'phone' => ['sometimes', 'nullable', 'string'],
            'metadata' => ['sometimes', 'nullable', 'array'],
            'status' => ['sometimes', 'in:active,used,revoked'],
        ]);

        $pass->update($validated);

        return response()->json([
            'message' => 'Pass updated successfully',
            'pass' => $pass,
        ]);
    }

    public function destroy(Pass $pass)
    {
        $this->authorize('update', $pass->event);

        $pass->delete();

        return response()->json([
            'message' => 'Pass deleted successfully',
        ]);
    }

    public function bulkGenerate(Event $event, Request $request, QrSignatureService $signatureService)
    {
        $this->authorize('update', $event);

        if ($request->has('passes')) {
            $validated = $request->validate([
                'passes' => ['required', 'array', 'min:1'],
                'passes.*.pass_type_id' => ['required', 'exists:pass_types,id'],
                'passes.*.attendee_name' => ['nullable', 'string'],
                'passes.*.company' => ['nullable', 'string'],
                'passes.*.phone' => ['nullable', 'string'],
                'passes.*.metadata' => ['nullable', 'array'],
            ]);
            $inputPasses = $validated['passes'];
        } else {
            $validated = $request->validate([
                'count' => ['required', 'integer', 'min:1', 'max:1000'],
                'pass_type_id' => ['required', 'exists:pass_types,id'],
                'prefix' => ['nullable', 'string', 'max:20'],
            ]);
            $inputPasses = array_fill(0, $validated['count'], [
                'pass_type_id' => $validated['pass_type_id'],
            ]);
        }

        $results = [];

        foreach ($inputPasses as $payload) {
            $passType = PassType::where('id', $payload['pass_type_id'])
                ->where('event_id', $event->id)
                ->first();

            if (! $passType) {
                continue;
            }

            $passUid = ($validated['prefix'] ?? '').Str::upper(Str::random(16));
            $signature = $signatureService->generateSignature($passUid, $event->event_secret);

            $pass = Pass::create([
                'event_id' => $event->id,
                'pass_type_id' => $passType->id,
                'pass_uid' => $passUid,
                'signature' => $signature,
                'attendee_name' => $payload['attendee_name'] ?? null,
                'company' => $payload['company'] ?? null,
                'phone' => $payload['phone'] ?? null,
                'metadata' => $payload['metadata'] ?? null,
                'scan_count' => 0,
                'status' => 'active',
            ]);

            $results[] = [
                'pass' => $pass,
                'qr_data' => sprintf('GPX1|%s|%s', $passUid, $signature),
            ];
        }

        return response()->json([
            'message' => 'Bulk pass generation completed',
            'generated_count' => count($results),
            'results' => $results,
        ], 201);
    }

    public function printManifest(Event $event, Request $request, PrintPassService $printPassService)
    {
        $this->authorize('view', $event);

        $validated = $request->validate([
            'template_id' => ['nullable', 'exists:pass_templates,id'],
            'pass_ids' => ['nullable', 'array'],
            'pass_ids.*' => ['integer', 'exists:passes,id'],
        ]);

        $passes = $event->passes();

        if (! empty($validated['pass_ids'])) {
            $passes->whereIn('id', $validated['pass_ids']);
        }

        $passes = $passes->with('passType')->get();
        $template = null;

        if (! empty($validated['template_id'])) {
            $template = PassTemplate::where('id', $validated['template_id'])
                ->where('event_id', $event->id)
                ->first();
        }

        $manifest = $printPassService->buildPrintManifest($event, $passes->all(), $template);

        return response()->json([
            'message' => 'Print manifest generated successfully',
            'manifest' => $manifest,
        ]);
    }
}
