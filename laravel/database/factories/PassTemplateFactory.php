<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\PassTemplate;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PassTemplate>
 */
class PassTemplateFactory extends Factory
{
    public function definition(): array
    {
        return [
            'event_id' => Event::factory()->active(),
            'name' => fake()->words(2, true).' Badge',
            'file_name' => 'badge-template.pdf',
            'file_path' => 'templates/badge-template.pdf',
            'content_type' => 'application/pdf',
            'file_size' => fake()->numberBetween(1024, 65536),
            'layout' => [
                'page_format' => 'A4',
                'columns' => 2,
            ],
            'created_by' => User::factory()->organizer(),
        ];
    }
}
