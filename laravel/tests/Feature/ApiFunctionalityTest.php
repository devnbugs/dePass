<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\Event;
use App\Models\PassType;
use App\Models\SystemConfiguration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class ApiFunctionalityTest extends TestCase
{
    use RefreshDatabase;

    protected bool $seed = true;

    public function test_mobile_authentication_contract_works(): void
    {
        $this->getJson('/api/me')->assertUnauthorized();

        $login = $this->postJson('/api/login', [
            'username' => 'admin',
            'password' => 'password123',
        ]);

        $login->assertOk()
            ->assertJsonPath('message', 'Login successful')
            ->assertJsonPath('user.username', 'admin')
            ->assertJsonStructure(['token', 'expires_in']);

        $token = $login->json('token');

        $this->withToken($token)
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('username', 'admin')
            ->assertJsonPath('role', 'super_admin');

        $refresh = $this->withToken($token)
            ->postJson('/api/refresh')
            ->assertOk()
            ->assertJsonPath('message', 'Token refreshed')
            ->assertJsonStructure(['token']);

        $this->withToken($refresh->json('token'))
            ->postJson('/api/logout')
            ->assertOk()
            ->assertJsonPath('message', 'Logout successful');
    }

    public function test_mobile_login_requires_admin_approved_device(): void
    {
        $deviceUuid = (string) Str::uuid();

        $this->postJson('/api/device-registration', [
            'uuid' => $deviceUuid,
            'username' => 'gateman1',
            'device_fingerprint' => 'pre-login-test-device',
        ])
            ->assertCreated()
            ->assertJsonPath('device.status', 'pending');

        $this->postJson('/api/login', [
            'username' => 'gateman1',
            'password' => 'password123',
            'device_uuid' => $deviceUuid,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['device_uuid']);

        $adminToken = $this->loginToken('admin');
        $device = Device::where('uuid', $deviceUuid)->firstOrFail();

        $this->withToken($adminToken)
            ->postJson("/api/devices/{$device->id}/approve")
            ->assertOk()
            ->assertJsonPath('device.status', 'approved');

        $this->postJson('/api/device-registration/status', [
            'uuid' => $deviceUuid,
            'username' => 'gateman1',
        ])
            ->assertOk()
            ->assertJsonPath('status', 'approved');

        $this->postJson('/api/login', [
            'username' => 'gateman1',
            'password' => 'password123',
            'device_uuid' => $deviceUuid,
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Login successful')
            ->assertJsonStructure(['token']);
    }

    public function test_organizer_can_load_events_generate_passes_and_fetch_package(): void
    {
        $organizer = User::where('username', 'organizer1')->firstOrFail();
        $event = Event::where('created_by', $organizer->id)->firstOrFail();
        $passType = PassType::where('event_id', $event->id)->where('name', 'VIP')->firstOrFail();

        $token = $this->loginToken('organizer1');

        $this->withToken($token)
            ->getJson('/api/events')
            ->assertOk()
            ->assertJsonPath('data.0.id', $event->id);

        $passResponse = $this->withToken($token)
            ->postJson("/api/events/{$event->id}/passes", [
                'pass_type_id' => $passType->id,
                'attendee_name' => 'Automation Guest',
                'company' => 'CI Labs',
                'metadata' => ['source' => 'automation'],
            ]);

        $passResponse->assertCreated()
            ->assertJsonPath('message', 'Pass generated successfully')
            ->assertJsonPath('pass.attendee_name', 'Automation Guest')
            ->assertJsonStructure(['pass' => ['id', 'pass_uid', 'signature'], 'qr_data']);

        $this->withToken($token)
            ->getJson("/api/events/{$event->id}/passes")
            ->assertOk()
            ->assertJsonFragment(['attendee_name' => 'Automation Guest']);

        $deviceUuid = (string) Str::uuid();

        $deviceResponse = $this->withToken($token)
            ->postJson('/api/devices', [
                'uuid' => $deviceUuid,
                'device_fingerprint' => 'automation-device',
            ]);

        $deviceResponse->assertCreated()
            ->assertJsonPath('device.status', 'pending')
            ->assertJsonPath('device.uuid', $deviceUuid);

        $deviceId = $deviceResponse->json('device.id');

        $this->withToken($token)
            ->postJson("/api/devices/{$deviceId}/approve")
            ->assertOk()
            ->assertJsonPath('device.status', 'approved');

        $this->withToken($token)
            ->getJson("/api/events/{$event->id}/package?device_uuid={$deviceUuid}")
            ->assertOk()
            ->assertJsonPath('format', 'encrypted')
            ->assertJsonStructure(['event_package', 'encryption']);
    }

    public function test_roles_are_enforced_for_sensitive_endpoints(): void
    {
        $event = Event::firstOrFail();
        $passType = PassType::where('event_id', $event->id)->firstOrFail();
        $gatemanToken = $this->loginToken('gateman1');
        $organizerToken = $this->loginToken('organizer1');

        $this->withToken($gatemanToken)
            ->getJson('/api/events')
            ->assertOk();

        $this->withToken($gatemanToken)
            ->postJson("/api/events/{$event->id}/passes", [
                'pass_type_id' => $passType->id,
                'attendee_name' => 'Blocked Guest',
            ])
            ->assertForbidden();

        $this->withToken($organizerToken)
            ->getJson('/api/organizations')
            ->assertForbidden();
    }

    public function test_admin_can_manage_system_configuration(): void
    {
        $adminToken = $this->loginToken('admin');
        $create = $this->withToken($adminToken)
            ->postJson('/api/configurations', [
                'key' => 'mobile.offline_scan_limit',
                'value' => ['limit' => 500],
                'description' => 'Maximum offline scans before sync warning.',
            ]);

        $create->assertCreated()
            ->assertJsonPath('configuration.key', 'mobile.offline_scan_limit')
            ->assertJsonPath('configuration.value.limit', 500);

        $configurationId = $create->json('configuration.id');

        $this->withToken($adminToken)
            ->getJson("/api/configurations/{$configurationId}")
            ->assertOk()
            ->assertJsonPath('key', 'mobile.offline_scan_limit');

        $this->withToken($adminToken)
            ->patchJson("/api/configurations/{$configurationId}", [
                'value' => ['limit' => 750],
            ])
            ->assertOk()
            ->assertJsonPath('configuration.value.limit', 750);

        $this->assertDatabaseHas(SystemConfiguration::class, [
            'key' => 'mobile.offline_scan_limit',
        ]);
    }

    public function test_non_admin_cannot_manage_system_configuration(): void
    {
        $organizerToken = $this->loginToken('organizer1');

        $this->withToken($organizerToken)
            ->getJson('/api/configurations')
            ->assertForbidden();
    }

    public function test_admin_dashboard_endpoints_return_expected_data(): void
    {
        $token = $this->loginToken('admin');

        $this->withToken($token)
            ->getJson('/api/users')
            ->assertOk()
            ->assertJsonFragment(['username' => 'admin']);

        $this->withToken($token)
            ->getJson('/api/organizations')
            ->assertOk()
            ->assertJsonFragment(['name' => 'Tech Conference 2026']);

        $this->withToken($token)
            ->getJson('/api/stats')
            ->assertOk()
            ->assertJsonStructure(['events', 'passes', 'devices', 'pending_devices', 'templates']);

        $this->withToken($token)
            ->getJson('/api/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('features.mobile_app.login', true)
            ->assertJsonPath('services.release_pipeline.split_per_abi_apk', true)
            ->assertJsonStructure([
                'stats' => ['events', 'passes', 'approved_devices', 'pending_devices', 'templates'],
                'features',
                'services',
                'configurations',
                'devices',
            ]);
    }

    public function test_organizer_can_manage_pass_types_templates_and_print_manifest(): void
    {
        Storage::fake('public');

        $organizer = User::where('username', 'organizer1')->firstOrFail();
        $event = Event::where('created_by', $organizer->id)->firstOrFail();
        $pass = $event->passes()->firstOrFail();
        $token = $this->loginToken('organizer1');

        $passTypeResponse = $this->withToken($token)
            ->postJson("/api/events/{$event->id}/pass-types", [
                'name' => 'Automation Staff',
                'entry_limit' => 25,
                'access_zones' => ['Main Hall', 'Backstage'],
            ]);

        $passTypeResponse->assertCreated()
            ->assertJsonPath('pass_type.name', 'Automation Staff')
            ->assertJsonPath('pass_type.entry_limit', 25);

        $passTypeId = $passTypeResponse->json('pass_type.id');

        $this->withToken($token)
            ->patchJson("/api/pass-types/{$passTypeId}", [
                'entry_limit' => 30,
            ])
            ->assertOk()
            ->assertJsonPath('pass_type.entry_limit', 30);

        $templateResponse = $this->withToken($token)
            ->post("/api/events/{$event->id}/templates", [
                'name' => 'Automation Badge',
                'layout' => json_encode(['page_format' => 'A4', 'columns' => 2]),
                'template_file' => UploadedFile::fake()->create('badge.pdf', 12, 'application/pdf'),
            ], [
                'Accept' => 'application/json',
            ]);

        $templateResponse->assertCreated()
            ->assertJsonPath('template.name', 'Automation Badge')
            ->assertJsonPath('template.layout.page_format', 'A4');

        $templateId = $templateResponse->json('template.id');
        $templatePath = $templateResponse->json('template.file_path');
        Storage::disk('public')->assertExists($templatePath);

        $this->withToken($token)
            ->patchJson("/api/templates/{$templateId}", [
                'layout' => json_encode(['page_format' => 'Letter', 'columns' => 1]),
            ])
            ->assertOk()
            ->assertJsonPath('template.layout.page_format', 'Letter');

        $this->withToken($token)
            ->postJson("/api/events/{$event->id}/print-manifest", [
                'template_id' => $templateId,
                'pass_ids' => [$pass->id],
            ])
            ->assertOk()
            ->assertJsonPath('manifest.event.id', $event->id)
            ->assertJsonPath('manifest.template.id', $templateId)
            ->assertJsonPath('manifest.cards.0.pass_id', $pass->id)
            ->assertJsonStructure(['manifest' => ['cards' => [['qr_data']]]]);

        $this->withToken($token)
            ->deleteJson("/api/templates/{$templateId}")
            ->assertOk();

        Storage::disk('public')->assertMissing($templatePath);

        $this->withToken($token)
            ->deleteJson("/api/pass-types/{$passTypeId}")
            ->assertOk();
    }

    private function loginToken(string $username): string
    {
        $payload = [
            'username' => $username,
            'password' => 'password123',
        ];

        if ($username !== 'admin') {
            $user = User::where('username', $username)->firstOrFail();
            $admin = User::where('username', 'admin')->firstOrFail();
            $device = Device::factory()->approved($admin)->create([
                'user_id' => $user->id,
                'device_fingerprint' => "test-{$username}",
            ]);

            $payload['device_uuid'] = $device->uuid;
        }

        return $this->postJson('/api/login', $payload)->assertOk()->json('token');
    }
}
