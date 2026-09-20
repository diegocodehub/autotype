import AppKit

// Draw a native vector mark at each icon size; no external assets or dependencies.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()

        let base = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 202, yRadius: 202)
        NSGradient(starting: NSColor(srgbRed: 0.39, green: 0.40, blue: 0.96, alpha: 1),
                   ending: NSColor(srgbRed: 0.22, green: 0.24, blue: 0.75, alpha: 1))!.draw(in: base, angle: -90)

        NSColor.white.setStroke()
        let keyboard = NSBezierPath(roundedRect: NSRect(x: 225, y: 310, width: 574, height: 404), xRadius: 70, yRadius: 70)
        keyboard.lineWidth = 30
        keyboard.stroke()
        NSColor.white.setFill()
        for row in 0..<2 {
            for column in 0..<5 {
                NSBezierPath(roundedRect: NSRect(x: 289 + column * 91, y: 528 - row * 86, width: 48, height: 42), xRadius: 10, yRadius: 10).fill()
            }
        }
        NSBezierPath(roundedRect: NSRect(x: 380, y: 364, width: 230, height: 28), xRadius: 10, yRadius: 10).fill()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(
            to: directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png")
        )
    }
}
