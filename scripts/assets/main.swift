// Renders the app icon, logo and README images.
// Usage: scripts/render_assets.sh   (compiles this together with the app sources)
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let docs = root.appendingPathComponent("docs/assets")
let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("shrinkle-assets")

final class KeyWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
func snap<V: View>(_ view: V, _ size: CGSize, wait: Double = 0.4) async -> NSBitmapImageRep {
    let host = NSHostingView(rootView: view
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .light))
    let screen = NSScreen.main!.frame
    let win = KeyWindow(contentRect: NSRect(x: screen.minX + 40, y: screen.minY + 40, width: size.width, height: size.height),
                       styleMask: [.borderless], backing: .buffered, defer: false)
    win.isOpaque = false
    win.backgroundColor = .clear
    win.alphaValue = 0          // never visible on screen
    win.ignoresMouseEvents = true
    win.appearance = NSAppearance(named: .aqua)
    win.contentView = host
    win.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
    host.layoutSubtreeIfNeeded()
    host.display()
    let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
    host.cacheDisplay(in: host.bounds, to: rep)
    win.orderOut(nil)
    return rep
}

func image(_ rep: NSBitmapImageRep) -> NSImage {
    let img = NSImage(size: NSSize(width: CGFloat(rep.pixelsWide) / 2, height: CGFloat(rep.pixelsHigh) / 2))
    img.addRepresentation(rep)
    return img
}

func savePNG(_ rep: NSBitmapImageRep, _ url: URL) {
    try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("wrote \(url.lastPathComponent)  \(rep.pixelsWide)×\(rep.pixelsHigh)")
}

func saveHEIC(_ rep: NSBitmapImageRep, _ url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.heic.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, rep.cgImage!, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    CGImageDestinationFinalize(dest)
}

@MainActor
func renderAll() async {
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

    // App icon + README logo
    savePNG(await snap(AppIconView().frame(width: 1024, height: 1024).scaleEffect(0.5).frame(width: 512, height: 512), CGSize(width: 512, height: 512)),
            root.appendingPathComponent("Resources/AppIcon.png"))
    savePNG(await snap(LogoMark().padding(8), CGSize(width: 256, height: 256)), docs.appendingPathComponent("logo.png"))

    // Sample photos (generated artwork, written as HEIC like an iPhone would)
    let names = ["IMG_2041.HEIC", "IMG_2042.HEIC", "IMG_2057.HEIC", "IMG_2063.HEIC", "IMG_2071.HEIC"]
    let bytes = [4_812_330, 3_954_112, 5_206_871, 2_871_540, 4_120_998]
    let outBytes = [962_118, 790_402, 551_870, 574_006, 823_771]
    var items: [ImageItem] = []
    for (i, name) in names.enumerated() {
        let rep = await snap(SceneArt(kind: i), CGSize(width: 800, height: 600), wait: 0.1)
        let url = tmp.appendingPathComponent(name)
        saveHEIC(rep, url)
        let crop: CGRect? = i == 2 ? CGRect(x: 0.18, y: 0.1, width: 0.6, height: 0.62) : nil
        items.append(ImageItem(url: url, bytes: bytes[i], pixelSize: CGSize(width: 4032, height: 3024),
                               thumbnail: image(rep), crop: crop,
                               status: .done(bytes: outBytes[i]),
                               outputURL: url))
    }

    // Real app UI
    let model = AppModel.shared
    model.items = items
    model.percent = 20
    let main = image(await snap(ContentView().environmentObject(model).background(Color(nsColor: .windowBackgroundColor)), CGSize(width: 720, height: 440), wait: 0.8))

    var cropItem = items[0]
    cropItem.crop = CGRect(x: 0.2, y: 0.14, width: 0.58, height: 0.66)
    let crop = image(await snap(CropView(item: cropItem) { _ in }.background(Color(nsColor: .windowBackgroundColor)), CGSize(width: 820, height: 600), wait: 1.5))

    // Posters
    savePNG(await snap(HeroPoster(screenshot: main), CGSize(width: 1280, height: 680)), docs.appendingPathComponent("hero.png"))
    savePNG(await snap(BeforeAfterPoster(), CGSize(width: 1280, height: 720)), docs.appendingPathComponent("before-after.png"))
    savePNG(await snap(UploadPoster(), CGSize(width: 1280, height: 720)), docs.appendingPathComponent("too-large.png"))
    savePNG(await snap(CropPoster(screenshot: crop), CGSize(width: 1280, height: 720)), docs.appendingPathComponent("crop.png"))
    savePNG(await snap(SocialPoster(), CGSize(width: 1280, height: 640)), docs.appendingPathComponent("social-preview.png"))
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
Task { @MainActor in
    await renderAll()
    exit(0)
}
app.run()
