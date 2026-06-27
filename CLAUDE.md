# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`vexa_finance` ("Vexa") is a personal-finance Flutter app (Android, iOS, Web, Windows, macOS, Linux), in production and used daily. It tracks accounts, transactions, budgets, goals, loans and subscriptions, and layers analytics on top: a financial "Coach" with a local insights engine, a 0–100 Vexa Score, cashflow projections, and a financial calendar. The UI is in Spanish; the default locale is `es`.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter test test/financial_calculations_test.dart  # Run a single test file
flutter analyze          # Static analysis / lint
dart run build_runner build --delete-conflicting-outputs  # Regenerate Isar *.g.dart after model changes
flutter build apk        # Build Android APK
flutter build web        # Build web version
```

## Architecture

Feature-first layout under `lib/features/<feature>/{domain,presentation}`, with cross-cutting code in `lib/core/` and `lib/shared/`.

- **State management:** Riverpod (`StateNotifierProvider` for mutable collections, `Provider` for derived/computed values). The financial brain lives in `lib/features/home/presentation/providers/home_provider.dart` (accounts, transactions, balances, transfers, monthly stats, prediction).
- **Persistence:** [Isar](https://isar.dev) local DB. Entity schemas live in `lib/core/data/isar/` (each `isar_*.dart` has a generated `*.g.dart`). `lib/core/data/isar_service.dart` opens the DB; `core/providers/isar_provider.dart` exposes it. Domain models (`features/**/domain/models`) are plain Dart; each provider converts to/from its `Isar*` row. Some flags (e.g. account `isSavings`, monthly savings tally) are stored via `local_prefs_service.dart` — a lightweight JSON key-value store (`vexa_prefs.json`, atomic tmp+rename writes, in-memory cache) used to avoid Isar schema migrations.
- **Entry point:** `lib/main.dart` opens Isar with a timeout + retry screen and purges debug seed data on first release launch, then mounts `app.dart` inside a `ProviderScope`. `app.dart` watches `subscriptionAutoProcessProvider` so due subscriptions are charged automatically.
- **Money-moving automation:** subscription charges (`subscriptions/.../subscription_processor_provider.dart`), loan origination/payment transactions (`loans_provider.dart`), and savings transfers all create real `Transaction`s and adjust account balances. Writes follow a fail-safe order: persist to Isar first, then mutate in-memory state/balances, with rollback on failure.

## Conventions

- Financial calculations must be mathematically correct and guard against division by zero, empty data, and partial months. Insights/score factors return nothing rather than showing misleading figures when data is insufficient.
- After editing any `lib/core/data/isar/isar_*.dart` model, regenerate code with `build_runner` (see commands).
- Run `flutter analyze` (must be clean) and `flutter test` before committing.

## Dependencies

Defined in `pubspec.yaml`: `flutter_riverpod`, `isar` (+ `isar_flutter_libs`), `path_provider`, `google_fonts`, `intl`, `fl_chart`, `uuid`, `image_picker`, `flutter_secure_storage`, `crypto`, `flutter_local_notifications`, `timezone`, and `flutter_lints` (dev). Run `flutter pub get` after any change to `pubspec.yaml`. Note: local key-value prefs use a custom JSON file (see Architecture), not `shared_preferences`.

## Linting

The project uses `flutter_lints` via `analysis_options.yaml`. Run `flutter analyze` to catch issues before committing.
