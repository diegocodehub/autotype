import AutoTypeCore
import CoreGraphics
import Foundation

@main
struct AutoTypeCLI {
    static let usage = """
    Usage: autotype [--code] [--instant] [--speed 10...40] [--] "text to type"

      --code     Clear editor-generated indentation after each Return.
      --instant  Send small text chunks through keyboard events (experimental).
      --speed    Characters per second, 10–40; default 40. Ignored with --instant.
      --help     Show this help.

    Focus the destination during the three-second countdown. Control-C stops
    the CLI. Code mode requires macOS Command-Shift-Left and an empty starting
    line. Neither mode uses clipboard paste. Editors may alter received text.
    """

    @MainActor
    static func main() async {
        var args = Array(CommandLine.arguments.dropFirst())
        if args == ["--help"] || args == ["-h"] { print(usage); return }
        var code = false
        var instant = false
        var speed = 40.0
        while let arg = args.first, arg.hasPrefix("--") {
            args.removeFirst()
            switch arg {
            case "--": break
            case "--code": code = true; continue
            case "--instant": instant = true; continue
            case "--speed":
                guard let value = args.first, let parsed = Double(value), (10...40).contains(parsed) else {
                    fail("Speed must be a number from 10 to 40.\n" + usage)
                }
                speed = parsed
                args.removeFirst()
                continue
            default: fail("Unknown option: \(arg)\n" + usage)
            }
            break
        }
        guard args.count == 1 else { fail(usage) }
        guard CGPreflightPostEventAccess() else {
            _ = CGRequestPostEventAccess()
            fail("Enable your terminal in System Settings → Privacy & Security → Accessibility, then retry.")
        }
        print("Typing in 3 seconds...")
        do {
            try await Task.sleep(for: .seconds(3))
            try await KeyboardTyper.send(args[0], options: TypingOptions(
                fixIndentation: code, instant: instant, charactersPerSecond: speed
            ))
        } catch { fail(error.localizedDescription) }
    }

    static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        exit(1)
    }
}
