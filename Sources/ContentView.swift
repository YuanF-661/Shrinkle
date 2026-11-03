import SwiftUI
import AppKit

func formatBytes(_ b: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(b), countStyle: .file)
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var dropTargeted = false
    @State private var cropping: ImageItem?

    var body: some View {
        VStack(spacing: 0) {
            if model.items.isEmpty {
                EmptyDropView(targeted: dropTargeted) { model.openPanel() }
            } else {
                List {
                    ForEach(model.items) { item in
                        ItemRow(item: item,
                                disabled: model.isRunning,
                                onCrop: { cropping = item },
                                onReveal: { if let u = item.outputURL { model.reveal([u]) } },
                                onRemove: { model.remove(item.id) })
                    }
                }
                .overlay {
                    if dropTargeted {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                            .padding(6)
                    }
                }
                if model.doneCount > 0 && !model.isRunning {
                    summaryBar
                }
            }
            Divider()
            bottomBar
        }
        .frame(minWidth: 640, minHeight: 440)
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            model.handleDrop(providers)
            return true
        }
        .sheet(item: $cropping) { item in
            CropView(item: item) { rect in model.setCrop(item.id, rect) }
        }
        .toolbar {
            if !model.items.isEmpty {
                ToolbarItemGroup {
                    Button { model.openPanel() } label: { Label("添加照片", systemImage: "plus") }
                        .help("添加照片")
                    Button { model.clear() } label: { Label("清空列表", systemImage: "trash") }
                        .help("清空列表（不会删除任何文件）")
                        .disabled(model.isRunning)
                }
            }
        }
    }

    private var summaryBar: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text("已完成 \(model.doneCount) 张，共节省 \(formatBytes(model.savedBytes))")
            Spacer()
            Button("在 Finder 中显示") { model.revealAll() }
                .buttonStyle(.link)
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.green.opacity(0.08))
    }

    private var bottomBar: some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Text("压缩到原大小的")
                Slider(value: $model.percent, in: 5...90, step: 1)
                    .frame(width: 150)
                Text("\(Int(model.percent))%")
                    .monospacedDigit()
                    .fontWeight(.semibold)
                    .frame(width: 40, alignment: .leading)
            }

            Text("输出 JPG")
                .font(.caption)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                .help("JPG 是兼容性最好的图片格式，HEIC / PNG 等都会转成 JPG")

            Menu {
                Button("原图所在文件夹") { model.outputDir = nil }
                Button("选择文件夹…") { model.chooseOutputDir() }
            } label: {
                Label(model.outputDir?.lastPathComponent ?? "原图所在文件夹", systemImage: "folder")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("压缩后的文件保存位置（不会覆盖原图）")

            Spacer()

            Button {
                model.compressAll()
            } label: {
                HStack(spacing: 6) {
                    if model.isRunning { ProgressView().controlSize(.small) }
                    Text(model.isRunning ? "压缩中…" : "开始压缩")
                }
                .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(model.items.isEmpty || model.isRunning)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct EmptyDropView: View {
    let targeted: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 14) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(targeted ? Color.accentColor : .secondary)
                Text("把照片拖到这里")
                    .font(.title2.weight(.medium))
                Text("或点击选择照片 / 文件夹 · 支持 HEIC、JPG、PNG 等")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(targeted ? Color.accentColor : Color.secondary.opacity(0.35),
                              style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .background(RoundedRectangle(cornerRadius: 16).fill(targeted ? Color.accentColor.opacity(0.06) : .clear))
        )
        .padding(24)
    }
}

struct ItemRow: View {
    let item: ImageItem
    let disabled: Bool
    let onCrop: () -> Void
    let onReveal: () -> Void
    let onRemove: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).lineLimit(1).truncationMode(.middle)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            status
            Button(action: onCrop) {
                Image(systemName: "crop")
                    .foregroundStyle(item.crop != nil ? Color.accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .help(item.crop != nil ? "修改裁剪" : "裁剪（可选）")
            .disabled(disabled)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
            }
            .buttonStyle(.borderless)
            .help("从列表移除")
            .opacity(hovering ? 1 : 0)
            .disabled(disabled)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(count: 2) { if !disabled { onCrop() } }
        .contextMenu {
            Button("裁剪…", action: onCrop).disabled(disabled)
            if item.outputURL != nil { Button("在 Finder 中显示", action: onReveal) }
            Divider()
            Button("从列表移除", action: onRemove).disabled(disabled)
        }
    }

    private var thumbnail: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let t = item.thumbnail {
                    Image(nsImage: t).resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if item.crop != nil {
                Image(systemName: "crop")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(3)
                    .background(Circle().fill(Color.accentColor))
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var detail: String {
        var s = "\(formatBytes(item.bytes)) · \(Int(item.pixelSize.width))×\(Int(item.pixelSize.height))"
        if let c = item.crop {
            s += " · 裁剪为 \(Int(c.width * item.pixelSize.width))×\(Int(c.height * item.pixelSize.height))"
        }
        return s
    }

    @ViewBuilder private var status: some View {
        switch item.status {
        case .pending:
            EmptyView()
        case .working:
            ProgressView().controlSize(.small)
        case .done(let b):
            Button(action: onReveal) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(formatBytes(b)).monospacedDigit()
                    if item.bytes > 0 {
                        Text("(\(Int((Double(b) / Double(item.bytes) * 100).rounded()))%)")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }
            .buttonStyle(.borderless)
            .help("在 Finder 中显示")
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }
}
