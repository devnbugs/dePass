<?php

namespace App\Console\Commands;

use App\Models\Device;
use App\Models\Event;
use App\Services\EventPackageService;
use Illuminate\Console\Command;

class SyncDevicePackages extends Command
{
    protected $signature = 'devices:sync-packages {--event=}';

    protected $description = 'Generate event packages for all approved devices';

    public function handle(EventPackageService $packageService): int
    {
        $events = $this->option('event')
            ? Event::where('id', $this->option('event'))->get()
            : Event::where('status', 'active')->get();

        if ($events->isEmpty()) {
            $this->warn('No events found.');

            return self::SUCCESS;
        }

        $totalPackages = 0;

        foreach ($events as $event) {
            $devices = Device::where('status', 'approved')->get();

            if ($devices->isEmpty()) {
                $this->line("No approved devices for event '{$event->name}'.");

                continue;
            }

            foreach ($devices as $device) {
                $packageService->buildPackage($event, $device);
                $totalPackages++;
            }

            $this->info("Generated {$devices->count()} package(s) for event '{$event->name}'.");
        }

        $this->info("Total packages generated: {$totalPackages}");

        return self::SUCCESS;
    }
}
