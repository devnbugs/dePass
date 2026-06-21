<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\Organization;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Event>
 */
class EventFactory extends Factory
{
    public function definition(): array
    {
        return [
            'organization_id' => Organization::factory(),
            'name' => fake()->catchPhrase().' Summit',
            'date' => fake()->dateTimeBetween('+2 weeks', '+6 months'),
            'location' => fake()->city().', '.fake()->country(),
            'event_secret' => Str::random(32),
            'status' => fake()->randomElement(['draft', 'active']),
            'created_by' => User::factory()->organizer(),
        ];
    }

    public function active(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'active',
        ]);
    }
}
