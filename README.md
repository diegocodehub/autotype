# AutoType

A small Mac app that sends your text as keyboard events. Paste code or other text into AutoType, click **Send**, then focus the destination during the countdown (3 seconds by default).

**Status:** First app implementation. Local builds are available from source; the public notarized download is still being prepared.

[Project website](https://diegocodehub.github.io/autotype/) · [Releases](https://github.com/diegocodehub/autotype/releases) · [MIT license](LICENSE)

## Using the app

1. Open AutoType and enable it in **System Settings → Privacy & Security → Accessibility** when prompted. If permission is missing, clicking Send opens the permission settings.
2. Enter your text. The window shows a large text field and a full-width **Send** button.
3. Expand **Options** if needed: set the start delay (1–60 seconds, default 3), typing speed (10–40 characters per second), **Fix automatic indentation**, or **Instant mode**. Options are collapsed when the app opens.
4. Click **Send**, then click the destination before your chosen countdown ends.
5. Press **Escape** to stop. Switching to a different app during sending also stops the run.

**Fix automatic indentation** removes indentation added by the receiving editor after Return, then types your original whitespace. Start at the beginning of an empty line. This mode requires the destination's macOS Command-Shift-Left shortcut. Quote/bracket completion and formatting in the destination may also change text.

**Instant mode** is experimental. It sends small Unicode text chunks through keyboard events instead of delaying between individual characters. It never invokes clipboard paste. Receiving apps may process chunks differently; it is not a guarantee of instant insertion or compatibility. Indentation correction still takes a short pause at every newline.

Stop cancels the remaining work, not text or events already delivered. The Escape shortcut also reaches the destination application. “Finished sending” means events were sent, not that the destination was inspected.

## Privacy

Text stays in memory and is discarded when the app quits. AutoType has no accounts, analytics, cloud service, or text history. Sending does not read or modify the clipboard. The app observes Escape while a run is active so you can stop without switching back; it does not record your typing. Signing credentials belong in the macOS Keychain and are never part of this repository.

## Build locally

Requires macOS 13 or later and Xcode with Swift 6 or newer. No third-party dependencies.

```bash
swift build
swift test
./scripts/package.sh
open dist/AutoType.app
```

The packaging script builds a universal app for Apple silicon and Intel, creates its icon, and produces `dist/AutoType-local.dmg`. This is a local development build, **not a notarized public release**. The script automatically uses an Apple Development certificate when exactly one is available; set `LOCAL_SIGNING_IDENTITY` to select a specific certificate. Reuse that identity across builds so macOS can recognize the app. If no unique development certificate is available, the script falls back to ad-hoc signing and prints a warning.

If Accessibility is enabled but the app reports no access after a rebuild, quit AutoType, remove its old entry with **−** in Accessibility settings, use **+** to add the current `dist/AutoType.app`, enable it, and reopen the app. Switching from ad-hoc signing to a certificate also requires this one-time reauthorization. Merely toggling a stale entry may not repair it.

The six focused tests cover indentation/blank lines, newline handling, Unicode chunking, speed, cancellation, and event failures. They do not send keystrokes to your desktop or claim compatibility with every editor.

## Command line

The original CLI shares the app's typing engine:

```bash
swift run autotype 'Hello from AutoType!'
swift run autotype --code 'if s == "end":
    print("stop")
else:
    print("go")'
swift run autotype --speed 20 'Slower typing'
swift run autotype --instant 'Fast text delivery'
swift run autotype --help
```

Combine `--code` and `--instant` if needed. The CLI needs Accessibility permission for your terminal; Control-C stops it. Use `--` before text beginning with `--`. Shell quotes are shell syntax, so code containing a single quote needs appropriate shell quoting; the app's text box avoids this issue.

## Public release

See [RELEASING.md](RELEASING.md) for Developer ID signing, notarization, and publication. The DMG belongs in GitHub Releases, not Git history. The website is served from `docs/` using GitHub Pages.

## Project structure

- `Sources/AutoTypeCore/` — shared keyboard-event engine.
- `Sources/AutoTypeApp/` — native SwiftUI app and plain-text editor.
- `Sources/autotype/` — CLI entry point.
- `Tests/AutoTypeCoreTests/` — focused regression tests.
- `Resources/` and `scripts/` — app metadata, icon drawing, and packaging.
- `docs/` — static download website; no build tooling required.
- [APP_SPEC.md](APP_SPEC.md) — first-release scope.

Bug reports and small, focused contributions are welcome. Include your macOS version, the receiving app, the selected modes, and a non-sensitive example when reporting delivery issues.
