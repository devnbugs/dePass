<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class DepassSetupCommand extends Command
{
    protected $signature = 'depass:setup';

    protected $description = 'One-command setup for dePass application';

    public function handle(): int
    {
        $this->info('=== dePass Setup ===');
        $this->newLine();

        $this->line('1/4. Generating application key...');
        $this->call('key:generate');

        $this->line('2/4. Running database migrations and seeders...');
        $this->call('migrate:fresh', ['--seed' => true]);

        $this->line('3/4. Creating initial admin user...');
        User::firstOrCreate(
            ['email' => 'admin@depass.app'],
            [
                'username' => 'admin',
                'password' => Hash::make('admin123'),
                'role' => 'super_admin',
            ]
        );

        $this->line('4/4. Creating storage symlink...');
        $this->call('storage:link');

        $this->newLine();
        $this->info('=== Setup Complete ===');
        $this->info('Admin credentials:');
        $this->table(
            ['Field', 'Value'],
            [
                ['Email', 'admin@depass.app'],
                ['Password', 'admin123'],
                ['Role', 'super_admin'],
            ]
        );

        return self::SUCCESS;
    }
}
