# Babaal Patro (ababal Patro)

A modern Nepali Calendar (Bikram Sambat) app built with Flutter. Designed for everyday use with a clean, minimal interface that feels native to Nepali users.

## Features

- BS (Bikram Sambat) calendar with monthly grid view
- Today's date highlighted with quick navigation
- Holiday listings for each month
- BS to AD and AD to BS date converter
- Custom events and reminders with recurring support
- Multiple accent color themes (Dark & Light mode)
- Android home screen widget showing today's Nepali date and time
- Devanagari numerals and Nepali language throughout

## Screenshots

_Coming soon_

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Local Storage:** SharedPreferences
- **Date Engine:** nepali_utils
- **Widget:** Android AppWidgetProvider (Kotlin)

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.0
- Android Studio / Xcode

### Run

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --split-per-abi
```

## Project Structure

```
lib/
  core/           # Theme, helpers, constants
  providers/      # Riverpod state providers
  screens/        # Calendar, Events, Converter, Splash
  widgets/        # Calendar grid, date banner, holidays, dialogs
android/
  app/src/main/
    kotlin/       # Android home screen widget (Kotlin)
    res/          # Widget layouts, drawables
```

## License

MIT
