<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Get all users (super_admin only or organizer sees own org users).
     *
     * @return JsonResponse
     */
    public function index(Request $request)
    {
        $this->authorize('viewAny', User::class);

        $query = User::query();

        // Organizer can only see users in their organization
        if ($request->user()->role === 'organizer') {
            $query->where('organization_id', $request->user()->organization_id);
        }

        $users = $query->paginate(15);

        return response()->json($users);
    }

    /**
     * Create a new user (super_admin only).
     *
     * @return JsonResponse
     */
    public function store(Request $request)
    {
        $this->authorize('create', User::class);

        $validated = $request->validate([
            'username' => ['required', 'string', 'unique:users'],
            'email' => ['required', 'email', 'unique:users'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', Rule::in(['super_admin', 'organizer', 'gateman'])],
            'organization_id' => ['nullable', 'exists:organizations,id'],
        ]);

        $user = User::create([
            'username' => $validated['username'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'organization_id' => $validated['organization_id'] ?? null,
        ]);

        return response()->json([
            'message' => 'User created successfully',
            'user' => $user->only(['id', 'username', 'email', 'role', 'organization_id']),
        ], 201);
    }

    /**
     * Get a specific user.
     *
     * @return JsonResponse
     */
    public function show(User $user, Request $request)
    {
        $this->authorize('view', $user);

        return response()->json([
            'id' => $user->id,
            'username' => $user->username,
            'email' => $user->email,
            'role' => $user->role,
            'organization_id' => $user->organization_id,
        ]);
    }

    /**
     * Update a user.
     *
     * @return JsonResponse
     */
    public function update(User $user, Request $request)
    {
        $this->authorize('update', $user);

        $validated = $request->validate([
            'email' => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'role' => ['sometimes', Rule::in(['super_admin', 'organizer', 'gateman'])],
            'organization_id' => ['sometimes', 'nullable', 'exists:organizations,id'],
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'User updated successfully',
            'user' => $user->only(['id', 'username', 'email', 'role', 'organization_id']),
        ]);
    }

    /**
     * Soft delete a user.
     *
     * @return JsonResponse
     */
    public function destroy(User $user, Request $request)
    {
        $this->authorize('delete', $user);

        // Soft delete implementation would go here
        // For now, we'll just do a permanent delete since we haven't added soft deletes
        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully',
        ]);
    }
}
