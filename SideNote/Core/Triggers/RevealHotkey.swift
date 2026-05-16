import Foundation
import HotKey

/// 呼出侧边栏的全局快捷键——单一真相 + 持久化。
///
/// 用 `HotKey` 库自带的 `KeyCombo.dictionary` / `init?(dictionary:)` 存到
/// UserDefaults（carbon keyCode + modifiers，跨键盘布局稳定）。改动后 post
/// `didChange`，`HotkeyService` 监听同一通知热重绑——无需重启 App。
enum RevealHotkey {

    static let defaultsKey = "revealHotkey"
    static let didChange = Notification.Name("sn.revealHotkeyDidChange")

    /// v1 出厂默认：⌃⇧Space。
    static var `default`: KeyCombo { KeyCombo(key: .space, modifiers: [.control, .shift]) }

    static func load() -> KeyCombo {
        if let dict = UserDefaults.standard.dictionary(forKey: defaultsKey),
           let combo = KeyCombo(dictionary: dict) {
            return combo
        }
        return `default`
    }

    static func save(_ combo: KeyCombo) {
        UserDefaults.standard.set(combo.dictionary, forKey: defaultsKey)
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    static func reset() { save(`default`) }

    /// "⌃⇧Space" 这种给 UI 展示的字符串（库的 KeyCombo.description）。
    static var displayString: String { load().description }
}
