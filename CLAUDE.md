# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`vexa_finance` is a Flutter application targeting Android, iOS, Web, Windows, macOS, and Linux. It is currently in early development — the app foundation is in place but finance features are not yet implemented.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis / lint
flutter build apk        # Build Android APK
flutter build web        # Build web version
```

## Architecture

- `lib/main.dart` — entry point; Material app with deep purple seed color theme
- `test/widget_test.dart` — widget test suite
- Platform directories (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) contain platform-specific scaffolding; no custom native code yet

## Dependencies

Defined in `pubspec.yaml`. Currently minimal:
- `cupertino_icons` — iOS-style icons
- `flutter_lints` — linting rules (configured via `analysis_options.yaml`)

Run `flutter pub get` after any change to `pubspec.yaml`.

## Linting

The project uses `flutter_lints` via `analysis_options.yaml`. Run `flutter analyze` to catch issues before committing.
