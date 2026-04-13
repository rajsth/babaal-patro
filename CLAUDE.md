# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter pub get                    # Install dependencies
flutter run                        # Run on connected device
flutter build apk --release        # Release APK (output: build/app/outputs/flutter-apk/app-release.apk)
flutter build apk --release --split-per-abi  # Smaller per-ABI APKs
flutter build ios --release        # iOS release build
flutter analyze                    # Lint/static analysis (no flags needed)
```

No test suite exists. Web deployment is handled by `.github/workflows/deploy-web.yml` (triggers on GitHub release publish).

## Architecture

Flutter app using **Riverpod** for state management. Nepali calendar (Bikram Sambat) with BS months having variable lengths (29-32 days) — this is the core complexity that drives most design decisions.

### Layer organization (`lib/`)

- **core/** — Pure utilities with no UI dependency: date conversion (`nepali_date_helper.dart`), theme (`app_theme.dart`), localization (`app_localizations.dart`), holiday data (`calendar_data_service.dart`, `nepali_holidays.dart`)
- **models/** — Single model: `Reminder` with category/recurrence/alert enums
- **providers/** — Riverpod StateNotifiers: calendar navigation, reminders (syncs local + Firestore), theme, settings, language, auth, app updates
- **screens/** — Calendar, Events, Converter, Settings, Splash
- **services/** — Notification scheduling, Firestore sync, GitHub release update checker
- **widgets/** — Calendar grid, weekday row, date banner, monthly holidays, dialogs

### Nepali date conversion

`NepaliDateHelper` wraps `nepali_utils` but includes a custom `_adToBS()` that uses `DateTime.utc()` exclusively to avoid DST bugs. Reference point: BS 1970/1/1 = AD 1913/4/13. Always use UTC constructors for date arithmetic — this was a hard-won fix (see BUGS.md).

### Calendar data

Holiday/event/tithi/panchangam data loads from `assets/data/artifact-YYYY.json` files (currently 2081-2083). `CalendarDataService` auto-discovers all artifact files at startup. Adding a new year requires only dropping a new JSON file in `assets/data/` and listing it in `pubspec.yaml` assets.

`NepaliHolidays` has hardcoded fixed holidays (e.g., New Year on 1/1) and year-specific lunar holidays (Dashain/Tihar) for 2081-2085.

### Home screen widgets — native date computation

Both Android (`NepaliCalendar.kt`) and iOS (`NepaliDateWidget.swift`) compute BS dates natively without calling into Flutter. They replicate the same AD→BS algorithm. This is intentional — widgets must work without the app process running. Accent color is the only value read from SharedPreferences/UserDefaults.

### Notification scheduling

BS-aware scheduling is the hard part. Monthly/yearly BS recurrences can't use fixed intervals because BS months vary 29-32 days. The approach: monthly pre-schedules 24 individual notifications (2 years), yearly pre-schedules 5, each independently converted from BS→AD. Uses `flutter_local_notifications` with `Asia/Kathmandu` timezone.

### Localization

Static `S` class in `app_localizations.dart` — not the standard Flutter l10n package. `S.of(isNepali)` returns all strings. Nepali and English are the two languages.

### Theming

8 accent color presets in `AppTheme.accentOptions`. Each preset bundles a main color, light variant, and a contrasting holiday color (red for cool accents, blue for warm accents to avoid clashing). `AppTheme.saturday` is the holiday color used for weekend days and public holidays throughout the UI.

### Firebase

Auth (Google Sign-In) + Cloud Firestore for reminder sync. Config files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are gitignored — run `flutterfire configure` to generate them.

## Version & Release

Version format: `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`. Bump both version and build number before each release. Release APKs are uploaded to GitHub releases via `gh release create`. The app has an in-app auto-update system that checks GitHub releases.
