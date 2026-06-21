<?php

namespace App\Services;

class QrSignatureService
{
    public function generateSignature(string $passUid, string $eventSecret): string
    {
        return hash_hmac('sha256', $passUid, $eventSecret);
    }

    public function validateSignature(string $passUid, string $signature, string $eventSecret): bool
    {
        return hash_equals($this->generateSignature($passUid, $eventSecret), $signature);
    }
}
