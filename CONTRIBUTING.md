# Contributing to Babaal Patro

Thank you for your interest in contributing to Babaal Patro (बबाल पात्रो)! This guide will help you get started.

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please [open an issue](https://github.com/rajsth/babaal-patro/issues/new) with the following details:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs. actual behavior
- Device/platform info (Android version, iOS version, etc.)
- Screenshots or screen recordings, if applicable

### Suggesting Features

Feature requests are welcome. Please open an issue and include:

- A clear description of the feature and the problem it solves
- Why this would be useful to other users of a Nepali calendar app
- Any mockups or examples, if you have them

### Submitting Changes

1. Fork the repository
2. Create a feature branch from `main` (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test on at least one platform (Android or iOS)
5. Run linting and analysis (see below)
6. Commit your changes with a clear, descriptive message
7. Push to your fork and [open a pull request](https://github.com/rajsth/babaal-patro/pulls)

## Development Setup

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) >= 3.11.0
- Dart (included with Flutter)
- Android Studio or Xcode (for platform-specific development)
- Java 17 (for Android builds)

### Getting Started

```bash
# Clone your fork
git clone https://github.com/<your-username>/babaal-patro.git
cd babaal-patro

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

This project uses Firebase for authentication and Firestore. You will need to set up your own Firebase project and add the configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS). These files are not included in the repo for security reasons.

### Running Checks

Before submitting a PR, make sure your code passes analysis:

```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Build to verify no compile errors
flutter build apk --debug
```

## Code Style

- Follow the [Dart style guide](https://dart.dev/effective-dart/style)
- This project uses `flutter_lints` — run `flutter analyze` and fix any warnings
- Use Riverpod for state management, consistent with the existing codebase
- Keep widgets small and composable

## Project Structure

```
lib/
  core/       # Theme, colors, date helpers
  models/     # Data models and enums
  providers/  # Riverpod providers
  screens/    # Full-page screens
  services/   # Platform services (notifications, etc.)
  widgets/    # Reusable UI components
```

Place new code in the appropriate directory. If you're unsure, mention it in your PR and we can discuss.

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR
- Reference any related issues (e.g., "Fixes #12")
- Describe what changed and why in the PR description
- Include screenshots for UI changes
- Make sure `flutter analyze` passes with no issues

## Platform-Specific Contributions

- **Android widget code** is in `android/` (Kotlin, AppWidgetProvider)
- **iOS widget code** is in `ios/` (SwiftUI, WidgetKit)

If you're contributing to platform-specific features, please test on the relevant platform.

## License

By contributing to Babaal Patro, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).

## Questions?

If you have questions about contributing, feel free to open an issue and tag it with `question`.
