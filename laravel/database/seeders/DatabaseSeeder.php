<?php

namespace Database\Seeders;

use App\Models\Device;
use App\Models\Event;
use App\Models\Organization;
use App\Models\Pass;
use App\Models\PassTemplate;
use App\Models\PassType;
use App\Models\Scan;
use App\Models\SystemConfiguration;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $defaultPassword = env('DEPASS_DEFAULT_PASSWORD', 'password123');

        $superAdmin = User::factory()->superAdmin()->create([
            'username' => env('DEPASS_ADMIN_USERNAME', 'admin'),
            'email' => env('DEPASS_ADMIN_EMAIL', 'admin@gatepassx.com'),
            'password' => Hash::make(env('DEPASS_ADMIN_PASSWORD', $defaultPassword)),
        ]);

        $organization = Organization::factory()->create([
            'name' => 'Tech Conference 2026',
            'metadata' => [
                'description' => 'Annual tech conference',
                'seed' => 'default',
            ],
            'created_by' => $superAdmin->id,
        ]);

        $organizer = User::factory()->organizer()->create([
            'username' => 'organizer1',
            'email' => 'organizer@techconf.com',
            'password' => Hash::make($defaultPassword),
            'organization_id' => $organization->id,
        ]);

        $gatemen = User::factory()->gateman()->count(2)->sequence(
            [
                'username' => 'gateman1',
                'email' => 'gate1@techconf.com',
                'password' => Hash::make($defaultPassword),
                'organization_id' => $organization->id,
            ],
            [
                'username' => 'gateman2',
                'email' => 'gate2@techconf.com',
                'password' => Hash::make($defaultPassword),
                'organization_id' => $organization->id,
            ],
        )->create();

        $event = Event::factory()->active()->create([
            'organization_id' => $organization->id,
            'name' => 'Tech Summit 2026',
            'date' => now()->addDays(30),
            'location' => 'Convention Center, New York',
            'created_by' => $organizer->id,
        ]);

        $passTypes = [
            ['name' => 'VIP', 'entry_limit' => 100, 'access_zones' => ['Main Hall', 'VIP Lounge', 'Backstage']],
            ['name' => 'Guest', 'entry_limit' => 500, 'access_zones' => ['Main Hall', 'Expo Floor']],
            ['name' => 'Staff', 'entry_limit' => 50, 'access_zones' => ['Main Hall', 'Backstage', 'Operations']],
            ['name' => 'Speaker', 'entry_limit' => 20, 'access_zones' => ['Main Hall', 'Speaker Lounge', 'Backstage']],
        ];

        foreach ($passTypes as $passType) {
            PassType::factory()->create([
                'event_id' => $event->id,
                'name' => $passType['name'],
                'entry_limit' => $passType['entry_limit'],
                'access_zones' => $passType['access_zones'],
            ]);
        }

        $vipPassType = PassType::where('event_id', $event->id)->where('name', 'VIP')->first();
        Pass::factory()->count(5)->forEventAndType($event, $vipPassType)->sequence(
            ...collect(range(1, 5))->map(fn (int $index) => [
                'attendee_name' => "VIP Guest {$index}",
                'company' => "Tech Company {$index}",
                'metadata' => ['seed_batch' => 'vip-demo'],
            ])->all(),
        )->create();

        $approvedDevice = Device::factory()->approved($superAdmin)->create([
            'user_id' => $gatemen->first()->id,
            'device_fingerprint' => 'seeded-approved-gate-device',
        ]);

        Scan::factory()->create([
            'pass_id' => $event->passes()->first()->id,
            'device_id' => $approvedDevice->id,
            'scan_result' => 'valid',
            'location_zone' => 'Main Hall',
            'metadata' => ['seed' => 'default'],
        ]);

        PassTemplate::factory()->create([
            'event_id' => $event->id,
            'name' => 'Default A4 Badge',
            'file_name' => 'default-a4-badge.pdf',
            'file_path' => 'templates/default-a4-badge.pdf',
            'created_by' => $organizer->id,
        ]);

        SystemConfiguration::factory()->sequence(
            [
                'key' => 'features.mobile_app',
                'value' => [
                    'login' => true,
                    'event_list' => true,
                    'pass_sync' => true,
                    'offline_package' => true,
                ],
                'description' => 'Admin dashboard controls for mobile app feature availability.',
                'created_by' => $superAdmin->id,
            ],
            [
                'key' => 'services.release_pipeline',
                'value' => [
                    'laravel_preflight' => true,
                    'flutter_analyze' => true,
                    'flutter_tests' => true,
                    'split_per_abi_apk' => true,
                ],
                'description' => 'Admin dashboard controls for release workflow services.',
                'created_by' => $superAdmin->id,
            ],
        )->count(2)->create();

        $this->command?->info('Database seeded with default users, event data, factories, and mobile configuration.');
    }
}
