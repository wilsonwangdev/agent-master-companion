#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="AgentMasterCompanion"
PROJECT="$PROJECT_DIR/AgentMasterCompanion.xcodeproj"
ARCHIVE_PATH="$BUILD_DIR/$SCHEME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
DMG_STAGING="$BUILD_DIR/dmg-staging"

VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
if [ -z "$VERSION" ]; then
  echo "Error: no git tag found. Create a tag first: git tag v0.1.0"
  exit 1
fi
DMG_NAME="AgentMasterCompanion-${VERSION}-universal.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "Building AgentMasterCompanion v${VERSION}"
echo "==========================================="

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Archive (universal binary, no code signing)
# Tee full log to a file so CI failures can be inspected; print only
# progress lines + errors to stdout so the console stays readable.
echo "Archiving..."
ARCHIVE_LOG="$BUILD_DIR/archive.log"
set +e
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  2>&1 | tee "$ARCHIVE_LOG" | grep -E "^(=== |\\*\\* |[^ ].*error:|[^ ].*warning:)" || true
ARCHIVE_STATUS=${PIPESTATUS[0]}
set -e
if [ "$ARCHIVE_STATUS" -ne 0 ]; then
  echo ""
  echo "Archive failed. Tail of full log:"
  tail -40 "$ARCHIVE_LOG"
  exit "$ARCHIVE_STATUS"
fi

# Export
echo "Exporting..."
mkdir -p "$EXPORT_PATH"

# For unsigned builds, copy directly from archive
APP_PATH="$ARCHIVE_PATH/Products/Applications/$SCHEME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "Error: .app not found at $APP_PATH"
  exit 1
fi
cp -R "$APP_PATH" "$EXPORT_PATH/"

# Create DMG
echo "Creating DMG..."
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$EXPORT_PATH/$SCHEME.app" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$SCHEME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDBZ \
  "$DMG_PATH"

rm -rf "$DMG_STAGING"

# Checksum
echo "Generating checksum..."
cd "$BUILD_DIR"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"

echo ""
echo "Done!"
echo "  DMG: $DMG_PATH"
echo "  SHA: $BUILD_DIR/${DMG_NAME}.sha256"
echo "  Size: $(du -h "$DMG_PATH" | cut -f1)"
