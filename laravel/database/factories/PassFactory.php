<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\Pass;
use App\Models\PassType;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Pass>
 */
class PassFactory extends Factory
{
    public function definition(): array
    {
        $passUid = Str::random(16);

        return [
            'event_id' => Event::factory()->active(),
            'pass_type_id' => PassType::factory(),
            'pass_uid' => $passUid,
            'signature' => hash_hmac('sha256', $passUid, 'factory-event-secret'),
            'attendee_name' => fake()->name(),
            'company' => fake()->company(),
            'phone' => fake()->optional()->phoneNumber(),
            'metadata' => [
                'source' => 'factory',
            ],
            'scan_count' => 0,
            'status' => 'active',
        ];
    }

    public function forEventAndType(Event $event, PassType $passType): static
    {
        return $this->state(function (array $attributes) use ($event, $passType) {
            $passUid = Str::random(16);

            return [
                'event_id' => $event->id,
                'pass_type_id' => $passType->id,
                'pass_uid' => $passUid,
                'signature' => hash_hmac('sha256', $passUid, $event->event_secret),
            ];
        });
    }
}
