import SwiftUI
import AppKit

/// DESIGN.md 字号梯度的唯一出处。
///
/// 三族字体（M3 加载，运行时由 `FontRegistration` 注册进进程）：
/// - Display：PP Editorial New（标题 / H1-H3 / 斜体强调）
/// - Body：General Sans（UI + 正文 + 列表）
/// - Mono：JetBrains Mono（代码块 / 行内 code）
///
/// **优雅回退**：某个家族没打包成功（例如 PP Editorial New 需手动从
/// pangrampangram.com 取，可能暂缺）→ 自动回退到对应系统字形
/// （display→serif New York / sans→系统 / mono→系统等宽），永不空白、不崩。
/// 字号 / 行距 / 字重严格照 DESIGN.md，与回退与否无关。
enum Typography {

    // MARK: - Family availability (注册后查一次)

    private static func has(_ psName: String) -> Bool {
        NSFont(name: psName, size: 12) != nil
    }

    private static let displayRegularPS = ["PPEditorialNew-Regular", "PPEditorialNew-Ultralight"]
        .first(where: has)
    private static let displayItalicPS = ["PPEditorialNew-Italic", "PPEditorialNew-RegularItalic"]
        .first(where: has)
    private static let hasSans = has("GeneralSans-Regular")
    private static let hasMono = has("JetBrainsMono-Regular")

    // MARK: - Builders

    private static func display(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        if let ps = displayRegularPS { return .custom(ps, fixedSize: size) }
        return .system(size: size, weight: weight, design: .serif)
    }

    /// 斜体强调：DESIGN.md 唯一刻意的 cross-family fallthrough（切到 PP Editorial New Italic）。
    static func displayItalic(_ size: CGFloat) -> Font {
        if let ps = displayItalicPS { return .custom(ps, fixedSize: size) }
        return .system(size: size, weight: .regular, design: .serif).italic()
    }

    private static func sans(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        guard hasSans else { return .system(size: size, weight: weight) }
        let ps: String
        switch weight {
        case .semibold, .bold: ps = "GeneralSans-Semibold"
        case .medium:          ps = "GeneralSans-Medium"
        default:               ps = "GeneralSans-Regular"
        }
        return .custom(ps, fixedSize: size)
    }

    /// 行内粗体：DESIGN.md = General Sans Semibold（600）。
    static func bold(_ size: CGFloat) -> Font { sans(size, .semibold) }

    private static func mono(_ size: CGFloat) -> Font {
        guard hasMono else { return .system(size: size, weight: .regular, design: .monospaced) }
        return .custom("JetBrainsMono-Regular", fixedSize: size)
    }

    // MARK: - Display (PP Editorial New)

    static let h1 = display(28, .regular)
    static let h2 = display(21, .regular)
    static let h3 = display(17, .medium)

    // MARK: - Body (General Sans)

    static let body       = sans(15, .regular)
    static let bodyBold   = sans(15, .semibold)
    static let listItem   = sans(13, .regular)
    static let button     = sans(13, .medium)
    static let meta       = sans(11, .regular)

    // MARK: - Mono (JetBrains Mono)

    static let codeBlock  = mono(13.5)
    static let inlineCode = mono(13)

    // MARK: - Leading helpers

    /// DESIGN.md 用 line-height 倍数；SwiftUI `.lineSpacing` 是「行间额外点数」。
    /// 换算：额外点数 ≈ fontSize × (multiple − 1)。
    static func lineSpacing(fontSize: CGFloat, multiple: CGFloat) -> CGFloat {
        max(0, fontSize * (multiple - 1))
    }

    static let bodyLineSpacing      = lineSpacing(fontSize: 15,   multiple: 1.55)
    static let listLineSpacing      = lineSpacing(fontSize: 13,   multiple: 1.45)
    static let codeBlockLineSpacing = lineSpacing(fontSize: 13.5, multiple: 1.5)
}
