// 生成 1024×1024 的 App 图标 PNG：swift scripts/make_icon.swift out.png
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let inset: CGFloat = 100
let body = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.70, alpha: 1),
           ending: NSColor(calibratedRed: 0.13, green: 0.42, blue: 0.95, alpha: 1))!
    .draw(in: path, angle: -60)

func symbol(_ name: String, _ pt: CGFloat, _ weight: NSFont.Weight, in rect: NSRect) {
    let cfg = NSImage.SymbolConfiguration(pointSize: pt, weight: weight)
        .applying(.init(paletteColors: [.white]))
    guard let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(cfg) else { return }
    let s = img.size
    let r = NSRect(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2, width: s.width, height: s.height)
    img.draw(in: r)
}
symbol("photo", 400, .regular, in: NSRect(x: 0, y: 60, width: size, height: size))
symbol("arrow.down.right.and.arrow.up.left", 150, .bold, in: NSRect(x: 0, y: -290, width: size, height: size))

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
