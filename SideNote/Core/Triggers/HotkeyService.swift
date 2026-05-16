import AppKit
import HotKey

/// 全局热键注册器。组合从 `RevealHotkey` 读取（用户可在 Preferences 改），
/// 监听 `RevealHotkey.didChange` 通知热重绑——改快捷键无需重启 App。
///
/// 用 `soffes/HotKey` 包装 Carbon 的 RegisterEventHotKey。它在 macOS 14 上仍工作良好，
/// 是 menubar / 全局工具类应用的标准选择。
///
/// 注意：全局热键**不需要** Accessibility 权限——和 CGEventTap 不同。
final class HotkeyService {

    private var hotKey: HotKey?
    private let onTrigger: () -> Void
    private var observer: NSObjectProtocol?

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: RevealHotkey.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        hotKey = nil
    }

    /// 销毁旧绑定 → 按当前配置重新注册。配置损坏时回退默认，保证永远有快捷键可用。
    private func reload() {
        hotKey = nil
        let combo = RevealHotkey.load()
        let hk = HotKey(keyCombo: combo)
        hk.keyDownHandler = { [weak self] in
            self?.onTrigger()
        }
        self.hotKey = hk
    }
}
