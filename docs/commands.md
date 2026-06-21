# Quick Commands

## Laravel

```bash
# Setup
cd laravel && composer install && cp .env.example .env && php artisan key:generate && php artisan migrate:fresh --seed

# Development server
cd laravel && php artisan serve --host=0.0.0.0 --port=8000
```

## Flutter

```bash
# Build release APK (split per ABI)
cd flutter && flutter pub get && flutter build apk --release --split-per-abi

# Development
cd flutter && flutter run

# Analysis & tests
flutter analyze && flutter test
```

## Docker

```bash
docker-compose up -d
```

## GitHub Actions

Run the release workflow manually:
- Go to Actions tab → Release - APK & Laravel Shared Hosting → Run workflow
- Select build_type: `all`, `android`, or `laravel`