<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Login user and generate API token.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
            'device_uuid' => 'nullable|uuid',
        ]);

        $user = User::where('username', $request->username)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'username' => ['The provided credentials are invalid.'],
            ]);
        }

        if ($user->role !== 'super_admin') {
            if (!$request->filled('device_uuid')) {
                throw ValidationException::withMessages([
                    'device_uuid' => ['This device must be registered and approved before login.'],
                ]);
            }

            $approvedDevice = Device::where('uuid', $request->device_uuid)
                ->where('user_id', $user->id)
                ->where('status', 'approved')
                ->first();

            if (!$approvedDevice) {
                throw ValidationException::withMessages([
                    'device_uuid' => ['This device is not approved by an admin yet.'],
                ]);
            }
        }

        // Revoke all existing tokens
        $user->tokens()->delete();

        // Create new token with 1 hour expiry
        $token = $user->createToken('api-token', ['*'], now()->addHour());

        return response()->json([
            'message' => 'Login successful',
            'user' => [
                'id' => $user->id,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
                'organization_id' => $user->organization_id,
            ],
            'token' => $token->plainTextToken,
            'expires_in' => 3600, // 1 hour in seconds
        ]);
    }

    /**
     * Logout user and revoke token.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout successful',
        ]);
    }

    /**
     * Get current authenticated user.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function me(Request $request)
    {
        return response()->json([
            'id' => $request->user()->id,
            'username' => $request->user()->username,
            'email' => $request->user()->email,
            'role' => $request->user()->role,
            'organization_id' => $request->user()->organization_id,
            'has_passkey' => $request->user()->has_passkey,
            'has_biometric' => $request->user()->has_biometric,
        ]);
    }

    /**
     * Refresh API token.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function refresh(Request $request)
    {
        $user = $request->user();

        // Revoke old token
        $user->currentAccessToken()->delete();

        // Create new token with 1 hour expiry
        $token = $user->createToken('api-token', ['*'], now()->addHour());

        return response()->json([
            'message' => 'Token refreshed',
            'token' => $token->plainTextToken,
            'expires_in' => 3600,
        ]);
    }
}
