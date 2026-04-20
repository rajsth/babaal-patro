#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# --- Parse arguments ---
BUMP_TYPE="${1:-patch}"  # patch (default), minor, or major

if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
  echo "Usage: ./scripts/release.sh [patch|minor|major]"
  echo "  patch  — 1.1.1 → 1.1.2 (default)"
  echo "  minor  — 1.1.1 → 1.2.0"
  echo "  major  — 1.1.1 → 2.0.0"
  exit 1
fi

# --- Read current version ---
CURRENT=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
VERSION="${CURRENT%%+*}"
BUILD="${CURRENT##*+}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# --- Bump version ---
case "$BUMP_TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

BUILD=$((BUILD + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}+${BUILD}"
TAG="v${MAJOR}.${MINOR}.${PATCH}"

echo "Version: $CURRENT → $NEW_VERSION (tag: $TAG)"
echo ""

# --- Confirm ---
read -rp "Proceed? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# --- Update pubspec.yaml ---
sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "Updated pubspec.yaml to $NEW_VERSION"

# --- Build release APKs ---
echo ""
echo "Building release APKs (split-per-abi)..."
flutter build apk --release --split-per-abi

APK_DIR="build/app/outputs/flutter-apk"
APKS=("$APK_DIR"/app-*-release.apk)

if [[ ${#APKS[@]} -eq 0 ]]; then
  echo "Error: no APKs found in $APK_DIR"
  exit 1
fi

echo ""
echo "Built APKs:"
for apk in "${APKS[@]}"; do
  echo "  $(basename "$apk") ($(du -h "$apk" | awk '{print $1}'))"
done

# --- Commit & tag ---
echo ""
git add pubspec.yaml
git commit -m "release $TAG"
git tag "$TAG"
echo "Created commit and tag $TAG"

# --- Push ---
echo ""
echo "Pushing to origin..."
git push
git push origin "$TAG"

# --- Create GitHub release ---
echo ""
echo "Creating GitHub release..."
gh release create "$TAG" "${APKS[@]}" \
  --title "$TAG" \
  --generate-notes

echo ""
echo "Done! Release $TAG published."
echo "https://github.com/$(gh repo view --json nameWithOwner -q '.nameWithOwner')/releases/tag/$TAG"
