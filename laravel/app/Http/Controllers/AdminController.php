<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\Device;
use App\Models\Event;
use App\Models\Organization;
use App\Models\Pass;
use App\Models\PassTemplate;
use App\Models\Scan;
use App\Models\SystemConfiguration;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function dashboard(Request $request)
    {
        $user = $request->user();

        $stats = [
            'events' => Event::query()->when(
                $user->role === 'organizer',
                fn ($q) => $q->where('organization_id', $user->organization_id)
            )->count(),
            'passes' => Pass::query()->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('event', fn ($e) => $e->where('organization_id', $user->organization_id))
            )->count(),
            'users' => User::query()->when(
                $user->role === 'organizer',
                fn ($q) => $q->where('organization_id', $user->organization_id)
            )->count(),
            'organizations' => Organization::count(),
            'devices_approved' => Device::where('status', 'approved')->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('user', fn ($u) => $u->where('organization_id', $user->organization_id))
            )->count(),
            'devices_pending' => Device::where('status', 'pending')->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('user', fn ($u) => $u->where('organization_id', $user->organization_id))
            )->count(),
            'devices_revoked' => Device::where('status', 'revoked')->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('user', fn ($u) => $u->where('organization_id', $user->organization_id))
            )->count(),
            'scans' => Scan::query()->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('pass', fn ($p) => $p->whereHas('event', fn ($e) => $e->where('organization_id', $user->organization_id)))
            )->count(),
            'templates' => PassTemplate::query()->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('event', fn ($e) => $e->where('organization_id', $user->organization_id))
            )->count(),
        ];

        $auditLogs = AuditLog::with('user')
            ->latest('id')
            ->take(10)
            ->get();

        $pendingDevices = Device::with('user')
            ->where('status', 'pending')
            ->when(
                $user->role === 'organizer',
                fn ($q) => $q->whereHas('user', fn ($u) => $u->where('organization_id', $user->organization_id))
            )
            ->latest()
            ->take(10)
            ->get();

        $recentEvents = Event::with('organization', 'passTypes')
            ->when(
                $user->role === 'organizer',
                fn ($q) => $q->where('organization_id', $user->organization_id)
            )
            ->latest()
            ->take(5)
            ->get();

        $features = SystemConfiguration::where('key', 'like', 'feature\_%')->get();
        $services = SystemConfiguration::where('key', 'like', 'service\_%')->get();

        return view('admin.dashboard', compact(
            'stats', 'auditLogs', 'pendingDevices', 'recentEvents', 'features', 'services'
        ));
    }

    public function users(Request $request)
    {
        $query = User::with('organization');

        if ($request->user()->role === 'organizer') {
            $query->where('organization_id', $request->user()->organization_id);
        }

        $search = $request->get('search');
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->withCount('devices')->paginate(15);

        return view('admin.users', compact('users', 'search'));
    }

    public function events(Request $request)
    {
        $query = Event::with('organization', 'passTypes');

        if ($request->user()->role === 'organizer') {
            $query->where('organization_id', $request->user()->organization_id);
        }

        $search = $request->get('search');
        if ($search) {
            $query->where('name', 'like', "%{$search}%");
        }

        $status = $request->get('status');
        if ($status && in_array($status, ['draft', 'active', 'locked'])) {
            $query->where('status', $status);
        }

        $events = $query->withCount('passes')->latest()->paginate(15);

        return view('admin.events', compact('events', 'search', 'status'));
    }

    public function devices(Request $request)
    {
        $query = Device::with('user', 'approver');

        if ($request->user()->role === 'organizer') {
            $query->whereHas('user', fn ($q) => $q->where('organization_id', $request->user()->organization_id));
        }

        $filterStatus = $request->get('status', 'all');
        if ($filterStatus !== 'all' && in_array($filterStatus, ['pending', 'approved', 'revoked'])) {
            $query->where('status', $filterStatus);
        }

        $devices = $query->latest()->paginate(15);

        return view('admin.devices', compact('devices', 'filterStatus'));
    }

    public function scans(Request $request)
    {
        $query = Scan::with('pass', 'device.user');

        if ($request->user()->role === 'organizer') {
            $query->whereHas('pass', fn ($p) => $p->whereHas('event', fn ($e) => $e->where('organization_id', $request->user()->organization_id)));
        }

        $result = $request->get('result', 'all');
        if ($result !== 'all' && in_array($result, ['valid', 'invalid', 'duplicate', 'error'])) {
            $query->where('scan_result', $result);
        }

        $dateFrom = $request->get('date_from');
        if ($dateFrom) {
            $query->whereDate('scanned_at', '>=', $dateFrom);
        }

        $dateTo = $request->get('date_to');
        if ($dateTo) {
            $query->whereDate('scanned_at', '<=', $dateTo);
        }

        $scans = $query->latest('scanned_at')->paginate(15);

        return view('admin.scans', compact('scans', 'result', 'dateFrom', 'dateTo'));
    }

    public function approveDevice(Device $device, Request $request)
    {
        $this->authorize('approve', $device);

        $device->update([
            'status' => 'approved',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
        ]);

        return redirect()->route('admin.devices')->with('success', 'Device approved successfully');
    }

    public function revokeDevice(Device $device, Request $request)
    {
        $this->authorize('approve', $device);

        $device->update([
            'status' => 'revoked',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
        ]);

        return redirect()->route('admin.devices')->with('success', 'Device revoked successfully');
    }

    public function deleteDevice(Device $device, Request $request)
    {
        $this->authorize('delete', $device);

        $device->delete();

        return redirect()->route('admin.devices')->with('success', 'Device deleted successfully');
    }

    public function lockEvent(Event $event, Request $request)
    {
        $this->authorize('lock', $event);

        $event->update(['status' => 'locked']);

        return redirect()->route('admin.events')->with('success', 'Event locked successfully');
    }

    public function deleteEvent(Event $event, Request $request)
    {
        $this->authorize('delete', $event);

        $event->delete();

        return redirect()->route('admin.events')->with('success', 'Event deleted successfully');
    }

    public function deleteUser(User $user, Request $request)
    {
        $this->authorize('delete', $user);

        $user->delete();

        return redirect()->route('admin.users')->with('success', 'User deleted successfully');
    }
}
