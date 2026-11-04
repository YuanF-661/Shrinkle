import SwiftUI
import AppKit

enum AspectOption: String, CaseIterable, Identifiable {
    case free = "Free", original = "Original", square = "1:1",
         r43 = "4:3", r34 = "3:4", r169 = "16:9", r916 = "9:16"
    var id: String { rawValue }

    /// 像素宽高比
    func ratio(original size: CGSize) -> CGFloat? {
        switch self {
        case .free: return nil
        case .original: return size.width / size.height
        case .square: return 1
        case .r43: return 4.0 / 3
        case .r34: return 3.0 / 4
        case .r169: return 16.0 / 9
        case .r916: return 9.0 / 16
        }
    }
}

private enum Corner: CaseIterable, Identifiable {
    case topLeft, topRight, bottomLeft, bottomRight
    var id: Self { self }
    var opposite: Corner {
        switch self {
        case .topLeft: return .bottomRight
        case .topRight: return .bottomLeft
        case .bottomLeft: return .topRight
        case .bottomRight: return .topLeft
        }
    }
    func point(in r: CGRect) -> CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: r.minX, y: r.minY)
        case .topRight: return CGPoint(x: r.maxX, y: r.minY)
        case .bottomLeft: return CGPoint(x: r.minX, y: r.maxY)
        case .bottomRight: return CGPoint(x: r.maxX, y: r.maxY)
        }
    }
}

struct CropView: View {
    let item: ImageItem
    let onDone: (CGRect?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rect: CGRect           // 归一化坐标 0...1
    @State private var dragStart: CGRect?
    @State private var aspect: AspectOption = .free
    @State private var image: NSImage?

    private static let full = CGRect(x: 0, y: 0, width: 1, height: 1)

    init(item: ImageItem, onDone: @escaping (CGRect?) -> Void) {
        self.item = item
        self.onDone = onDone
        _rect = State(initialValue: item.crop ?? Self.full)
    }

    /// 归一化坐标下的宽高比
    private var normalizedK: CGFloat? {
        aspect.ratio(original: item.pixelSize).map { $0 * item.pixelSize.height / item.pixelSize.width }
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let fit = fitted(container: geo.size, image: item.pixelSize)
                let r = CGRect(x: fit.minX + rect.minX * fit.width, y: fit.minY + rect.minY * fit.height,
                               width: rect.width * fit.width, height: rect.height * fit.height)
                ZStack {
                    Group {
                        if let image {
                            Image(nsImage: image).resizable().interpolation(.high)
                        } else if let t = item.thumbnail {
                            Image(nsImage: t).resizable()
                        }
                    }
                    .frame(width: fit.width, height: fit.height)
                    .position(x: fit.midX, y: fit.midY)

                    // 裁剪框外变暗
                    Path { p in p.addRect(fit); p.addRect(r) }
                        .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
                        .allowsHitTesting(false)

                    // 三分线
                    Path { p in
                        for i in 1...2 {
                            let x = r.minX + r.width * CGFloat(i) / 3
                            let y = r.minY + r.height * CGFloat(i) / 3
                            p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY))
                            p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.45), lineWidth: 0.8)
                    .allowsHitTesting(false)

                    // 拖动整体
                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 1.5)
                        .background(Color.white.opacity(0.001))
                        .frame(width: max(r.width, 1), height: max(r.height, 1))
                        .position(x: r.midX, y: r.midY)
                        .gesture(moveGesture(fit: fit))
                        .onHover { inside in inside ? NSCursor.openHand.push() : NSCursor.pop() }

                    // 四角拖拽
                    ForEach(Corner.allCases) { c in
                        let pt = c.point(in: r)
                        ZStack {
                            Color.white.opacity(0.001).frame(width: 30, height: 30)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .shadow(color: .black.opacity(0.4), radius: 2)
                        }
                        .position(pt)
                        .gesture(resizeGesture(corner: c, fit: fit))
                    }
                }
            }
            .background(Color.black.opacity(0.85))

            HStack(spacing: 14) {
                Picker("Aspect", selection: $aspect) {
                    ForEach(AspectOption.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 380)

                Text("\(Int(rect.width * item.pixelSize.width)) × \(Int(rect.height * item.pixelSize.height))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .font(.callout)

                Spacer()

                Button("Reset") { aspect = .free; rect = Self.full }
                    .help("Remove the crop and use the whole photo")
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Done") {
                    onDone(isFull(rect) ? nil : rect)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(minWidth: 760, idealWidth: 900, minHeight: 580, idealHeight: 680)
        .onChange(of: aspect) { _ in applyAspect() }
        .task {
            let url = item.url
            let loaded = await Task.detached(priority: .userInitiated) {
                Compressor.loadOriented(url: url, maxPixel: 2000)
            }.value
            if let loaded { image = NSImage(cgImage: loaded, size: .zero) }
        }
    }

    // MARK: - 几何

    private func fitted(container: CGSize, image: CGSize) -> CGRect {
        let pad: CGFloat = 24
        let cw = max(container.width - pad * 2, 10), ch = max(container.height - pad * 2, 10)
        let s = min(cw / image.width, ch / image.height)
        let w = image.width * s, h = image.height * s
        return CGRect(x: (container.width - w) / 2, y: (container.height - h) / 2, width: w, height: h)
    }

    private func isFull(_ r: CGRect) -> Bool {
        r.minX < 0.002 && r.minY < 0.002 && r.maxX > 0.998 && r.maxY > 0.998
    }

    private func applyAspect() {
        guard let k = normalizedK else { return }
        // 以当前裁剪框中心为基准，取该比例下尽可能大的框
        var w: CGFloat = 1, h: CGFloat = 1
        if k < 1 { w = k } else { h = 1 / k }
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let x = min(max(c.x - w / 2, 0), 1 - w)
        let y = min(max(c.y - h / 2, 0), 1 - h)
        rect = CGRect(x: x, y: y, width: w, height: h)
    }

    private func moveGesture(fit: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if dragStart == nil { dragStart = rect }
                guard let s = dragStart else { return }
                let x = min(max(s.minX + v.translation.width / fit.width, 0), 1 - s.width)
                let y = min(max(s.minY + v.translation.height / fit.height, 0), 1 - s.height)
                rect = CGRect(x: x, y: y, width: s.width, height: s.height)
            }
            .onEnded { _ in dragStart = nil }
    }

    private func resizeGesture(corner: Corner, fit: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if dragStart == nil { dragStart = rect }
                guard let s = dragStart else { return }
                let anchor = corner.opposite.point(in: s)
                var p = corner.point(in: s)
                p.x = min(max(p.x + v.translation.width / fit.width, 0), 1)
                p.y = min(max(p.y + v.translation.height / fit.height, 0), 1)
                rect = Self.makeRect(anchor: anchor, toward: p, k: normalizedK)
            }
            .onEnded { _ in dragStart = nil }
    }

    private static func makeRect(anchor a: CGPoint, toward p: CGPoint, k: CGFloat?) -> CGRect {
        let minSize: CGFloat = 0.04
        let sx: CGFloat = p.x >= a.x ? 1 : -1
        let sy: CGFloat = p.y >= a.y ? 1 : -1
        var w = max(abs(p.x - a.x), minSize)
        var h = max(abs(p.y - a.y), minSize)
        if let k {
            if w / h > k { w = h * k } else { h = w / k }
        }
        let maxW = sx > 0 ? 1 - a.x : a.x
        let maxH = sy > 0 ? 1 - a.y : a.y
        if w > maxW { w = maxW; if let k { h = w / k } }
        if h > maxH { h = maxH; if let k { w = h * k } }
        let x = sx > 0 ? a.x : a.x - w
        let y = sy > 0 ? a.y : a.y - h
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
