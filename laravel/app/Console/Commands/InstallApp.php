<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class InstallApp extends Command
{
    protected $signature = 'app:install {--mysql} {--force}';

    protected $description = 'One-command app installation with setup wizard';

    public function handle(): int
    {
        $force = $this->option('force');

        $this->info('=== dePass Installation Wizard ===');
        $this->newLine();

        if ($this->option('mysql')) {
            $this->configureMySql($force);
        }

        if (! $force && ! $this->confirm('Continue with installation?', true)) {
            $this->warn('Installation aborted.');

            return self::SUCCESS;
        }

        $this->line('1/5. Run `composer install` to install PHP dependencies.');
        $this->line('2/5. Generating application key...');
        $this->call('key:generate');

        $this->line('3/5. Running database migrations and seeders...');
        $this->call('migrate:fresh', ['--seed' => true, '--force' => $force]);

        $this->line('4/5. Creating storage symlink...');
        $this->call('storage:link');

        $this->line('5/5. Installation complete!');
        $this->newLine();

        $this->info('Admin Credentials (if seeded):');
        $this->table(
            ['Field', 'Value'],
            [
                ['Email', 'admin@depass.app'],
                ['Password', 'password'],
            ]
        );

        return self::SUCCESS;
    }

    protected function configureMySql(bool $force): void
    {
        $this->warn('Switching to MySQL...');

        $db = env('DB_DATABASE') ?: ($force ? 'depass' : $this->ask('Database name', 'depass'));
        $user = env('DB_USERNAME') ?: ($force ? 'root' : $this->ask('Database user', 'root'));
        $pass = env('DB_PASSWORD') ?: ($force ? '' : $this->secret('Database password (leave blank for none)'));

        $this->setEnv('DB_CONNECTION', 'mysql');
        $this->setEnv('DB_HOST', env('DB_HOST', '127.0.0.1'));
        $this->setEnv('DB_PORT', env('DB_PORT', '3306'));
        $this->setEnv('DB_DATABASE', $db);
        $this->setEnv('DB_USERNAME', $user);
        $this->setEnv('DB_PASSWORD', $pass);

        $this->info('MySQL configured. Ensure the database exists before running migrations.');
    }

    protected function setEnv(string $key, string $value): void
    {
        $path = base_path('.env');

        if (file_exists($path)) {
            $content = preg_replace(
                "/^{$key}=.*/m",
                "{$key}={$value}",
                file_get_contents($path)
            );

            if (str_contains($content, "{$key}=")) {
                file_put_contents($path, $content);
            } else {
                file_put_contents($path, $content.PHP_EOL."{$key}={$value}");
            }
        }
    }
}
