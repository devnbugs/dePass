<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'metadata', 'created_by'])]
class Organization extends Model
{
    use HasFactory;

    protected $casts = [
        'metadata' => 'json',
    ];

    /**
     * Get the user who created this organization.
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get all users in this organization.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    /**
     * Get all events in this organization.
     */
    public function events(): HasMany
    {
        return $this->hasMany(Event::class);
    }
}
