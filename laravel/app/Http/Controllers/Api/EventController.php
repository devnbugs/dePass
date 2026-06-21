<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Event;
use App\Models\Pass;
use App\Models\PassTemplate;
use App\Services\EventPackageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class EventController extends Controller
{
    /**
     * Get all events (filtered by role).
     *
     * @return JsonResponse
     */
    public function index(Request $request)
    {
        $query = Event::query();

        // Filter by organization if organizer or gateman
        if ($request->user()->role === 'organizer') {
            $query->where('organization_id', $request->user()->organization_id);
        } elseif ($request->user()->role === 'gateman') {
            // Gateman can see limited event info
            $query->where('status', 'active');
        }

        $events = $query->with('organization', 'creator')
            ->paginate(15);

        // Remove event_secret from gateman view
        if ($request->user()->role === 'gateman') {
            $events->makeHidden('event_secret');
        }

        return response()->json($events);
    }

    /**
     * Create a new event (organizer or super_admin).
     *
     * @return JsonResponse
     */
    public function store(Request $request)
    {
        if (! in_array($request->user()->role, ['organizer', 'super_admin'])) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $validated = $request->validate([
            'organization_id' => ['required', 'exists:organizations,id'],
            'name' => ['required', 'string'],
            'date' => ['required', 'date'],
            'location' => ['required', 'string'],
        ]);

        // Organizers can only create in their organization
        if ($request->user()->role === 'organizer' &&
            $validated['organization_id'] !== $request->user()->organization_id) {
            return response()->json([
                'message' => 'You can only create events in your organization',
            ], 403);
        }

        $event = Event::create([
            'organization_id' => $validated['organization_id'],
            'name' => $validated['name'],
            'date' => $validated['date'],
            'location' => $validated['location'],
            'event_secret' => Str::random(32), // For HMAC signature
            'status' => 'draft',
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Event created successfully',
            'event' => $event,
        ], 201);
    }

    /**
     * Get a specific event.
     *
     * @return JsonResponse
     */
    public function show(Event $event, Request $request)
    {
        $this->authorize('view', $event);

        $event->load('organization', 'creator', 'passTypes', 'passes');

        // Hide secret from gateman
        if ($request->user()->role === 'gateman') {
            $event->makeHidden('event_secret');
        }

        return response()->json($event);
    }

    /**
     * Update an event.
     *
     * @return JsonResponse
     */
    public function update(Event $event, Request $request)
    {
        // Only creator or super_admin can edit
        if ($request->user()->id !== $event->created_by && $request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        // Cannot edit locked event
        if ($event->status === 'locked') {
            return response()->json([
                'message' => 'Cannot edit a locked event',
            ], 422);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string',
            'date' => 'sometimes|date',
            'location' => 'sometimes|string',
        ]);

        $event->update($validated);

        return response()->json([
            'message' => 'Event updated successfully',
            'event' => $event,
        ]);
    }

    /**
     * Lock an event (super_admin only).
     *
     * @return JsonResponse
     */
    public function lock(Event $event, Request $request)
    {
        $this->authorize('lock', $event);

        $event->update(['status' => 'locked']);

        return response()->json([
            'message' => 'Event locked successfully',
            'event' => $event,
        ]);
    }

    /**
     * Delete an event (super_admin only).
     *
     * @return JsonResponse
     */
    public function destroy(Event $event, Request $request)
    {
        $this->authorize('delete', $event);

        $event->delete();

        return response()->json([
            'message' => 'Event deleted successfully',
        ]);
    }

    public function stats(Request $request)
    {
        $eventQuery = Event::query();
        $passQuery = Pass::query();

        if ($request->user()->role === 'organizer') {
            $eventQuery->where('organization_id', $request->user()->organization_id);
            $passQuery->whereHas('event', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
        } elseif ($request->user()->role === 'gateman') {
            $eventQuery->where('status', 'active');
            $passQuery->whereHas('event', function ($query) {
                $query->where('status', 'active');
            });
        }

        $events = $eventQuery->count();
        $passes = $passQuery->count();

        $deviceQuery = Device::where('status', 'approved');
        $pendingDeviceQuery = Device::where('status', 'pending');
        $templateQuery = PassTemplate::query();

        if ($request->user()->role === 'organizer') {
            $deviceQuery->whereHas('user', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
            $pendingDeviceQuery->whereHas('user', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
            $templateQuery->whereHas('event', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
        } elseif ($request->user()->role === 'gateman') {
            $deviceQuery->whereHas('user', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
            $pendingDeviceQuery->whereHas('user', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
            $templateQuery->whereHas('event', function ($query) {
                $query->where('status', 'active');
            });
        }

        return response()->json([
            'events' => $events,
            'passes' => $passes,
            'devices' => $deviceQuery->count(),
            'pending_devices' => $pendingDeviceQuery->count(),
            'templates' => $templateQuery->count(),
        ]);
    }

    public function package(Event $event, Request $request, EventPackageService $packageService)
    {
        $this->authorize('package', $event);

        $validated = $request->validate([
            'device_uuid' => ['required', 'string'],
        ]);

        $deviceQuery = Device::where('uuid', $validated['device_uuid'])
            ->where('status', 'approved');

        if ($request->user()->role !== 'super_admin') {
            $deviceQuery->where('user_id', $request->user()->id);
        }

        $device = $deviceQuery->first();

        if (! $device) {
            return response()->json([
                'message' => 'Approved device not found or not authorized',
            ], 404);
        }

        $package = $packageService->buildPackage($event, $device);

        return response()->json([
            'event_package' => $package,
            'format' => 'encrypted',
            'encryption' => $device->public_key ? 'device_public_key' : 'laravel_app_key',
        ]);
    }
}
