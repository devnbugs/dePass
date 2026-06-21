<?php

namespace App\Services;

use App\Models\Event;
use App\Models\Pass;

class GatePassQrService
{
    public function generateQrData(Pass $pass, Event $event): string
    {
        $signature = hash_hmac('sha256', $pass->pass_uid, $event->event_secret);

        return 'GPX1|'.$pass->pass_uid.'|'.$signature;
    }

    public function validateQrData(string $qrData, string $eventSecret): array
    {
        $parts = explode('|', $qrData);

        if (count($parts) !== 3 || $parts[0] !== 'GPX1') {
            return [
                'pass_uid' => null,
                'valid' => false,
                'message' => 'Invalid QR format',
            ];
        }

        $passUid = $parts[1];
        $signature = $parts[2];

        $expectedSignature = hash_hmac('sha256', $passUid, $eventSecret);

        if (! hash_equals($expectedSignature, $signature)) {
            return [
                'pass_uid' => $passUid,
                'valid' => false,
                'message' => 'Invalid signature',
            ];
        }

        return [
            'pass_uid' => $passUid,
            'valid' => true,
            'message' => 'Valid QR code',
        ];
    }

    public function encryptPackage(string $data, string $publicKey): string
    {
        $encrypted = '';
        openssl_public_encrypt($data, $encrypted, $publicKey);

        return base64_encode($encrypted);
    }

    public function generateQrCodeImage(string $data, int $size = 300): string
    {
        if (function_exists('simplexml_load_string')) {
            $svg = <<<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="{$size}" height="{$size}" viewBox="0 0 {$size} {$size}">
  <rect width="{$size}" height="{$size}" fill="white"/>
  <text x="50%" y="50%" text-anchor="middle" dy=".1em" font-family="monospace" font-size="12" fill="black">
    QR: {$data}
  </text>
</svg>
SVG;

            return 'data:image/svg+xml;base64,'.base64_encode($svg);
        }

        return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    }
}
