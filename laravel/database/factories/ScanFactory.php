<?php

namespace Database\Factories;

use App\Models\Device;
use App\Models\Pass;
use App\Models\Scan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Scan>
 */
class ScanFactory extends Factory
{
    public function definition(): array
    {
        return [
            'pass_id' => Pass::factory(),
            'device_id' => Device::factory()->approved(),
            'scan_result' => fake()->randomElement(['valid', 'invalid', 'duplicate']),
            'scanned_at' => now(),
            'location_zone' => fake()->randomElement(['Main Hall', 'VIP Lounge', 'Backstage']),
            'metadata' => [
                'source' => 'factory',
            ],
        ];
    }
}
