<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\PassType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PassType>
 */
class PassTypeFactory extends Factory
{
    public function definition(): array
    {
        return [
            'event_id' => Event::factory()->active(),
            'name' => fake()->randomElement(['VIP', 'Guest', 'Staff', 'Speaker', 'Press', 'Security']),
            'entry_limit' => fake()->numberBetween(25, 500),
            'access_zones' => fake()->randomElements(['Main Hall', 'VIP Lounge', 'Backstage', 'Expo Floor'], 2),
        ];
    }
}
