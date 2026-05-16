import AppKit
import ApplicationServices

/// 第三种唤出方式：鼠标贴住屏幕右边缘停留一下 → 面板滑入。
///
/// **为什么 M3 才做**：CGEventTap 监听全局鼠标位置需要 Accessibility 权限，
/// 首启动权限引导是一段 UX，不该污染 M1/M2 的核心验证。默认**关闭**，
/// 用户在 Preferences 主动开启时才请求权限（DESIGN.md / PLAN.md 约定）。
///
/// 行为：光标 x ≥ 屏幕右沿 −2pt 且在右沿停留 ≥ dwell（250ms）→ 触发。
/// 面板已开 / 已触发未离开边缘 → 不重复触发（离开边缘才 re-arm）。
final class EdgeHoverService {

    private let onTrigger: () -> Void
    private var isPresented: () -> Bool

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var dwellWorkItem: DispatchWorkItem?
    private var armed = true

    /// 贴边判定阈值 / 停留时长。
    private let edgeThreshold: CGFloat = 2
    private let dwell: TimeInterval = 0.25

    init(isPresented: @escaping () -> Bool, onTrigger: @escaping () -> Void) {
        self.isPresented = isPresented
        self.onTrigger = onTrigger
    }

    deinit { stop() }

    // MARK: - Permission

    /// 是否已拿到 Accessibility 信任（不弹窗，纯查询）。
    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    /// 请求 Accessibility 权限（弹系统授权框）。返回当前是否已信任。
    @discardableResult
    static func requestAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// 深链到 系统设置 → 隐私与安全性 → 辅助功能。
    static func openAccessibilitySettings() {
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Lifecycle

    /// 开启监听。未授权则静默不启动（调用方负责引导授权）。
    func start() {
        guard eventTap == nil, Self.hasAccessibility else { return }

        let mask = (1 << CGEventType.mouseMoved.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let svc = Unmanaged<EdgeHoverService>.fromOpaque(refcon).takeUnretainedValue()
            if type == .mouseMoved {
                svc.handle(location: event.location)
            } else if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = svc.eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.eventTap = tap
        self.runLoopSource = source
    }

    func stop() {
        dwellWorkItem?.cancel()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    var isRunning: Bool { eventTap != nil }

    // MARK: - Edge detection

    /// CGEvent.location 是「翻转」坐标（原点左上）。只关心 x，直接用。
    private func handle(location: CGPoint) {
        guard let screen = screenContaining(x: location.x) else { return }
        let rightEdge = screen.frame.maxX

        let atEdge = location.x >= rightEdge - edgeThreshold

        if atEdge {
            guard armed, !isPresented() else { return }
            if dwellWorkItem != nil { return }  // 已在计时
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.dwellWorkItem = nil
                guard self.armed, !self.isPresented() else { return }
                self.armed = false              // 触发后上锁，离开边缘才解锁
                self.onTrigger()
            }
            dwellWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + dwell, execute: work)
        } else {
            // 离开边缘：取消计时 + re-arm
            dwellWorkItem?.cancel()
            dwellWorkItem = nil
            armed = true
        }
    }

    private func screenContaining(x: CGFloat) -> NSScreen? {
        NSScreen.screens.first { x >= $0.frame.minX && x <= $0.frame.maxX } ?? NSScreen.main
    }
}
