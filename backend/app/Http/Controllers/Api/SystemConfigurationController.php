<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Event;
use App\Models\Pass;
use App\Models\PassTemplate;
use App\Models\SystemConfiguration;
use Illuminate\Http\Request;

class SystemConfigurationController extends Controller
{
    public function index(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json(SystemConfiguration::paginate(15));
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'key' => ['required', 'string', 'unique:system_configurations,key'],
            'value' => ['nullable'],
            'description' => ['nullable', 'string'],
        ]);

        $config = SystemConfiguration::create([
            'key' => $validated['key'],
            'value' => $this->normalizeValue($validated['value'] ?? null),
            'description' => $validated['description'] ?? null,
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Configuration saved successfully',
            'configuration' => $config,
        ], 201);
    }

    public function show(SystemConfiguration $configuration, Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json($configuration);
    }

    public function update(Request $request, SystemConfiguration $configuration)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'value' => ['sometimes'],
            'description' => ['sometimes', 'string'],
        ]);

        $configuration->update([
            'value' => array_key_exists('value', $validated) ? $this->normalizeValue($validated['value']) : $configuration->value,
            'description' => $validated['description'] ?? $configuration->description,
        ]);

        return response()->json([
            'message' => 'Configuration updated successfully',
            'configuration' => $configuration,
        ]);
    }

    public function destroy(SystemConfiguration $configuration, Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $configuration->delete();

        return response()->json([
            'message' => 'Configuration removed successfully',
        ]);
    }

    public function dashboard(Request $request)
    {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $configurations = SystemConfiguration::query()
            ->orderBy('key')
            ->get(['id', 'key', 'value', 'description', 'updated_at']);

        return response()->json([
            'stats' => [
                'events' => Event::count(),
                'passes' => Pass::count(),
                'approved_devices' => Device::where('status', 'approved')->count(),
                'pending_devices' => Device::where('status', 'pending')->count(),
                'templates' => PassTemplate::count(),
            ],
            'features' => $this->configurationGroup($configurations, 'features.'),
            'services' => $this->configurationGroup($configurations, 'services.'),
            'configurations' => $configurations,
        ]);
    }

    private function normalizeValue(mixed $value): mixed
    {
        if (is_string($value)) {
            $decoded = json_decode($value, true);

            return json_last_error() === JSON_ERROR_NONE ? $decoded : $value;
        }

        return $value;
    }

    private function configurationGroup($configurations, string $prefix): array
    {
        return $configurations
            ->filter(fn (SystemConfiguration $configuration) => str_starts_with($configuration->key, $prefix))
            ->mapWithKeys(fn (SystemConfiguration $configuration) => [
                substr($configuration->key, strlen($prefix)) => $configuration->value,
            ])
            ->all();
    }
}
