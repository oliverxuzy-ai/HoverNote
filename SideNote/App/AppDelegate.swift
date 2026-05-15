import AppKit
import SwiftUI

/// 应用启动后的非 SwiftUI 生命周期 + NSPanel 管理。
///
/// M0 阶段：
/// - 启动后无可见窗口（菜单栏 App，LSUIElement = true）
/// - 点击菜单栏 → toggleSidebar() → 显示/隐藏一个静态侧边栏面板
/// - 面板暂用普通 show/hide，无动画
///
/// M1 阶段会改：
/// - NSPanel 替换为带滑入动画的实现（slideIn / slideOut）
/// - NSVisualEffectView 实现 vibrancy
/// - 添加全局热键（HotKey）和边缘悬停（CGEventTap）触发
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var sidebarPanel: NSPanel?
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement App 默认不激活；这里仅用于打印 M0 启动确认。
        NSLog("[side-note] M0 launched. Click menu bar icon to toggle the sidebar.")
    }

    // MARK: - Sidebar panel

    func toggleSidebar() {
        if let panel = sidebarPanel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            showSidebar()
        }
    }

    private func showSidebar() {
        if sidebarPanel == nil {
            sidebarPanel = makeSidebarPanel()
        }
        guard let panel = sidebarPanel else { return }
        positionAtRightEdge(panel: panel)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makeSidebarPanel() -> NSPanel {
        let hosting = NSHostingController(rootView: SidebarPanelView())
        hosting.view.frame = NSRect(x: 0, y: 0, width: 380, height: 720)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 720),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hosting
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hidesOnDeactivate = false
        return panel
    }

    private func positionAtRightEdge(panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let panelSize = panel.frame.size
        let x = frame.maxX - panelSize.width - 20  // 20pt from right edge
        let y = frame.midY - (panelSize.height / 2)
        panel.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height),
                       display: false)
    }

    // MARK: - About

    func openAbout() {
        if let win = aboutWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hosting = NSHostingController(rootView: AboutView())
        let win = NSWindow(contentViewController: hosting)
        win.title = "About side-note"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 360, height: 240))
        win.center()
        win.isReleasedWhenClosed = false
        aboutWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - About view (minimal)

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("side-note")
                .font(.system(size: 28, weight: .regular, design: .serif))
            Text("v0.1.0 — M0 scaffolding")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text("A Mac sidebar Markdown notebook that slides in from screen edge.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 28)
        .frame(width: 360, height: 240)
    }
}
