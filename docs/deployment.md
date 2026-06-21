# Deployment Guide

## Shared Hosting (serv00.com)

### Upload

```bash
# Extract in document root
unzip gatepassx-laravel-*.zip -d /path/to/document/root

# Configure environment
cp .env.example .env
# Edit .env with your database credentials

# Install dependencies
composer install --no-dev --optimize-autoloader

# Generate app key
php artisan key:generate

# Run migrations
php artisan migrate --force
```

### Directory Structure

The ZIP contains public/ contents at root level with:
- `index.php` - Entry point at document root
- `.htaccess` - Routes requests, blocks sensitive paths
- `storage/` - Must be writable for logs/cache
- `bootstrap/`, `config/`, `app/`, etc. - Laravel core

## Local Development

```bash
# Laravel
cd laravel
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve
```

```bash
# Flutter
cd flutter
flutter pub get
flutter run
```

## Docker

```bash
docker-compose up -d
```

Services:
- MySQL: port 3306
- Laravel API: port 8000