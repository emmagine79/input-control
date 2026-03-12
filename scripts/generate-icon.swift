import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 3 else {
    fputs("usage: generate-icon.swift <png-destination> <size>\n", stderr)
    exit(1)
}

let destinationURL = URL(fileURLWithPath: arguments[1])
guard let size = Double(arguments[2]) else {
    fputs("size must be numeric\n", stderr)
    exit(1)
}

let pixelWidth = Int(size.rounded())
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelWidth,
    pixelsHigh: pixelWidth,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("unable to create bitmap\n", stderr)
    exit(1)
}

bitmap.size = NSSize(width: size, height: size)

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("unable to acquire graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext
let context = graphicsContext.cgContext

context.setFillColor(NSColor.clear.cgColor)
context.fill(CGRect(origin: .zero, size: CGSize(width: size, height: size)))

let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size)).insetBy(dx: size * 0.055, dy: size * 0.055)
let cornerRadius = size * 0.225
let roundedRect = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

context.saveGState()
roundedRect.addClip()

let baseGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.12, green: 0.17, blue: 0.30, alpha: 1.0),
    NSColor(calibratedRed: 0.23, green: 0.46, blue: 0.88, alpha: 1.0),
    NSColor(calibratedRed: 0.52, green: 0.83, blue: 0.95, alpha: 1.0)
])!
baseGradient.draw(in: roundedRect, angle: 310)

let glowRect = rect.insetBy(dx: -size * 0.10, dy: -size * 0.10)
let glowGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.96, green: 0.99, blue: 1.0, alpha: 0.65), 0.0),
    (NSColor(calibratedRed: 0.86, green: 0.95, blue: 1.0, alpha: 0.18), 0.40),
    (NSColor.clear, 1.0)
)!
glowGradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: NSPoint(x: -0.35, y: 0.55))

let glassOverlayRect = CGRect(
    x: rect.minX + size * 0.035,
    y: rect.midY + size * 0.03,
    width: rect.width - size * 0.07,
    height: rect.height * 0.38
)
let glassOverlay = NSBezierPath(roundedRect: glassOverlayRect, xRadius: size * 0.16, yRadius: size * 0.16)
NSColor.white.withAlphaComponent(0.18).setFill()
glassOverlay.fill()

context.restoreGState()

NSColor.white.withAlphaComponent(0.17).setStroke()
roundedRect.lineWidth = max(2.0, size * 0.012)
roundedRect.stroke()

let innerGlowRect = rect.insetBy(dx: size * 0.06, dy: size * 0.06)
let innerGlow = NSBezierPath(roundedRect: innerGlowRect, xRadius: size * 0.18, yRadius: size * 0.18)
NSColor.white.withAlphaComponent(0.10).setStroke()
innerGlow.lineWidth = max(1.0, size * 0.008)
innerGlow.stroke()

let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * 0.40, weight: .semibold, scale: .large)
let symbolRect = CGRect(
    x: size * 0.24,
    y: size * 0.25,
    width: size * 0.52,
    height: size * 0.52
)

if let microphone = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
    let micImage = microphone.copy() as! NSImage
    micImage.isTemplate = false
    micImage.lockFocus()
    NSColor.white.withAlphaComponent(0.96).set()
    NSRect(origin: .zero, size: micImage.size).fill(using: .sourceAtop)
    micImage.unlockFocus()
    micImage.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)
}

func strokeArc(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, lineWidth: CGFloat, alpha: CGFloat) {
    let center = CGPoint(x: size * 0.5, y: size * 0.50)
    let path = NSBezierPath()
    path.appendArc(
        withCenter: center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: false
    )
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    NSColor.white.withAlphaComponent(alpha).setStroke()
    path.stroke()
}

strokeArc(radius: size * 0.205, startAngle: 208, endAngle: 332, lineWidth: size * 0.030, alpha: 0.78)
strokeArc(radius: size * 0.275, startAngle: 214, endAngle: 326, lineWidth: size * 0.022, alpha: 0.48)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("unable to encode png\n", stderr)
    exit(1)
}

try pngData.write(to: destinationURL, options: .atomic)
