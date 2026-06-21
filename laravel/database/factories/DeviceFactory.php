<?php

namespace Database\Factories;

use App\Models\Device;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Device>
 */
class DeviceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->gateman(),
            'uuid' => (string) Str::uuid(),
            'device_fingerprint' => fake()->sha256(),
            'status' => 'pending',
        ];
    }

    public function approved(?User $approver = null): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'approved',
            'approved_by' => $approver?->id,
            'approved_at' => now(),
        ]);
    }
}
