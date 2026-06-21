<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SystemConfiguration;
use Illuminate\Http\Request;

class GatemanSettingsController extends Controller
{
    public function index(Request $request)
    {
        $prefixes = ['scanner.', 'gateman.'];

        $settings = SystemConfiguration::where(function ($q) use ($prefixes) {
            foreach ($prefixes as $prefix) {
                $q->orWhere('key', 'like', $prefix.'%');
            }
        })->get();

        $result = [];

        foreach ($settings as $setting) {
            $result[$setting->key] = $setting->value;
        }

        return response()->json([
            'settings' => $result,
        ]);
    }

    public function update(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $validated = $request->validate([
            'settings' => ['required', 'array'],
            'settings.*' => ['nullable'],
        ]);

        $saved = [];

        foreach ($validated['settings'] as $key => $value) {
            $prefixedKey = $key;

            if (! str_starts_with($key, 'scanner.') && ! str_starts_with($key, 'gateman.')) {
                continue;
            }

            $config = SystemConfiguration::updateOrCreate(
                ['key' => $prefixedKey],
                [
                    'value' => $value,
                    'created_by' => $request->user()->id,
                ]
            );

            $saved[$prefixedKey] = $config->value;
        }

        return response()->json([
            'message' => 'Settings updated successfully',
            'settings' => $saved,
        ]);
    }
}
