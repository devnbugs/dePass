<?php

namespace App\Policies;

use App\Models\User;

class AdminPolicy
{
    public function accessAdmin(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer'], true);
    }
}
