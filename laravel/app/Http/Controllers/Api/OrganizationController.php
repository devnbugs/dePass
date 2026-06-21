<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Organization;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrganizationController extends Controller
{
    /**
     * Get all organizations (super_admin only).
     *
     * @return JsonResponse
     */
    public function index(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $organizations = Organization::with('creator')
            ->withCount('users', 'events')
            ->paginate(15);

        return response()->json($organizations);
    }

    /**
     * Create a new organization (super_admin only).
     *
     * @return JsonResponse
     */
    public function store(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string',
            'metadata' => 'nullable|json',
        ]);

        $organization = Organization::create([
            'name' => $validated['name'],
            'metadata' => $validated['metadata'] ?? null,
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Organization created successfully',
            'organization' => $organization,
        ], 201);
    }

    /**
     * Get a specific organization.
     *
     * @return JsonResponse
     */
    public function show(Organization $organization, Request $request)
    {
        return response()->json($organization->load('creator', 'users', 'events'));
    }

    /**
     * Update an organization.
     *
     * @return JsonResponse
     */
    public function update(Organization $organization, Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string',
            'metadata' => 'sometimes|nullable|json',
        ]);

        $organization->update($validated);

        return response()->json([
            'message' => 'Organization updated successfully',
            'organization' => $organization,
        ]);
    }

    /**
     * Delete an organization (super_admin only).
     *
     * @return JsonResponse
     */
    public function destroy(Organization $organization, Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $organization->delete();

        return response()->json([
            'message' => 'Organization deleted successfully',
        ]);
    }
}
