import AppKit

func star(center: CGPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    for index in 0..<8 {
        let radius = index.isMultiple(of: 2) ? outer : inner
        let angle = CGFloat(index) * .pi / 4 - .pi / 2
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        index == 0 ? path.move(to: point) : path.line(to: point)
    }
    path.close()
    return path
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024
    let rect = CGRect(x: size * 0.085, y: size * 0.085, width: size * 0.83, height: size * 0.83)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = 26 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -12 * scale)
    shadow.set()

    let orb = NSBezierPath(ovalIn: rect)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.43, green: 0.43, blue: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.10, green: 0.68, blue: 0.90, alpha: 1),
        NSColor(calibratedRed: 0.14, green: 0.90, blue: 0.66, alpha: 1)
    ])!
    gradient.draw(in: orb, angle: -92)
    NSShadow().set()

    let gloss = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.08, dy: size * 0.1))
    context.saveGState()
    gloss.addClip()
    NSColor.white.withAlphaComponent(0.16).setFill()
    NSBezierPath(rect: CGRect(x: rect.minX, y: rect.midY + size * 0.12, width: rect.width, height: rect.height)).fill()
    context.restoreGState()

    NSColor.white.setFill()
    star(center: CGPoint(x: size * 0.42, y: size * 0.49), outer: size * 0.23, inner: size * 0.07).fill()
    star(center: CGPoint(x: size * 0.71, y: size * 0.72), outer: size * 0.07, inner: size * 0.023).fill()

    image.unlockFocus()
    return image
}

func writePNG(image: NSImage, to url: URL) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode \(url.path)")
    }
    try! data.write(to: url)
}

let root = URL(fileURLWithPath: CommandLine.arguments[1])
try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
let iconURL = root.appendingPathComponent("CodexQuotaIcon.png")
writePNG(image: drawIcon(size: 1024), to: iconURL)

let iconset = root.appendingPathComponent("CodexQuota.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for entry in entries {
    writePNG(image: drawIcon(size: entry.1), to: iconset.appendingPathComponent(entry.0))
}
