<?php

namespace App\Services;

use App\Models\Device;
use App\Models\Event;
use Illuminate\Support\Facades\Crypt;

class EventPackageService
{
    public function buildPackage(Event $event, Device $device): string
    {
        $payload = [
            'package_version' => '1.0',
            'generated_at' => now()->toIso8601String(),
            'event' => [
                'id' => $event->id,
                'name' => $event->name,
                'date' => $event->date->toIso8601String(),
                'location' => $event->location,
                'event_secret' => $event->event_secret,
                'status' => $event->status,
            ],
            'device_binding' => [
                'device_uuid' => $device->uuid,
                'status' => $device->status,
                'approved_at' => $device->approved_at?->toIso8601String(),
                'device_fingerprint' => $device->device_fingerprint,
                'has_public_key' => ! empty($device->public_key),
            ],
            'pass_types' => $event->passTypes()->get()->map(function ($type) {
                return [
                    'id' => $type->id,
                    'name' => $type->name,
                    'entry_limit' => $type->entry_limit,
                    'access_zones' => $type->access_zones,
                    'date_restrictions' => $type->date_restrictions,
                    'time_restrictions' => $type->time_restrictions,
                ];
            })->toArray(),
            'passes' => $event->passes()->get()->map(function ($pass) {
                return [
                    'pass_uid' => $pass->pass_uid,
                    'signature' => $pass->signature,
                    'pass_type_id' => $pass->pass_type_id,
                    'attendee_name' => $pass->attendee_name,
                    'company' => $pass->company,
                    'phone' => $pass->phone,
                    'metadata' => $pass->metadata,
                    'scan_count' => $pass->scan_count,
                    'status' => $pass->status,
                ];
            })->toArray(),
        ];

        $package = json_encode($payload, JSON_THROW_ON_ERROR);

        return $this->encryptPackage($package, $device);
    }

    protected function encryptPackage(string $package, Device $device): string
    {
        if ($device->status === 'approved' && ! empty($device->public_key)) {
            return $this->encryptWithPublicKey($package, $device->public_key);
        }

        return Crypt::encryptString($package);
    }

    protected function encryptWithPublicKey(string $package, string $publicKey): string
    {
        $publicKeyResource = openssl_pkey_get_public($publicKey);

        if ($publicKeyResource === false) {
            throw new \RuntimeException('Invalid device public key provided for package encryption.');
        }

        $symmetricKey = random_bytes(32);
        $iv = random_bytes(12);
        $tag = '';

        $cipherText = openssl_encrypt(
            $package,
            'aes-256-gcm',
            $symmetricKey,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
        );

        if ($cipherText === false) {
            throw new \RuntimeException('Unable to encrypt event package payload.');
        }

        if (! openssl_public_encrypt($symmetricKey, $encryptedKey, $publicKeyResource, OPENSSL_PKCS1_OAEP_PADDING)) {
            throw new \RuntimeException('Unable to encrypt the package key with the device public key.');
        }

        return json_encode([
            'encryption' => 'aes-256-gcm',
            'cipher_text' => base64_encode($cipherText),
            'iv' => base64_encode($iv),
            'tag' => base64_encode($tag),
            'encrypted_key' => base64_encode($encryptedKey),
        ], JSON_THROW_ON_ERROR);
    }
}
