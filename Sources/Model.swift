import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ItemStatus: Equatable {
    case pending
    case working
    case done(bytes: Int)
    case failed(String)
}

struct ImageItem: Identifiable {
    let id = UUID()
    let url: URL
    let bytes: Int
    let pixelSize: CGSize      // 已按方向修正
    let thumbnail: NSImage?
    var crop: CGRect? = nil    // 归一化坐标
    var status: ItemStatus = .pending
    var outputURL: URL? = nil

    var name: String { url.lastPathComponent }

    static func load(_ url: URL) -> ImageItem? {
        guard let size = Compressor.orientedPixelSize(url: url) else { return nil }
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let thumb = Compressor.loadOriented(url: url, maxPixel: 160).map { NSImage(cgImage: $0, size: .zero) }
        return ImageItem(url: url, bytes: bytes, pixelSize: size, thumbnail: thumb)
    }
}

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var items: [ImageItem] = []
    @Published var percent: Double {
        didSet { UserDefaults.standard.set(percent, forKey: "percent") }
    }
    @Published var outputDir: URL? = nil   // nil = 保存到原图所在文件夹
    @Published var isRunning = false

    init() {
        let p = UserDefaults.standard.double(forKey: "percent")
        percent = p > 0 ? p : 20
    }

    var doneCount: Int { items.filter { if case .done = $0.status { return true }; return false }.count }

    var savedBytes: Int {
        items.reduce(0) { sum, it in
            if case .done(let b) = it.status { return sum + max(0, it.bytes - b) }
            return sum
        }
    }

    // MARK: - 添加 / 移除

    func add(_ urls: [URL]) {
        Task.detached(priority: .userInitiated) {
            let files = AppModel.expand(urls)
            let loaded = files.compactMap { ImageItem.load($0) }
            await MainActor.run {
                let existing = Set(self.items.map { $0.url.standardizedFileURL })
                self.items += loaded.filter { !existing.contains($0.url.standardizedFileURL) }
            }
        }
    }

    nonisolated static func expand(_ urls: [URL]) -> [URL] {
        var result: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                if let all = fm.enumerator(at: url, includingPropertiesForKeys: [.contentTypeKey],
                                           options: [.skipsHiddenFiles, .skipsPackageDescendants])?.allObjects as? [URL] {
                    result += all.filter(isImage).sorted { $0.path < $1.path }
                }
            } else if isImage(url) {
                result.append(url)
            }
        }
        // 跳过本程序自己生成的文件
        return result.filter { !$0.deletingPathExtension().lastPathComponent.contains("_compressed") }
    }

    nonisolated static func isImage(_ url: URL) -> Bool {
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)
            ?? UTType(filenameExtension: url.pathExtension)
        return type?.conforms(to: .image) ?? false
    }

    func handleDrop(_ providers: [NSItemProvider]) {
        for p in providers {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                if let url { Task { @MainActor in self.add([url]) } }
            }
        }
    }

    func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.image]
        panel.message = "Choose photos (folders work too)"
        if panel.runModal() == .OK { add(panel.urls) }
    }

    func chooseOutputDir() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Save Here"
        if panel.runModal() == .OK { outputDir = panel.url }
    }

    func remove(_ id: UUID) { items.removeAll { $0.id == id } }

    func clear() { items.removeAll() }

    func setCrop(_ id: UUID, _ rect: CGRect?) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].crop = rect
        items[i].status = .pending
    }

    func reveal(_ urls: [URL]) {
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func revealAll() {
        reveal(items.compactMap { if case .done = $0.status { return $0.outputURL }; return nil })
    }

    // MARK: - 压缩

    func compressAll() {
        guard !isRunning, !items.isEmpty else { return }
        isRunning = true
        let jobs = items.map {
            CompressJob(id: $0.id, url: $0.url, originalBytes: $0.bytes, crop: $0.crop, previousOutput: $0.outputURL)
        }
        for i in items.indices { items[i].status = .working }
        let fraction = percent / 100
        let outDir = outputDir
        let limit = max(2, ProcessInfo.processInfo.activeProcessorCount / 2)

        Task {
            await withTaskGroup(of: (UUID, Result<CompressOutput, Error>).self) { group in
                var next = 0
                func enqueue() {
                    guard next < jobs.count else { return }
                    let job = jobs[next]
                    next += 1
                    group.addTask {
                        (job.id, Result { try Compressor.compress(job, fraction: fraction, outputDir: outDir) })
                    }
                }
                for _ in 0..<min(limit, jobs.count) { enqueue() }
                for await (id, result) in group {
                    if let i = self.items.firstIndex(where: { $0.id == id }) {
                        switch result {
                        case .success(let out):
                            self.items[i].outputURL = out.url
                            self.items[i].status = .done(bytes: out.bytes)
                        case .failure(let err):
                            self.items[i].status = .failed(err.localizedDescription)
                        }
                    }
                    enqueue()
                }
            }
            self.isRunning = false
        }
    }
}
