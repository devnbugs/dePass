<?php

namespace App\Helpers;

use App\Models\AuditLog;
use Illuminate\Support\Facades\Auth;

class AuditLogger
{
    public function log(string $action, string $entityType, ?int $entityId = null, ?array $oldData = null, ?array $newData = null, ?string $ip = null, ?string $userAgent = null): AuditLog
    {
        $user = Auth::guard('sanctum')->user() ?? Auth::guard('web')->user();

        $auditLog = AuditLog::create([
            'user_id' => $user?->id,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'old_data' => $oldData,
            'new_data' => $newData,
            'ip_address' => $ip ?? request()->ip(),
            'user_agent' => $userAgent ?? request()->userAgent(),
            'created_at' => now(),
        ]);

        return $auditLog;
    }

    public function logApiRequest(string $method, string $path, int $statusCode, ?string $ip = null, ?string $userAgent = null): ?AuditLog
    {
        if (! config('app.audit_log_requests', false)) {
            return null;
        }

        return $this->log(
            action: "{$method} {$path}",
            entityType: 'api_request',
            oldData: null,
            newData: ['status_code' => $statusCode],
            ip: $ip,
            userAgent: $userAgent,
        );
    }

    public static function __callStatic(string $method, array $parameters): mixed
    {
        return (new self)->{$method}(...$parameters);
    }
}
