<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\User;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function publicRegister(Request $request)
    {
        $validated = $request->validate([
            'uuid' => ['required', 'uuid'],
            'username' => ['required', 'string', 'exists:users,username'],
            'public_key' => ['nullable', 'string'],
            'device_fingerprint' => ['nullable', 'string'],
        ]);

        $user = User::where('username', $validated['username'])->firstOrFail();
        $device = Device::where('uuid', $validated['uuid'])->first();

        if ($device && $device->user_id && $device->user_id !== $user->id) {
            return response()->json([
                'message' => 'This device is already registered to another user.',
                'device' => $device,
            ], 409);
        }

        if (!$device) {
            $device = Device::create([
                'user_id' => $user->id,
                'uuid' => $validated['uuid'],
                'public_key' => $validated['public_key'] ?? null,
                'device_fingerprint' => $validated['device_fingerprint'] ?? null,
                'status' => 'pending',
            ]);
        } elseif ($device->status === 'pending') {
            $device->update([
                'user_id' => $user->id,
                'public_key' => $validated['public_key'] ?? $device->public_key,
                'device_fingerprint' => $validated['device_fingerprint'] ?? $device->device_fingerprint,
            ]);
        }

        return response()->json([
            'message' => $device->status === 'approved'
                ? 'Device already approved'
                : 'Device registration pending approval',
            'device' => $device->fresh('user', 'approver'),
        ], $device->wasRecentlyCreated ? 201 : 200);
    }

    public function publicStatus(Request $request)
    {
        $validated = $request->validate([
            'uuid' => ['required', 'uuid'],
            'username' => ['required', 'string', 'exists:users,username'],
        ]);

        $user = User::where('username', $validated['username'])->firstOrFail();
        $device = Device::where('uuid', $validated['uuid'])
            ->where('user_id', $user->id)
            ->first();

        if (!$device) {
            return response()->json([
                'message' => 'Device is not registered for this user.',
                'status' => 'unregistered',
            ], 404);
        }

        return response()->json([
            'message' => match ($device->status) {
                'approved' => 'Device approved',
                'revoked' => 'Device revoked',
                default => 'Device registration pending approval',
            },
            'status' => $device->status,
            'device' => $device->load('user', 'approver'),
        ]);
    }

    public function index(Request $request)
    {
        $query = Device::with('user', 'approver');

        if ($request->user()->role === 'organizer') {
            $query->whereHas('user', function ($query) use ($request) {
                $query->where('organization_id', $request->user()->organization_id);
            });
        }

        return response()->json($query->paginate(15));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'uuid' => ['required', 'uuid', 'unique:devices,uuid'],
            'public_key' => ['nullable', 'string'],
            'device_fingerprint' => ['nullable', 'string'],
            'user_id' => ['nullable', 'exists:users,id'],
        ]);

        $device = Device::create([
            'user_id' => $validated['user_id'] ?? $request->user()->id,
            'uuid' => $validated['uuid'],
            'public_key' => $validated['public_key'] ?? null,
            'device_fingerprint' => $validated['device_fingerprint'] ?? null,
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Device registration pending approval',
            'device' => $device,
        ], 201);
    }

    public function show(Device $device, Request $request)
    {
        $this->authorize('view', $device);

        return response()->json($device->load('user', 'approver'));
    }

    public function update(Device $device, Request $request)
    {
        $this->authorize('update', $device);

        $validated = $request->validate([
            'public_key' => ['sometimes', 'nullable', 'string'],
            'device_fingerprint' => ['sometimes', 'nullable', 'string'],
            'status' => ['sometimes', 'in:pending,approved,revoked'],
        ]);

        $device->update($validated);

        return response()->json([
            'message' => 'Device updated successfully',
            'device' => $device,
        ]);
    }

    public function destroy(Device $device)
    {
        $this->authorize('delete', $device);

        $device->delete();

        return response()->json([
            'message' => 'Device removed successfully',
        ]);
    }

    public function approve(Device $device, Request $request)
    {
        $this->authorize('approve', $device);

        $device->update([
            'status' => 'approved',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
        ]);

        return response()->json([
            'message' => 'Device approved successfully',
            'device' => $device,
        ]);
    }

    public function revoke(Device $device, Request $request)
    {
        $this->authorize('approve', $device);

        $device->update([
            'status' => 'revoked',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
        ]);

        return response()->json([
            'message' => 'Device revoked successfully',
            'device' => $device,
        ]);
    }
}
