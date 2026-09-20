import AppKit
@preconcurrency import ApplicationServices
import AutoTypeCore
import SwiftUI

@MainActor
final class TypingModel: ObservableObject {
    @Published var text = ""
    @Published var fixIndentation = false
    @Published var instant = false
    @Published var speed = 40.0
    @Published var startDelay = 3
    @Published private(set) var isRunning = false
    @Published private(set) var hasPermission = AXIsProcessTrusted()
    @Published private(set) var status = ""
    @Published private(set) var hasError = false

    private var task: Task<Void, Never>?
    private var globalEscapeMonitor: Any?
    private var localEscapeMonitor: Any?

    func refreshPermission() { hasPermission = AXIsProcessTrusted() }

    func openPermissionSettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        refreshPermission()
    }

    func start() {
        guard !isRunning, !text.isEmpty else { return }
        refreshPermission()
        guard hasPermission else {
            status = "Allow AutoType in Accessibility. Already enabled? Quit AutoType, remove its old entry with −, add this copy again with +, then reopen."
            hasError = true
            openPermissionSettings()
            return
        }
        let input = text
        let delay = startDelay
        let options = TypingOptions(fixIndentation: fixIndentation, instant: instant, charactersPerSecond: speed)
        hasError = false
        isRunning = true
        installEscapeMonitors()
        guard globalEscapeMonitor != nil, localEscapeMonitor != nil else {
            finish("Could not enable the Escape shortcut. Restart AutoType and check Accessibility access.", error: true)
            return
        }
        task = Task { [weak self] in
            guard let self else { return }
            do {
                for seconds in (1...delay).reversed() {
                    status = "Starting in \(seconds)… Click your destination. Esc to stop."
                    try await Task.sleep(for: .seconds(1))
                }
                try Task.checkCancellation()
                guard let target = NSWorkspace.shared.frontmostApplication,
                      target.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                    finish("Nothing sent. Click another app during the countdown.", error: true)
                    return
                }
                let pid = target.processIdentifier
                status = "Sending to \(target.localizedName ?? "your destination")… Esc to stop."
                try await KeyboardTyper.send(input, options: options) {
                    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else {
                        throw DestinationError.focusChanged
                    }
                    guard AXIsProcessTrusted() else { throw DestinationError.permissionLost }
                }
                finish("Finished sending.")
            } catch is CancellationError {
                finish("Stopped. Text already sent stays in the destination.")
            } catch {
                refreshPermission()
                finish(error.localizedDescription, error: true)
            }
        }
    }

    func stop() { task?.cancel() }

    private func finish(_ message: String, error: Bool = false) {
        status = message
        hasError = error
        isRunning = false
        task = nil
        if let monitor = globalEscapeMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localEscapeMonitor { NSEvent.removeMonitor(monitor) }
        globalEscapeMonitor = nil
        localEscapeMonitor = nil
    }

    private func installEscapeMonitors() {
        globalEscapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53,
                  event.cgEvent?.getIntegerValueField(.eventSourceUserData) != KeyboardTyper.eventMarker else { return }
            MainActor.assumeIsolated { self?.stop() }
        }
        localEscapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            MainActor.assumeIsolated { self?.stop() }
            return nil
        }
    }
}

private enum DestinationError: LocalizedError {
    case focusChanged, permissionLost

    var errorDescription: String? {
        switch self {
        case .focusChanged: "Stopped because you switched apps. Text already sent stays in place."
        case .permissionLost: "Stopped. Restore Accessibility access before sending again."
        }
    }
}
