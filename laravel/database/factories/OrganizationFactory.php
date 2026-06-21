<?php

namespace Database\Factories;

use App\Models\Organization;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Organization>
 */
class OrganizationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->company().' Events',
            'metadata' => [
                'description' => fake()->sentence(),
                'industry' => fake()->randomElement(['technology', 'education', 'hospitality', 'enterprise']),
            ],
            'created_by' => User::factory()->superAdmin(),
        ];
    }
}
