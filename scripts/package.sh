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
# Assemble separately so rebuilding never overwrites a running executable.
work_dir="$(mktemp -d "$project_dir/.build/package.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
app="$work_dir/AutoType.app"
mkdir -p "$project_dir/dist"
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
  local_identity="${LOCAL_SIGNING_IDENTITY:-}"
  if [[ -z "$local_identity" ]]; then
    development_identities=()
    while IFS= read -r identity; do
      development_identities+=("$identity")
    done < <(security find-identity -v -p codesigning | awk '/"Apple Development:/ {print $2}')
    if [[ ${#development_identities[@]} -eq 1 ]]; then
      local_identity="${development_identities[0]}"
    else
      local_identity="-"
      echo 'No unique Apple Development identity found. Set LOCAL_SIGNING_IDENTITY for stable permissions.'
    fi
  fi
  codesign --force --sign "$local_identity" "$app"
  dmg="$project_dir/dist/AutoType-local.dmg"
fi
codesign --verify --strict --verbose=2 "$app"

stage="$work_dir/dmg-stage"
mkdir -p "$stage"
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
  if [[ "$local_identity" == "-" ]]; then
    echo 'Ad-hoc signing: Accessibility permission may need removal and re-adding after each rebuild.'
  else
    echo 'Development certificate signing: using a stable identity for local Accessibility permissions.'
  fi
  echo 'This local build is not notarized. Do not publish it as the public download.'
fi

# Swap the completed bundle without changing the old process's executable bytes.
if [[ -e "$project_dir/dist/AutoType.app" ]]; then
  mv "$project_dir/dist/AutoType.app" "$work_dir/previous.app"
fi
mv "$app" "$project_dir/dist/AutoType.app"
