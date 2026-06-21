# DePass / GatePassX

Secure event pass management with a Laravel API, Flutter mobile client, QR pass generation, device approval, and CI-backed Android release builds.

## Stacks

- Backend: Laravel 13, Sanctum token auth
- Mobile: Flutter app for login, events, passes, and scanner workflows

## Quick Start

### Backend (Laravel)

```bash
cd laravel
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate:fresh --seed
php artisan serve
```

### Mobile (Flutter)

```bash
cd flutter
flutter pub get
flutter run
```

## Default Users

| Username | Role | Password |
| --- | --- | --- |
| `admin` | `super_admin` | `password123` |
| `organizer1` | `organizer` | `password123` |

## GitHub Workflow

`.github/workflows/release.yml` - Single unified workflow for testing, building APK (split-per-ABI), and Laravel shared-hosting ZIP.

Triggered via workflow_dispatch or on version tags (`v*`).

## Project Layout

```text
laravel/    Laravel API
flutter/    Flutter mobile app
.github/    CI/CD
docs/       Documentation
```

## Shared Hosting Deployment

```bash
unzip gatepassx-laravel-*.zip -d /path/to/document/root
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate
php artisan migrate --force
```