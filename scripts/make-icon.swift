#!/usr/bin/env swift
// Generates App/Assets.xcassets/AppIcon.appiconset PNGs.
// Motif: a terminal window (">_") with a Finder-style context menu in front.
// Usage: swift scripts/make-icon.swift
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "App/Assets.xcassets/AppIcon.appiconset")

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func roundedRect(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

/// Draws on a 1024×1024 canvas with a top-left origin.
func draw(_ ctx: CGContext) {
    // Background squircle (macOS icon grid: 824pt body, 100pt margin).
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: color(0x000000, 0.35))
    ctx.addPath(roundedRect(body, 185))
    ctx.setFillColor(color(0x1B1E24))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(roundedRect(body, 185))
    ctx.clip()
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [color(0x353A44), color(0x15171B)] as CFArray,
                        locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
    ctx.restoreGState()

    // Terminal window.
    let term = CGRect(x: 170, y: 220, width: 600, height: 520)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 24, color: color(0x000000, 0.45))
    ctx.addPath(roundedRect(term, 44))
    ctx.setFillColor(color(0x0D0F12))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(roundedRect(term, 44))
    ctx.clip()
    ctx.setFillColor(color(0x2A2E36))
    ctx.fill(CGRect(x: term.minX, y: term.minY, width: term.width, height: 76))
    ctx.restoreGState()

    for (i, hex) in [UInt32(0xFF5F57), 0xFEBC2E, 0x28C840].enumerated() {
        ctx.setFillColor(color(hex))
        ctx.fillEllipse(in: CGRect(x: term.minX + 40 + CGFloat(i) * 52, y: term.minY + 22, width: 32, height: 32))
    }

    ctx.addPath(roundedRect(term, 44))
    ctx.setStrokeColor(color(0xFFFFFF, 0.12))
    ctx.setLineWidth(4)
    ctx.strokePath()

    // ">_" prompt, drawn as strokes so it stays crisp at every size.
    let green = color(0x4ADE80)
    ctx.setStrokeColor(green)
    ctx.setLineWidth(46)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: 245, y: 330))
    ctx.addLine(to: CGPoint(x: 350, y: 415))
    ctx.addLine(to: CGPoint(x: 245, y: 500))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: 395, y: 500))
    ctx.addLine(to: CGPoint(x: 465, y: 500))
    ctx.strokePath()

    // Context menu in front.
    let menu = CGRect(x: 500, y: 470, width: 360, height: 380)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 14), blur: 30, color: color(0x000000, 0.5))
    ctx.addPath(roundedRect(menu, 34))
    ctx.setFillColor(color(0xF4F5F7))
    ctx.fillPath()
    ctx.restoreGState()

    let rowH: CGFloat = 76
    let top = menu.minY + 38
    for row in 0..<4 {
        let y = top + CGFloat(row) * rowH
        if row == 2 {
            ctx.addPath(roundedRect(CGRect(x: menu.minX + 18, y: y - 8, width: menu.width - 36, height: rowH - 8), 18))
            ctx.setFillColor(color(0x3B82F6))
            ctx.fillPath()
            // Mini prompt marking the "New iTerm2 … Here" item.
            ctx.setStrokeColor(color(0xFFFFFF))
            ctx.setLineWidth(12)
            ctx.move(to: CGPoint(x: menu.minX + 46, y: y + 10))
            ctx.addLine(to: CGPoint(x: menu.minX + 72, y: y + 30))
            ctx.addLine(to: CGPoint(x: menu.minX + 46, y: y + 50))
            ctx.strokePath()
            ctx.setFillColor(color(0xFFFFFF))
            ctx.addPath(roundedRect(CGRect(x: menu.minX + 100, y: y + 22, width: 200, height: 16), 8))
            ctx.fillPath()
        } else {
            ctx.setFillColor(color(0x9CA3AF))
            let w: CGFloat = [230, 180, 0, 210][row]
            ctx.addPath(roundedRect(CGRect(x: menu.minX + 46, y: y + 22, width: w, height: 16), 8))
            ctx.fillPath()
        }
    }
}

func png(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    let s = CGFloat(size) / 1024
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: s, y: -s)
    ctx.interpolationQuality = .high
    draw(ctx)
    return rep.representation(using: .png, properties: [:])!
}

var images: [[String: String]] = []
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let name = "icon_\(base)x\(base)\(scale == 2 ? "@2x" : "").png"
        try png(size: px).write(to: outDir.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(base)x\(base)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outDir.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icons to \(outDir.path)")
