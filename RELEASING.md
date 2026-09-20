# Releasing AutoType

The app is distributed directly, outside the Mac App Store. Apple notarization is an automated security check, not App Store review.

## One-time setup

1. In Xcode, sign in to the Apple Developer Program account.
2. In Xcode's certificate management, create or import a **Developer ID Application** certificate with its private key. An Apple Development certificate is not sufficient. The team account holder creates Developer ID certificates.
3. Store notarization authentication in the Keychain, using the interactive command below. Enter credentials locally at its prompts; do not put passwords, private keys, or certificates in the repository.

```bash
xcrun notarytool store-credentials AutoType
```

The app uses bundle identifier `io.github.diegocodehub.autotype`. Keep it stable between releases. The app does not require App Store provisioning or sandbox capabilities.

## Build and notarize

Update the version and build number in `Resources/Info.plist`, run `swift test`, then:

```bash
SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' \
NOTARY_PROFILE='AutoType' \
./scripts/package.sh --release
```

This builds Apple silicon and Intel binaries, signs the app with hardened runtime, notarizes and staples the app, creates a DMG, and signs/notarizes/staples the DMG. Both app and DMG are validated. Without `--release`, the script produces only a local development build.

Keep all `dist/` contents out of Git. The script stops on any signing, notarization, or validation failure. Only publish after its final **Notarized release ready** message.

## Brief release check

Open the final DMG, install the app, and check permission onboarding, one short text/code example, and Escape during a run. Use a clean Mac if one is available. The two optional modes remain user choices; no specific website or broad compatibility matrix is a release requirement. Keep instant mode labeled experimental.

Before committing, inspect the staged file list and diff. `.gitignore` excludes build output, environment files, local editor settings, common signing files, and packaged binaries. Ignore rules supplement review; they are not a guarantee that arbitrary files contain no secrets.

## Publish

Create a GitHub Release for the version and attach only:

- `dist/AutoType.dmg`
- `dist/SHA256SUMS.txt`

Use the asset name `AutoType.dmg` consistently. The Pages website enables its download button when the latest public release has that asset. Never publish a local ad-hoc build as the notarized download. Updates are manual downloads for this release.

Apple references: [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates), [notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), [notarization credentials and workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).
