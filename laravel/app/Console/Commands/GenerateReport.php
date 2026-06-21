<?php

namespace App\Console\Commands;

use App\Models\Device;
use App\Models\Event;
use App\Models\Pass;
use App\Models\Scan;
use App\Models\User;
use Illuminate\Console\Command;

class GenerateReport extends Command
{
    protected $signature = 'report:generate {type=summary} {--from=} {--to=}';

    protected $description = 'Generate system reports';

    public function handle(): int
    {
        $type = $this->argument('type');

        if ($type === 'summary') {
            return $this->summaryReport();
        }

        if ($type === 'devices') {
            return $this->devicesReport();
        }

        $this->error("Unknown report type '{$type}'.");

        return self::FAILURE;
    }

    protected function summaryReport(): int
    {
        $from = $this->option('from') ? now()->parse($this->option('from')) : now()->subDays(30);
        $to = $this->option('to') ? now()->parse($this->option('to')) : now();

        $this->info('=== System Summary ===');
        $this->line("Period: {$from->toDateString()} – {$to->toDateString()}");
        $this->newLine();

        $this->table(
            ['Metric', 'Count'],
            [
                ['Total Events', Event::count()],
                ['Total Passes', Pass::count()],
                ['Total Scans', Scan::count()],
                ['Total Users', User::count()],
                ['Total Devices', Device::count()],
            ]
        );

        $this->newLine();
        $this->info('Passes per Event');

        $passesPerEvent = Event::withCount('passes')->get()->map(fn ($e) => [
            $e->name,
            $e->passes_count,
        ]);

        $this->table(['Event', 'Passes'], $passesPerEvent);

        $this->newLine();
        $this->info('Scans per Day');

        $scansPerDay = Scan::whereBetween('scanned_at', [$from, $to])
            ->selectRaw('DATE(scanned_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->map(fn ($s) => [$s->date, $s->count]);

        $this->table(['Date', 'Scans'], $scansPerDay);

        return self::SUCCESS;
    }

    protected function devicesReport(): int
    {
        $this->info('=== Devices Report ===');
        $this->newLine();

        $this->table(
            ['Status', 'Count'],
            [
                ['Approved', Device::where('status', 'approved')->count()],
                ['Pending', Device::where('status', 'pending')->count()],
                ['Revoked', Device::where('status', 'revoked')->count()],
            ]
        );

        $this->newLine();
        $this->info('Devices per Organizer');

        $devicesPerUser = User::withCount('devices')->get()->map(fn ($u) => [
            $u->email,
            $u->devices_count,
        ]);

        $this->table(['Organizer (Email)', 'Devices'], $devicesPerUser);

        return self::SUCCESS;
    }
}
