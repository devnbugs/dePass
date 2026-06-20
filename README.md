# DePass / GatePassX

Secure event pass management with a Laravel API, Flutter mobile client, QR pass generation, device approval, and CI-backed Android release builds.

## Current Stack

- Backend: Laravel 13, Sanctum token auth, SQLite for local/CI, MySQL-ready production config
- Mobile: Flutter app for login, events, passes, and mobile scanner workflows
- Automation: seeded Laravel API tests, live HTTP smoke flow, Flutter analysis/tests, split-per-ABI APK builds
- Security model: role-based access for `super_admin`, `organizer`, and `gateman`; signed QR payloads; approved device packages
- Admin controls: super-admin dashboard API for feature flags, service controls, release toggles, and system configuration

## Quick Start

### Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate:fresh --seed
php artisan serve
```

Default seeded users:

| Username | Role | Password |
| --- | --- | --- |
| `admin` | `super_admin` | `password123` |
| `organizer1` | `organizer` | `password123` |
| `gateman1` | `gateman` | `password123` |
| `gateman2` | `gateman` | `password123` |

The admin seed can be overridden with `DEPASS_ADMIN_USERNAME`, `DEPASS_ADMIN_EMAIL`, `DEPASS_ADMIN_PASSWORD`, and `DEPASS_DEFAULT_PASSWORD`.

### Local Preflight

```bash
./scripts/local-preflight.sh
```

The preflight creates an ignored root `workspace/` directory, runs Composer validation, runs Laravel tests against an isolated SQLite database, then runs Flutter dependency, analysis, and test checks when Flutter is installed locally.

### Mobile

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Split APK outputs are created under `mobile/build/app/outputs/flutter-apk/`.

## Seeded Data

`php artisan migrate:fresh --seed` creates:

- Default admin, organizer, and gate users
- A `Tech Conference 2026` organization
- A live `Tech Summit 2026` event
- VIP, Guest, Staff, and Speaker pass types
- Demo VIP passes with valid HMAC signatures
- One approved gate device, a sample scan, a default badge template, and mobile configuration
- Admin feature and service controls under `features.*` and `services.*`

Factories now exist for users, organizations, events, pass types, passes, devices, scans, pass templates, audit logs, and system configurations. Tests and new seeders can use the same factory layer instead of hand-building records.

## API Smoke Test

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}' | jq -r '.token')

curl -s http://127.0.0.1:8000/api/me \
  -H "Authorization: Bearer $TOKEN"
```

Useful endpoints:

- `POST /api/login`, `POST /api/logout`, `GET /api/me`, `POST /api/refresh`
- `GET|POST /api/users`
- `GET|POST /api/organizations`
- `GET|POST /api/events`
- `GET|POST /api/events/{event}/pass-types`
- `GET|POST /api/events/{event}/passes`
- `POST /api/events/{event}/passes/bulk-generate`
- `GET /api/events/{event}/package`
- `POST /api/devices/{device}/approve`
- `GET /api/admin/dashboard`
- `GET /api/stats`

## GitHub Workflows

- `Turbo App Automation`: validates Composer config, runs migrated seeded Laravel tests, starts a live Laravel server, exercises the mobile API contract, and runs Flutter analysis/tests.
- `Turbo Mobile Build`: runs seeded Laravel tests first, generates Android platform files, analyzes/tests Flutter, builds release APKs with `--split-per-abi`, optionally builds an AAB, uploads artifacts, and publishes release assets outside pull requests.

Workflow release assets include ABI-specific APKs and a Laravel shared-hosting zip with root `index.php` and `.htaccess` support.

## Project Layout

```text
backend/                 Laravel API, migrations, factories, seeders, tests
mobile/                  Flutter mobile app
scripts/                 Local preflight and automation helpers
.github/workflows/       CI, smoke, and Android release automation
```

## Local Verification

```bash
cd backend && composer validate --strict && php artisan test
cd ../mobile && flutter analyze && flutter test
./scripts/local-preflight.sh
```
