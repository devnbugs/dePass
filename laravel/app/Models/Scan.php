<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['pass_id', 'device_id', 'scan_result', 'scanned_at', 'location_zone', 'metadata'])]
class Scan extends Model
{
    use HasFactory, SoftDeletes;

    protected $casts = [
        'scanned_at' => 'datetime',
        'metadata' => 'json',
    ];

    /**
     * Get the pass that was scanned.
     */
    public function pass(): BelongsTo
    {
        return $this->belongsTo(Pass::class);
    }

    /**
     * Get the device that performed the scan.
     */
    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
