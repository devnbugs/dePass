<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'uuid', 'public_key', 'device_fingerprint', 'status', 'approved_by', 'approved_at'])]
class Device extends Model
{
    use HasFactory;

    protected $casts = [
        'approved_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function scans(): HasMany
    {
        return $this->hasMany(Scan::class);
    }

    public function getNameAttribute(): string
    {
        return 'Device ' . $this->user?->username ?? $this->uuid;
    }

    public function getPlatformAttribute(): string
    {
        return 'Android';
    }

    public function getLastActiveAtAttribute(): ?string
    {
        return $this->updated_at?->toIso8601String();
    }

    public function getIsApprovedAttribute(): bool
    {
        return $this->status === 'approved';
    }
}
