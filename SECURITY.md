# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

Only the latest release receives security updates.

## Reporting a Vulnerability

If you discover a security vulnerability in Babaal Patro, please report it responsibly. **Do not open a public issue.**

### How to Report

1. Go to the [Security Advisories](https://github.com/rajsth/babaal-patro/security/advisories) page
2. Click **"Report a vulnerability"** to open a private advisory draft
3. Provide as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Affected versions and platforms
   - Potential impact
   - Suggested fix, if any

### What to Expect

- **Acknowledgement** within 7 days of your report
- **Status update** within 14 days with an assessment and expected timeline
- **Credit** in the release notes once the fix is published (unless you prefer to remain anonymous)

If the vulnerability is accepted, we will work on a fix and coordinate a release. If it is declined, we will explain why.

## Scope

The following are in scope for security reports:

- The Babaal Patro mobile app (Android and iOS)
- Home screen widgets (Android and iOS)
- Firebase authentication and data handling
- Any dependency vulnerability that directly affects this project

The following are **out of scope**:

- Vulnerabilities in Flutter or Dart themselves (report to the [Flutter team](https://github.com/flutter/flutter/security))
- Vulnerabilities in Firebase services (report to [Google](https://about.google/appsecurity/))
- The hosted web version at rajsth.github.io (static build, no server-side processing)

## Best Practices for Contributors

- Never commit secrets, API keys, or Firebase config files
- Keep dependencies up to date
- Run `flutter analyze` to catch potential issues before submitting PRs
