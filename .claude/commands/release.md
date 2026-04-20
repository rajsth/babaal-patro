Build a release APK and publish it as a GitHub release.

## Arguments

$ARGUMENTS — The release title suffix and description. Format: `<title> -- <description of changes>`. Example: `Sunday Holiday -- Added Sunday as a weekly holiday`. If no arguments provided, ask the user for a release title and description before proceeding.

## Steps

1. **Read current version** from `pubspec.yaml`. Extract the current `version: MAJOR.MINOR.PATCH+BUILD`.

2. **Bump version**: Increment the PATCH by 1 and BUILD by 1. For example `1.1.1+4` becomes `1.1.2+5`. Edit `pubspec.yaml` with the new version.

3. **Build the release APK**:
   ```bash
   cd /Users/raj/personal/babaal-patro && flutter build apk --release
   ```
   The output APK will be at `build/app/outputs/flutter-apk/app-release.apk`. If the build fails, stop and report the error.

4. **Parse arguments**: Split `$ARGUMENTS` on ` -- `. The part before `--` is the title suffix, the part after is the change description. If there's no `--`, treat the entire argument as the title suffix and ask the user for a description.

5. **Create the GitHub release** using `gh release create`:
   - Tag: `v{NEW_VERSION}` (e.g., `v1.1.2`)
   - Title: `v{NEW_VERSION} - {title suffix}` (e.g., `v1.1.2 - Sunday Holiday`)
   - Body: Format the description as a markdown release note with a `## What's New` section
   - Attach: `build/app/outputs/flutter-apk/app-release.apk`
   
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z - Title" --notes "body" build/app/outputs/flutter-apk/app-release.apk
   ```

6. **Commit the version bump**: Stage and commit `pubspec.yaml` with message `bump version to X.Y.Z+BUILD`.

7. **Report**: Show the user the release URL and the new version number.
