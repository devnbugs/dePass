<?php

namespace App\Observers;

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

class AuditLogObserver
{
    public function created(Model $model): void
    {
        if ($model instanceof AuditLog) {
            return;
        }

        $user = Auth::guard('sanctum')->user() ?? Auth::user();

        $hidden = $model->getHidden();
        $visibleAttributes = array_diff_key($model->getAttributes(), array_flip($hidden));

        AuditLog::create([
            'user_id' => $user?->id,
            'action' => 'created',
            'entity_type' => $model->getTable(),
            'entity_id' => $model->getKey(),
            'old_data' => null,
            'new_data' => $visibleAttributes,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'created_at' => now(),
        ]);
    }

    public function updated(Model $model): void
    {
        if ($model instanceof AuditLog) {
            return;
        }

        $user = Auth::guard('sanctum')->user() ?? Auth::user();

        $hidden = $model->getHidden();
        $visibleAttributes = array_diff_key($model->getAttributes(), array_flip($hidden));

        AuditLog::create([
            'user_id' => $user?->id,
            'action' => 'updated',
            'entity_type' => $model->getTable(),
            'entity_id' => $model->getKey(),
            'old_data' => $model->getOriginal(),
            'new_data' => $visibleAttributes,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'created_at' => now(),
        ]);
    }

    public function deleted(Model $model): void
    {
        if ($model instanceof AuditLog) {
            return;
        }

        $user = Auth::guard('sanctum')->user() ?? Auth::user();

        AuditLog::create([
            'user_id' => $user?->id,
            'action' => 'deleted',
            'entity_type' => $model->getTable(),
            'entity_id' => $model->getKey(),
            'old_data' => $model->getAttributes(),
            'new_data' => null,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'created_at' => now(),
        ]);
    }
}
