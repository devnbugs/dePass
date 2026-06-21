<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['event_id', 'pass_type_id', 'pass_uid', 'signature', 'attendee_name', 'company', 'phone', 'metadata', 'scan_count', 'status'])]
class Pass extends Model
{
    use HasFactory, SoftDeletes;

    protected $casts = [
        'deleted_at' => 'datetime',
        'metadata' => 'json',
    ];

    /**
     * Get the event this pass belongs to.
     */
    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    /**
     * Get the pass type of this pass.
     */
    public function passType(): BelongsTo
    {
        return $this->belongsTo(PassType::class);
    }

    /**
     * Get all scans for this pass.
     */
    public function scans(): HasMany
    {
        return $this->hasMany(Scan::class);
    }
}
