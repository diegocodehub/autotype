import CoreGraphics
import Foundation

public enum TypingError: LocalizedError {
    case eventCreation

    public var errorDescription: String? { "Could not create keyboard events. Try restarting AutoType." }
}

@MainActor
public enum KeyboardTyper {
    public static func send(
        _ text: String,
        options: TypingOptions,
        beforeStroke: () throws -> Void = {}
    ) async throws {
        guard let source = CGEventSource(stateID: .privateState) else { throw TypingError.eventCreation }
        try await run(text, options: options) { stroke in
            try beforeStroke()
            guard
                let down = makeEvent(stroke, source: source, down: true),
                let up = makeEvent(stroke, source: source, down: false)
            else { throw TypingError.eventCreation }
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }

    static func run(
        _ text: String,
        options: TypingOptions,
        post: (KeyStroke) throws -> Void,
        pause: (Double) async throws -> Void = { seconds in
            try await Task.sleep(for: .seconds(seconds))
        }
    ) async throws {
        for stroke in TypingSequence(text, options: options) {
            try Task.checkCancellation()
            try post(stroke)
            // Yield after every small payload: the UI and Escape remain responsive.
            try await pause(stroke.delay)
        }
    }

    private static func makeEvent(_ stroke: KeyStroke, source: CGEventSource, down: Bool) -> CGEvent? {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: stroke.keyCode, keyDown: down)
        else { return nil }
        event.flags = stroke.flags
        // A fixed marker distinguishes our generated events from physical Escape.
        event.setIntegerValueField(.eventSourceUserData, value: eventMarker)
        if let text = stroke.text {
            let utf16 = Array(text.utf16)
            utf16.withUnsafeBufferPointer {
                event.keyboardSetUnicodeString(stringLength: $0.count, unicodeString: $0.baseAddress!)
            }
        }
        return event
    }

    public nonisolated static let eventMarker: Int64 = 0x4155544F54595045
}
