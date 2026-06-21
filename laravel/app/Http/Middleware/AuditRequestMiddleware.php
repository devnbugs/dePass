<?php

namespace App\Http\Middleware;

use App\Models\AuditLog;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuditRequestMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if (config('app.audit_log_requests', false) && auth()->check()) {
            AuditLog::create([
                'user_id' => auth()->id(),
                'action' => $request->method().' '.$request->path(),
                'entity_type' => 'api_request',
                'entity_id' => null,
                'old_data' => null,
                'new_data' => [
                    'method' => $request->method(),
                    'path' => $request->path(),
                    'status' => $response->getStatusCode(),
                ],
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'created_at' => now(),
            ]);
        }

        return $response;
    }
}
