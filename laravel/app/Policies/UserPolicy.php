<?php

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'super_admin';
    }

    public function view(User $user, User $model): bool
    {
        if ($user->role === 'super_admin') {
            return true;
        }

        if ($user->role === 'organizer') {
            return $user->organization_id === $model->organization_id;
        }

        return $user->id === $model->id;
    }

    public function update(User $user, User $model): bool
    {
        return $user->role === 'super_admin' || $user->id === $model->id;
    }

    public function delete(User $user, User $model): bool
    {
        if ($user->role === 'super_admin') {
            return true;
        }

        if ($user->role === 'organizer') {
            return $user->organization_id === $model->organization_id;
        }

        return false;
    }
}
