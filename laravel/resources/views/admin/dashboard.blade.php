@extends('layouts.admin')

@section('title', 'Dashboard')

@section('content')
<div class="space-y-6">
    <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p class="text-sm text-gray-500">{{ now()->format('l, F j, Y') }}</p>
    </div>

    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
        <div class="bg-white rounded-xl border border-gray-200 p-4 flex items-center gap-4">
            <div class="w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/></svg>
            </div>
            <div>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['events'] }}</p>
                <p class="text-xs text-gray-500">Events</p>
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-4 flex items-center gap-4">
            <div class="w-10 h-10 rounded-lg bg-green-50 text-green-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6 6.878V6a2.25 2.25 0 0 1 2.25-2.25h7.5A2.25 2.25 0 0 1 18 6v.878m-12 0c.235-.083.487-.128.75-.128h10.5c.263 0 .515.045.75.128m-12 0A2.25 2.25 0 0 0 4.5 9v.75M18 6.878A2.25 2.25 0 0 1 19.5 9v.75m0 0v11.25c0 .621-.504 1.125-1.125 1.125h-12.75A1.125 1.125 0 0 1 4.5 21V9.75m16.5 0h-16.5"/></svg>
            </div>
            <div>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['passes'] }}</p>
                <p class="text-xs text-gray-500">Passes</p>
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-4 flex items-center gap-4">
            <div class="w-10 h-10 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/></svg>
            </div>
            <div>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['users'] }}</p>
                <p class="text-xs text-gray-500">Users</p>
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-4 flex items-center gap-4">
            <div class="w-10 h-10 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3"/></svg>
            </div>
            <div>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['devices_approved'] + $stats['devices_pending'] + $stats['devices_revoked'] }}</p>
                <p class="text-xs text-gray-500">Devices</p>
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-4 flex items-center gap-4">
            <div class="w-10 h-10 rounded-lg bg-red-50 text-red-600 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15"/></svg>
            </div>
            <div>
                <p class="text-2xl font-bold text-gray-900">{{ $stats['scans'] }}</p>
                <p class="text-xs text-gray-500">Scans</p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white rounded-xl border border-gray-200 p-4">
            <div class="flex items-center gap-2 text-xs text-gray-500 mb-1">
                <span class="w-2 h-2 rounded-full bg-green-500"></span>
                <span>{{ $stats['devices_approved'] }} Approved</span>
            </div>
            <div class="flex items-center gap-2 text-xs text-gray-500 mb-1">
                <span class="w-2 h-2 rounded-full bg-yellow-500"></span>
                <span>{{ $stats['devices_pending'] }} Pending</span>
            </div>
            <div class="flex items-center gap-2 text-xs text-gray-500">
                <span class="w-2 h-2 rounded-full bg-red-500"></span>
                <span>{{ $stats['devices_revoked'] }} Revoked</span>
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-4">
            <div class="flex items-center gap-2 text-xs text-gray-500 mb-1">
                <span class="w-2 h-2 rounded-full bg-blue-500"></span>
                <span>{{ $stats['organizations'] }} Organizations</span>
            </div>
            <div class="flex items-center gap-2 text-xs text-gray-500">
                <span class="w-2 h-2 rounded-full bg-purple-500"></span>
                <span>{{ $stats['templates'] }} Templates</span>
            </div>
        </div>

        <div class="md:col-span-2 bg-white rounded-xl border border-gray-200 p-4">
            <p class="text-xs text-gray-500 mb-2">Quick Actions</p>
            <div class="flex flex-wrap gap-2">
                <a href="{{ route('admin.events') }}" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-[#FA3E2C] text-white text-xs font-medium rounded-lg hover:bg-[#E03020] transition-colors">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/></svg>
                    Create Event
                </a>
                <a href="{{ route('admin.users') }}" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-800 text-white text-xs font-medium rounded-lg hover:bg-gray-700 transition-colors">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/></svg>
                    Add User
                </a>
                <a href="{{ route('admin.devices', ['status' => 'pending']) }}" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-amber-600 text-white text-xs font-medium rounded-lg hover:bg-amber-700 transition-colors">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/></svg>
                    Approve Devices
                </a>
                <a href="{{ route('admin.scans') }}" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 text-white text-xs font-medium rounded-lg hover:bg-blue-700 transition-colors">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/></svg>
                    View Scans
                </a>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white rounded-xl border border-gray-200">
            <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-sm font-semibold text-gray-900">Recent Audit Logs</h2>
            </div>
            <div class="divide-y divide-gray-100">
                @forelse($auditLogs as $log)
                    <div class="px-5 py-3 flex items-center gap-3 text-sm">
                        <span class="w-1.5 h-1.5 rounded-full flex-shrink-0
                            @if($log->action === 'created') bg-green-500
                            @elseif($log->action === 'updated') bg-blue-500
                            @elseif($log->action === 'deleted') bg-red-500
                            @else bg-gray-400
                            @endif">
                        </span>
                        <div class="flex-1 min-w-0">
                            <p class="text-gray-700 truncate">
                                <span class="font-medium">{{ $log->user?->username ?? 'System' }}</span>
                                {{ $log->action }}
                                <span class="text-gray-500">{{ class_basename($log->entity_type) }}</span>
                                @if($log->entity_id)
                                    <span class="text-gray-400">#{{ $log->entity_id }}</span>
                                @endif
                            </p>
                        </div>
                        <span class="text-xs text-gray-400 flex-shrink-0">{{ $log->created_at?->diffForHumans() }}</span>
                    </div>
                @empty
                    <div class="px-5 py-8 text-center text-sm text-gray-400">No audit logs yet.</div>
                @endforelse
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200">
            <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-sm font-semibold text-gray-900">Pending Device Approvals</h2>
            </div>
            <div class="divide-y divide-gray-100">
                @forelse($pendingDevices as $device)
                    <div class="px-5 py-3 flex items-center gap-3 text-sm">
                        <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3"/></svg>
                        <div class="flex-1 min-w-0">
                            <p class="text-gray-700 truncate">
                                <span class="font-medium">{{ Str::limit($device->uuid, 16) }}</span>
                                <span class="text-gray-400">by {{ $device->user?->username ?? 'Unknown' }}</span>
                            </p>
                        </div>
                        <span class="text-xs text-yellow-600 bg-yellow-50 px-2 py-0.5 rounded-full font-medium">{{ $device->status }}</span>
                    </div>
                @empty
                    <div class="px-5 py-8 text-center text-sm text-gray-400">No devices pending approval.</div>
                @endforelse
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white rounded-xl border border-gray-200">
            <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-sm font-semibold text-gray-900">Recent Events</h2>
            </div>
            <div class="divide-y divide-gray-100">
                @forelse($recentEvents as $event)
                    <div class="px-5 py-3 flex items-center gap-3 text-sm">
                        <div class="flex-1 min-w-0">
                            <p class="font-medium text-gray-900 truncate">{{ $event->name }}</p>
                            <p class="text-xs text-gray-500">
                                {{ $event->organization?->name ?? 'No Org' }}
                                &middot; {{ $event->passTypes->count() }} pass types
                                &middot; {{ $event->date?->format('M d, Y') }}
                            </p>
                        </div>
                        <span class="text-xs px-2 py-0.5 rounded-full font-medium
                            @if($event->status === 'active') bg-green-50 text-green-700
                            @elseif($event->status === 'draft') bg-yellow-50 text-yellow-700
                            @elseif($event->status === 'locked') bg-red-50 text-red-700
                            @else bg-gray-100 text-gray-600
                            @endif">
                            {{ $event->status }}
                        </span>
                    </div>
                @empty
                    <div class="px-5 py-8 text-center text-sm text-gray-400">No events yet.</div>
                @endforelse
            </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200">
            <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-sm font-semibold text-gray-900">System Features</h2>
            </div>
            <div class="divide-y divide-gray-100">
                @forelse($features as $config)
                    <div class="px-5 py-3 flex items-center justify-between text-sm">
                        <span class="text-gray-700">{{ Str::title(str_replace(['feature_', '_'], ['', ' '], $config->key)) }}</span>
                        <span class="text-xs px-2 py-0.5 rounded-full font-medium
                            @if($config->value === true || $config->value === 'true' || $config->value === 1 || $config->value === '1') bg-green-50 text-green-700
                            @else bg-gray-100 text-gray-500
                            @endif">
                            @if($config->value === true || $config->value === 'true' || $config->value === 1 || $config->value === '1') Enabled
                            @else Disabled
                            @endif
                        </span>
                    </div>
                @empty
                    <div class="px-5 py-8 text-center text-sm text-gray-400">No feature flags configured.</div>
                @endforelse
            </div>

            <div class="px-5 py-4 border-t border-gray-100">
                <h3 class="text-xs font-semibold text-gray-500 uppercase mb-2">Services</h3>
                <div class="divide-y divide-gray-100">
                    @forelse($services as $config)
                        <div class="py-2 flex items-center justify-between text-sm">
                            <span class="text-gray-700">{{ Str::title(str_replace(['service_', '_'], ['', ' '], $config->key)) }}</span>
                            <span class="text-xs px-2 py-0.5 rounded-full font-medium
                                @if($config->value === true || $config->value === 'true' || $config->value === 1 || $config->value === '1') bg-green-50 text-green-700
                                @else bg-gray-100 text-gray-500
                                @endif">
                                @if($config->value === true || $config->value === 'true' || $config->value === 1 || $config->value === '1') Active
                                @else Inactive
                                @endif
                            </span>
                        </div>
                    @empty
                        <p class="text-sm text-gray-400 py-2">No services configured.</p>
                    @endforelse
                </div>
            </div>
        </div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200">
        <div class="px-5 py-4 border-b border-gray-100">
            <h2 class="text-sm font-semibold text-gray-900">Scans Per Day (Last 7 Days)</h2>
        </div>
        <div class="px-5 py-4">
            @php
                $scanData = \App\Models\Scan::selectRaw('DATE(scanned_at) as date, COUNT(*) as count')
                    ->where('scanned_at', '>=', now()->subDays(6)->startOfDay())
                    ->groupBy('date')
                    ->orderBy('date')
                    ->pluck('count', 'date');
                $maxCount = max($scanData->max() ?: 1, 1);
                $labels = collect();
                $values = collect();
                for ($i = 6; $i >= 0; $i--) {
                    $date = now()->subDays($i)->format('Y-m-d');
                    $labels->push(now()->subDays($i)->format('D'));
                    $values->push($scanData->get($date, 0));
                }
            @endphp
            @if($values->sum() > 0)
                <div class="flex items-end gap-2 h-32">
                    @foreach($values as $i => $val)
                        <div class="flex-1 flex flex-col items-center gap-1">
                            <span class="text-xs text-gray-500 font-medium">{{ $val }}</span>
                            <div class="w-full bg-[#FA3E2C]/20 rounded-t-md relative" style="height: {{ ($val / $maxCount) * 100 }}%; min-height: 4px;">
                                <div class="absolute inset-x-0 bottom-0 bg-[#FA3E2C] rounded-t-md" style="height: {{ ($val / max($maxCount, 1)) * 100 }}%"></div>
                            </div>
                            <span class="text-xs text-gray-400">{{ $labels[$i] }}</span>
                        </div>
                    @endforeach
                </div>
            @else
                <div class="text-center text-sm text-gray-400 py-8">No scan data available for the last 7 days.</div>
            @endif
        </div>
    </div>
</div>
@endsection
