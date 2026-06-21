<?php

namespace App\Policies;

use App\Models\Scan;
use App\Models\User;

class ScanPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer', 'gateman'], true);
    }

    public function view(User $user, Scan $scan): bool
    {
        if ($user->role === 'super_admin') {
            return true;
        }

        if ($user->role === 'organizer') {
            return $user->organization_id === $scan->pass?->event?->organization_id;
        }

        return $user->role === 'gateman' && $user->id === $scan->device?->user_id;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer', 'gateman'], true);
    }

    public function delete(User $user, Scan $scan): bool
    {
        return $user->role === 'super_admin';
    }
}
