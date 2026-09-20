import CoreGraphics
import XCTest
@testable import AutoTypeCore

final class TypingTests: XCTestCase {
    // A minimal receiving editor models automatic indentation and macOS line
    // selection. No test posts keystrokes to the user's desktop.
    private func receive(_ source: String, indentation: String, options: TypingOptions) -> String {
        var document = ""
        var selectedPrefix = false
        for stroke in TypingSequence(source, options: options) {
            if let text = stroke.text {
                if selectedPrefix {
                    while document.last != nil && document.last != "\n" { document.removeLast() }
                    selectedPrefix = false
                }
                document += text
            } else if stroke.keyCode == 36 {
                document += "\n" + indentation
            } else if stroke.keyCode == 123 && stroke.flags == [.maskCommand, .maskShift] {
                selectedPrefix = true
            } else if stroke.keyCode == 51 {
                if !document.isEmpty { document.removeLast() }
            } else { XCTFail("Unexpected key: \(stroke.keyCode)") }
        }
        return document
    }

    func testIndentationAndBlankLinesInBothModes() {
        let examples = [
            "if s == \"end\":\n    print(\"stop\")\nelse:\n    print(\"go\")",
            "\nfirst\n\n  second\n\n",
            "if ready:\n\tif valid:\n\t\tprint(\"café 👋\")  \n\tfinish()\ndone()"
        ]
        for instant in [false, true] {
            for indentation in ["", "    ", "\t\t"] {
                for source in examples {
                    XCTAssertEqual(receive(source, indentation: indentation,
                        options: TypingOptions(fixIndentation: true, instant: instant)), source)
                }
            }
        }
        XCTAssertNotEqual(receive(examples[0], indentation: "    ", options: TypingOptions()), examples[0])
    }

    func testLineEndingsAndUnmodifiedWhitespace() {
        for instant in [false, true] {
            let options = TypingOptions(instant: instant)
            XCTAssertEqual(receive("a\r\nb\rc\n", indentation: "", options: options), "a\nb\nc\n")
            XCTAssertEqual(receive("  a\n\t b  \n\n", indentation: "", options: options), "  a\n\t b  \n\n")
            XCTAssertEqual(receive("", indentation: "", options: options), "")
        }
    }

    func testBurstChunksPreserveUnicodeAndStayBounded() {
        let source = String(repeating: "abc👨‍👩‍👧‍👦é🇺🇸", count: 30) + "a" + String(repeating: "\u{0301}", count: 35)
        let strokes = Array(TypingSequence(source, options: TypingOptions(instant: true)))
        XCTAssertEqual(strokes.compactMap(\.text).joined(), source)
        XCTAssertTrue(strokes.allSatisfy { (1...20).contains($0.text!.utf16.count) })
        XCTAssertLessThan(strokes.count, source.count)
    }

    func testSpeedDoesNotRemoveIndentationWaits() {
        for speed in [10.0, 40.0] {
            let options = TypingOptions(fixIndentation: true, charactersPerSecond: speed)
            let strokes = Array(TypingSequence("a\nb", options: options))
            XCTAssertEqual(strokes.first!.delay, 1 / speed)
            XCTAssertEqual(strokes.last!.delay, 1 / speed)
            XCTAssertEqual(Array(strokes[1...4]).map(\.delay), [0.05, 0.025, 0.025, 0.025])
        }
        XCTAssertEqual(TypingOptions(charactersPerSecond: .nan).charactersPerSecond, 40)
        XCTAssertEqual(TypingOptions(charactersPerSecond: 0).charactersPerSecond, 10)
    }

    @MainActor
    func testCancellationStopsBeforeNextPayload() async {
        let task = Task { @MainActor in
            var sent = 0
            do {
                try await KeyboardTyper.run(String(repeating: "code", count: 100), options: TypingOptions(instant: true), post: { _ in
                    sent += 1
                    withUnsafeCurrentTask { $0?.cancel() }
                }, pause: { _ in })
                XCTFail("Expected cancellation")
            } catch is CancellationError {
                XCTAssertEqual(sent, 1)
            } catch { XCTFail("Unexpected error: \(error)") }
        }
        await task.value
    }

    @MainActor
    func testDeliveryFailureDoesNotResendOrContinue() async {
        for failureIndex in 1...5 {
            var calls = 0
            do {
                try await KeyboardTyper.run("\nx", options: TypingOptions(fixIndentation: true), post: { _ in
                    calls += 1
                    if calls == failureIndex { throw TypingError.eventCreation }
                }, pause: { _ in })
                XCTFail("Expected delivery failure")
            } catch {
                XCTAssertEqual(calls, failureIndex)
            }
        }
    }
}
