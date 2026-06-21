<?php

namespace App\Policies;

use App\Models\Event;
use App\Models\User;

class EventPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer', 'gateman'], true);
    }

    public function view(User $user, Event $event): bool
    {
        if ($user->role === 'super_admin') {
            return true;
        }

        if ($user->role === 'organizer') {
            return $user->organization_id === $event->organization_id;
        }

        return $user->role === 'gateman' && $event->status === 'active';
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['super_admin', 'organizer'], true);
    }

    public function update(User $user, Event $event): bool
    {
        return $user->role === 'super_admin' || ($user->role === 'organizer' && $user->id === $event->created_by);
    }

    public function delete(User $user, Event $event): bool
    {
        return $user->role === 'super_admin';
    }

    public function lock(User $user, Event $event): bool
    {
        return in_array($user->role, ['super_admin', 'organizer'], true) &&
            ($user->role === 'super_admin' || $user->organization_id === $event->organization_id);
    }

    public function package(User $user, Event $event): bool
    {
        if ($user->role === 'gateman') {
            return false;
        }

        return $user->role === 'super_admin' || ($user->role === 'organizer' && $user->organization_id === $event->organization_id);
    }
}
