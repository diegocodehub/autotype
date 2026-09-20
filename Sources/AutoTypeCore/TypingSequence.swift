import CoreGraphics

struct KeyStroke {
    var keyCode: CGKeyCode = 0
    var text: String? = nil
    var flags: CGEventFlags = []
    var delay: Double
}

/// Produces only the next small batch, so large inputs remain cancellable.
struct TypingSequence: Sequence, IteratorProtocol {
    private var characters: String.Iterator
    private var lookahead: Character?
    private var pending: ArraySlice<KeyStroke> = []
    private let options: TypingOptions
    private let chunkLimit = 20 // Small UTF-16 payloads for Quartz text events.

    init(_ text: String, options: TypingOptions) {
        characters = text.makeIterator()
        self.options = options
    }

    mutating func next() -> KeyStroke? {
        if let stroke = pending.popFirst() { return stroke }
        guard let character = takeCharacter() else { return nil }

        if isNewline(character) {
            let delay = options.fixIndentation ? 0.05 : (options.instant ? 0.005 : options.characterDelay)
            if options.fixIndentation {
                // Replace even an empty selection with a space before Delete:
                // deleting an empty selection directly would join the lines.
                pending = [
                    KeyStroke(keyCode: 123, flags: [.maskCommand, .maskShift], delay: 0.025),
                    KeyStroke(text: " ", delay: 0.025),
                    KeyStroke(keyCode: 51, delay: 0.025)
                ][...]
            }
            return KeyStroke(keyCode: 36, delay: delay)
        }

        var payload = String(character)
        var length = payload.utf16.count
        if options.instant && length <= chunkLimit {
            while let candidate = characters.next() {
                let size = String(candidate).utf16.count
                if isNewline(candidate) || length + size > chunkLimit {
                    lookahead = candidate
                    break
                }
                payload.append(candidate)
                length += size
            }
        }

        let delay = options.instant ? 0.001 : options.characterDelay
        if length <= chunkLimit { return KeyStroke(text: payload, delay: delay) }

        // An unusually long composed character may exceed a payload. Split at
        // scalar boundaries, never between UTF-16 surrogate pairs.
        var chunks: [KeyStroke] = []
        var part = ""
        for scalar in payload.unicodeScalars {
            if part.utf16.count + scalar.utf16.count > chunkLimit {
                chunks.append(KeyStroke(text: part, delay: delay))
                part = ""
            }
            part.unicodeScalars.append(scalar)
        }
        if !part.isEmpty { chunks.append(KeyStroke(text: part, delay: delay)) }
        pending = chunks[...]
        return pending.popFirst()
    }

    private mutating func takeCharacter() -> Character? {
        if let character = lookahead {
            lookahead = nil
            return character
        }
        return characters.next()
    }

    private func isNewline(_ character: Character) -> Bool {
        character == "\n" || character == "\r" || character == "\r\n"
    }
}
