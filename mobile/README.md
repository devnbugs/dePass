# GatePassX Mobile App (Phase 3)

A Flutter mobile app scaffold for secure event scanning and pass management.

## Getting Started

1. Install Flutter SDK.
2. Open `mobile` in your editor.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```

## Current Scope

- Login screen
- Dashboard with event/pass navigation
- GatePass QR scanner with instant validation states
- Event detail placeholder
- Passes placeholder
- Theme built with a template-inspired design system

## Android Release Notes

The CI build expects Android release settings to stay aligned with the current Flutter toolchain:

- Java 17
- Android SDK Platform 34 or later
- `compileSdkVersion 34`
- `targetSdkVersion 34`
- `minSdkVersion 21`
- Camera permission is injected into the generated Android manifest during the release workflow
