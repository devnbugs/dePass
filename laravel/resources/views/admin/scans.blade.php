@extends('layouts.admin')

@section('title', 'Scans & Logs')

@section('content')
<div class="space-y-6">
    <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Scan History</h1>
    </div>

    @if(session('success'))
        <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm">
            {{ session('success') }}
        </div>
    @endif

    <div class="bg-white rounded-xl border border-gray-200">
        <div class="px-5 py-4 border-b border-gray-100">
            <form method="GET" class="flex flex-wrap gap-3 items-end">
                <div>
                    <label class="block text-xs text-gray-500 mb-1">Result</label>
                    <select name="result" class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-[#FA3E2C] focus:border-[#FA3E2C] outline-none">
                        <option value="all" {{ $result === 'all' ? 'selected' : '' }}>All Results</option>
                        <option value="valid" {{ $result === 'valid' ? 'selected' : '' }}>Valid</option>
                        <option value="invalid" {{ $result === 'invalid' ? 'selected' : '' }}>Invalid</option>
                        <option value="duplicate" {{ $result === 'duplicate' ? 'selected' : '' }}>Duplicate</option>
                        <option value="error" {{ $result === 'error' ? 'selected' : '' }}>Error</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs text-gray-500 mb-1">From</label>
                    <input type="date" name="date_from" value="{{ $dateFrom }}"
                        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-[#FA3E2C] focus:border-[#FA3E2C] outline-none">
                </div>
                <div>
                    <label class="block text-xs text-gray-500 mb-1">To</label>
                    <input type="date" name="date_to" value="{{ $dateTo }}"
                        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-[#FA3E2C] focus:border-[#FA3E2C] outline-none">
                </div>
                <button type="submit" class="px-4 py-2 bg-gray-800 text-white text-sm font-medium rounded-lg hover:bg-gray-700 transition-colors">Filter</button>
                @if($result !== 'all' || $dateFrom || $dateTo)
                    <a href="{{ route('admin.scans') }}" class="px-4 py-2 border border-gray-300 text-gray-600 text-sm font-medium rounded-lg hover:bg-gray-50 transition-colors">Clear</a>
                @endif
            </form>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="border-b border-gray-100 bg-gray-50">
                        <th class="text-left px-5 py-3 font-medium text-gray-500">Pass UID</th>
                        <th class="text-left px-5 py-3 font-medium text-gray-500">Attendee</th>
                        <th class="text-left px-5 py-3 font-medium text-gray-500">Device</th>
                        <th class="text-left px-5 py-3 font-medium text-gray-500">Result</th>
                        <th class="text-left px-5 py-3 font-medium text-gray-500">Location</th>
                        <th class="text-left px-5 py-3 font-medium text-gray-500">Time</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                    @forelse($scans as $scan)
                        <tr class="hover:bg-gray-50 transition-colors">
                            <td class="px-5 py-3 font-mono text-xs text-gray-700">{{ $scan->pass?->pass_uid ?? '—' }}</td>
                            <td class="px-5 py-3">
                                <div>
                                    <p class="text-gray-900">{{ $scan->pass?->attendee_name ?? 'Unknown' }}</p>
                                    @if($scan->pass?->company)
                                        <p class="text-xs text-gray-400">{{ $scan->pass->company }}</p>
                                    @endif
                                </div>
                            </td>
                            <td class="px-5 py-3 text-gray-600 text-xs">{{ $scan->device?->user?->username ?? 'Unknown' }} ({{ Str::limit($scan->device?->uuid ?? '?', 8) }})</td>
                            <td class="px-5 py-3">
                                <span class="text-xs px-2 py-0.5 rounded-full font-medium
                                    @if($scan->scan_result === 'valid') bg-green-50 text-green-700
                                    @elseif($scan->scan_result === 'invalid') bg-red-50 text-red-700
                                    @elseif($scan->scan_result === 'duplicate') bg-yellow-50 text-yellow-700
                                    @elseif($scan->scan_result === 'error') bg-gray-100 text-gray-600
                                    @else bg-gray-100 text-gray-600
                                    @endif">
                                    {{ $scan->scan_result }}
                                </span>
                            </td>
                            <td class="px-5 py-3 text-gray-600 text-xs">{{ $scan->location_zone ?? '—' }}</td>
                            <td class="px-5 py-3 text-gray-400 text-xs whitespace-nowrap">{{ $scan->scanned_at?->format('M d, Y H:i') ?? '—' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-5 py-12 text-center text-sm text-gray-400">No scans found.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($scans->hasPages())
            <div class="px-5 py-3 border-t border-gray-100">
                {{ $scans->links() }}
            </div>
        @endif
    </div>
</div>
@endsection