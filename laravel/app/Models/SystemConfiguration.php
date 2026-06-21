<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['key', 'value', 'description', 'created_by'])]
class SystemConfiguration extends Model
{
    use HasFactory;

    protected $casts = [
        'value' => 'json',
    ];
}
