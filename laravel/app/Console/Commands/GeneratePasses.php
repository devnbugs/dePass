<?php

namespace App\Console\Commands;

use App\Models\Event;
use App\Models\Pass;
use App\Models\PassType;
use App\Services\QrSignatureService;
use Illuminate\Console\Command;

class GeneratePasses extends Command
{
    protected $signature = 'passes:generate {event} {pass-type} {count=10} {--prefix=ATTENDEE}';

    protected $description = 'Bulk generate passes for an event';

    public function handle(QrSignatureService $qr): int
    {
        $event = Event::find($this->argument('event'));
        if (! $event) {
            $this->error('Event not found.');

            return self::FAILURE;
        }

        $passType = PassType::find($this->argument('pass-type'));
        if (! $passType) {
            $this->error('Pass type not found.');

            return self::FAILURE;
        }

        $count = (int) $this->argument('count');
        $prefix = $this->option('prefix');

        $bar = $this->output->createProgressBar($count);
        $bar->start();

        for ($i = 1; $i <= $count; $i++) {
            $passUid = strtoupper(substr(bin2hex(random_bytes(8)), 0, 16));

            Pass::create([
                'event_id' => $event->id,
                'pass_type_id' => $passType->id,
                'pass_uid' => $passUid,
                'signature' => $qr->generateSignature($passUid, $event->event_secret),
                'attendee_name' => "{$prefix} {$i}",
                'status' => 'active',
            ]);

            $bar->advance();
        }

        $bar->finish();
        $this->newLine();
        $this->info("Generated {$count} passes for event '{$event->name}'.");

        return self::SUCCESS;
    }
}
