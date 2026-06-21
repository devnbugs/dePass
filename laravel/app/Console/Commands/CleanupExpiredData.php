<?php

namespace App\Console\Commands;

use App\Models\Device;
use App\Models\Scan;
use Illuminate\Console\Command;

class CleanupExpiredData extends Command
{
    protected $signature = 'data:cleanup {--days=90}';

    protected $description = 'Clean up expired/old data';

    public function handle(): int
    {
        $days = (int) $this->option('days');
        $cutoff = now()->subDays($days);

        $deletedScans = Scan::where('scanned_at', '<', $cutoff)->delete();

        $revokedDevices = Device::where('status', 'approved')
            ->whereDoesntHave('scans', function ($query) use ($cutoff) {
                $query->where('scanned_at', '>=', $cutoff);
            })
            ->update(['status' => 'revoked']);

        $this->table(
            ['Operation', 'Count'],
            [
                ['Scans deleted (> '.$days.' days old)', $deletedScans],
                ['Devices revoked (inactive > '.$days.' days)', $revokedDevices],
            ]
        );

        $this->info('Cleanup completed successfully.');

        return self::SUCCESS;
    }
}
