<?php

namespace App\Policies;

use App\Models\Device;
use App\Models\User;

class DevicePolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer'], true);
    }

    public function view(User $user, Device $device): bool
    {
        if ($user->role === 'super_admin') {
            return true;
        }

        return $user->role === 'organizer' && $user->organization_id === $device->user?->organization_id;
    }

    public function update(User $user, Device $device): bool
    {
        if ($user->role === 'super_admin') {
            return true;
        }

        return $user->role === 'organizer' && $user->organization_id === $device->user?->organization_id;
    }

    public function delete(User $user, Device $device): bool
    {
        return $user->role === 'super_admin';
    }

    public function approve(User $user, Device $device): bool
    {
        return in_array($user->role, ['super_admin', 'organizer'], true);
    }
}
