<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['organization_id', 'name', 'date', 'location', 'event_secret', 'status', 'created_by'])]
class Event extends Model
{
    use HasFactory;

    protected $casts = [
        'date' => 'datetime',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function passTypes(): HasMany
    {
        return $this->hasMany(PassType::class);
    }

    public function passes(): HasMany
    {
        return $this->hasMany(Pass::class);
    }

    public function passTemplates(): HasMany
    {
        return $this->hasMany(PassTemplate::class);
    }

    public function getIsLockedAttribute(): bool
    {
        return $this->status === 'locked';
    }
}
