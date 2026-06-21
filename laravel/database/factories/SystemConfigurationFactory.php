<?php

namespace Database\Factories;

use App\Models\SystemConfiguration;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SystemConfiguration>
 */
class SystemConfigurationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'key' => fake()->unique()->slug(3),
            'value' => [
                'enabled' => true,
            ],
            'description' => fake()->sentence(),
            'created_by' => User::factory()->superAdmin(),
        ];
    }
}
