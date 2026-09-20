# AutoType for Mac — first release

## Scope

A native, single-window Mac app. Paste text into a large plain-text box, optionally expand Options, click Send, and focus the destination during the chosen countdown. No Terminal needed for recipients.

## Controls

- Large plain-text input with whitespace preserved and automatic text substitutions disabled.
- Full-width **Send** button directly below the input; no decorative heading, icon, subtitle, or character counter.
- **Options** disclosure collapsed by default, containing the delay, speed, and mode controls.
- **Start delay**, 1–60 seconds; default 3. Snapshot the chosen delay when sending starts.
- **Fix automatic indentation**, off by default: existing `--code` behavior.
- **Speed** slider, 10–40 characters per second; default 40. The current CLI speed is the baseline, not a universal compatibility guarantee.
- **Instant mode**, off by default and labeled experimental: bounded Unicode chunks sent through keyboard events. The speed slider is disabled in this mode. No paste commands or clipboard delivery.
- **Send**, visible countdown while running, and **Stop**. Escape stops while another app is focused.

## Behavior

Normal mode sends individual characters. Instant mode attempts visually rapid insertion; multi-character events are not equivalent to individual character events, and apps may handle them differently. Neither mode can guarantee how every destination responds.

Indentation correction remains optional in both modes. It clears editor-generated leading spaces after Return using Command-Shift-Left, a temporary space, and Delete, then enters the original whitespace. Keep short waits around these operations. Start on an empty line; destination shortcuts and automatic completion can affect the result.

One run at a time. Snapshot input and options before countdown. Never type into AutoType itself. Stop if the user switches to another app during sending. Cancellation cannot retract events already delivered. Do not automatically retry or fall back to paste.

Text stays in memory. No accounts, analytics, history, cloud sync, settings window, or automatic updater. If Send is clicked without Accessibility permission, open the settings and show a short explanation. Also provide a settings button inside Options while permission is missing.

## Implementation and checks

SwiftUI window, AppKit plain-text editor, shared Quartz keyboard engine for app and CLI. macOS 13+, universal Apple silicon and Intel build. No third-party dependencies.

Keep six focused tests for whitespace/indentation, newline normalization, Unicode chunks, speed, cancellation, and delivery failures. Build both architectures and check the app opens. Do a brief native text-field check if local Accessibility access permits it. No specific destination website or exhaustive compatibility testing is required, per the user's decision.

## Distribution

Public MIT-licensed GitHub repository at `diegocodehub/autotype`. Free static GitHub Pages site from `docs/`; DMG hosted in Releases. Keep signing material, local settings, test artifacts, and generated builds out of Git.

Use the owner's Developer ID Application certificate, hardened runtime, and Apple's notarization service. Deliver a stapled, validated `AutoType.dmg`. Local ad-hoc builds are labeled for development and are not the public download. See [RELEASING.md](RELEASING.md).

First-release completion requires the app, focused checks, and a signed/notarized DMG. Availability of signing credentials may block the final distribution step without blocking local development or publishing source.
