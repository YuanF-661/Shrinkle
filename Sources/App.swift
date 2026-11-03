import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// 支持把照片直接拖到 Dock 图标上 / 用“打开方式”打开
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in AppModel.shared.add(urls) }
    }
}

@main
struct ShrinkleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        Window("Shrinkle 缩一缩", id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .defaultSize(width: 760, height: 520)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("添加照片…") { model.openPanel() }
                    .keyboardShortcut("o")
            }
        }
    }
}
