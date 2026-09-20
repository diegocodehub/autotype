public struct TypingOptions: Sendable {
    public var fixIndentation: Bool
    public var instant: Bool
    public let charactersPerSecond: Double

    public init(fixIndentation: Bool = false, instant: Bool = false, charactersPerSecond: Double = 40) {
        self.fixIndentation = fixIndentation
        self.instant = instant
        self.charactersPerSecond = charactersPerSecond.isFinite
            ? min(40, max(10, charactersPerSecond)) : 40
    }

    var characterDelay: Double { 1 / charactersPerSecond }
}
