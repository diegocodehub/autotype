#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
release=false
case "${1:-}" in
  "") ;;
  --release) release=true ;;
  *) echo 'Usage: scripts/package.sh [--release]' >&2; exit 1 ;;
esac

if "$release"; then
  : "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application certificate name.}"
  : "${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool Keychain profile name.}"
  case "$SIGNING_IDENTITY" in
    "Developer ID Application:"*) ;;
    *) echo 'A Developer ID Application certificate is required for release.' >&2; exit 1 ;;
  esac
fi

# Distinct names for the app and CLI avoid case-insensitive filesystem collisions.
swift build -c release --product AutoTypeDesktop --arch arm64 --arch x86_64
bin_dir="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
app="$project_dir/dist/AutoType.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/AutoTypeDesktop" "$app/Contents/MacOS/AutoTypeDesktop"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp LICENSE "$app/Contents/Resources/LICENSE"
icon_dir="$project_dir/.build/AutoType.iconset"
swift scripts/make-icon.swift "$icon_dir"
iconutil -c icns "$icon_dir" -o "$app/Contents/Resources/AutoType.icns"
plutil -lint "$app/Contents/Info.plist"
lipo "$app/Contents/MacOS/AutoTypeDesktop" -verify_arch arm64
lipo "$app/Contents/MacOS/AutoTypeDesktop" -verify_arch x86_64

if "$release"; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$app"
  archive="$project_dir/.build/AutoType-notarization.zip"
  ditto -c -k --keepParent "$app" "$archive"
  xcrun notarytool submit "$archive" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose "$app"
  dmg="$project_dir/dist/AutoType.dmg"
else
  codesign --force --sign - "$app"
  dmg="$project_dir/dist/AutoType-local.dmg"
fi
codesign --verify --strict --verbose=2 "$app"

stage="$(mktemp -d "$project_dir/.build/dmg-stage.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/AutoType.app"
ln -s /Applications "$stage/Applications"
hdiutil create -volname AutoType -srcfolder "$stage" -format UDZO -ov "$dmg"

if "$release"; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$dmg"
  xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
  spctl --assess --type open --context context:primary-signature --verbose "$dmg"
  (cd "$project_dir/dist" && shasum -a 256 AutoType.dmg > SHA256SUMS.txt)
  echo "Notarized release ready: $dmg"
else
  echo "Local development build ready: $dmg"
  echo 'This build is ad-hoc signed, not notarized. Do not publish it as the public download.'
fi
