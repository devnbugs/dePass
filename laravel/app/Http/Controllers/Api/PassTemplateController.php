<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\PassTemplate;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PassTemplateController extends Controller
{
    public function index(Event $event, Request $request)
    {
        $this->authorize('view', $event);

        return response()->json($event->passTemplates()->paginate(15));
    }

    public function store(Event $event, Request $request)
    {
        $this->authorize('update', $event);

        $validated = $request->validate([
            'name' => ['required', 'string'],
            'template_file' => ['required', 'file', 'mimes:pdf,png,jpg,jpeg'],
            'layout' => ['nullable', 'json'],
        ]);

        $file = $request->file('template_file');
        $path = $file->store('pass_templates', 'public');

        $template = PassTemplate::create([
            'event_id' => $event->id,
            'name' => $validated['name'],
            'file_name' => $file->getClientOriginalName(),
            'file_path' => $path,
            'content_type' => $file->getMimeType(),
            'file_size' => $file->getSize(),
            'layout' => json_decode($validated['layout'] ?? 'null', true),
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Template uploaded successfully',
            'template' => $template,
        ], 201);
    }

    public function show(PassTemplate $template)
    {
        $this->authorize('view', $template->event);

        return response()->json($template);
    }

    public function update(Request $request, PassTemplate $template)
    {
        $this->authorize('update', $template->event);

        $validated = $request->validate([
            'name' => ['sometimes', 'string'],
            'layout' => ['sometimes', 'json'],
        ]);

        $template->update([
            'name' => $validated['name'] ?? $template->name,
            'layout' => array_key_exists('layout', $validated) ? json_decode($validated['layout'], true) : $template->layout,
        ]);

        return response()->json([
            'message' => 'Template updated successfully',
            'template' => $template,
        ]);
    }

    public function destroy(PassTemplate $template)
    {
        $this->authorize('update', $template->event);

        Storage::disk('public')->delete($template->file_path);
        $template->delete();

        return response()->json([
            'message' => 'Template deleted successfully',
        ]);
    }
}
