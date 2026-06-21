<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['event_id', 'name', 'entry_limit', 'access_zones', 'date_restrictions', 'time_restrictions'])]
class PassType extends Model
{
    use HasFactory;

    protected $casts = [
        'access_zones' => 'json',
        'date_restrictions' => 'json',
        'time_restrictions' => 'json',
    ];

    /**
     * Get the event this pass type belongs to.
     */
    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    /**
     * Get all passes of this type.
     */
    public function passes(): HasMany
    {
        return $this->hasMany(Pass::class);
    }
}
