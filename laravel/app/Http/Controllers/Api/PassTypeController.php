<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\PassType;
use Illuminate\Http\Request;

class PassTypeController extends Controller
{
    public function index(Event $event, Request $request)
    {
        $this->authorize('view', $event);

        $query = $event->passTypes();

        if ($request->user()->role === 'organizer') {
            $query->where('event_id', $event->id);
        }

        return response()->json($query->paginate(15));
    }

    public function store(Event $event, Request $request)
    {
        $this->authorize('update', $event);

        $validated = $request->validate([
            'name' => ['required', 'string'],
            'entry_limit' => ['nullable', 'integer', 'min:1'],
            'access_zones' => ['nullable', 'array'],
            'date_restrictions' => ['nullable', 'array'],
            'time_restrictions' => ['nullable', 'array'],
        ]);

        $passType = PassType::create([
            'event_id' => $event->id,
            'name' => $validated['name'],
            'entry_limit' => $validated['entry_limit'] ?? null,
            'access_zones' => $validated['access_zones'] ?? null,
            'date_restrictions' => $validated['date_restrictions'] ?? null,
            'time_restrictions' => $validated['time_restrictions'] ?? null,
        ]);

        return response()->json([
            'message' => 'Pass type created successfully',
            'pass_type' => $passType,
        ], 201);
    }

    public function show(PassType $passType)
    {
        $this->authorize('view', $passType->event);

        return response()->json($passType);
    }

    public function update(Request $request, PassType $passType)
    {
        $this->authorize('update', $passType->event);

        $validated = $request->validate([
            'name' => ['sometimes', 'string'],
            'entry_limit' => ['sometimes', 'nullable', 'integer', 'min:1'],
            'access_zones' => ['sometimes', 'nullable', 'array'],
            'date_restrictions' => ['sometimes', 'nullable', 'array'],
            'time_restrictions' => ['sometimes', 'nullable', 'array'],
        ]);

        $passType->update($validated);

        return response()->json([
            'message' => 'Pass type updated successfully',
            'pass_type' => $passType,
        ]);
    }

    public function destroy(PassType $passType)
    {
        $this->authorize('update', $passType->event);

        $passType->delete();

        return response()->json([
            'message' => 'Pass type deleted successfully',
        ]);
    }
}
