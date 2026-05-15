import SwiftUI

/// M0 placeholder · 主侧边栏面板的 SwiftUI 视图。
///
/// 这只是脚手架。展示：
/// - DESIGN.md 里 canvas 色 `#F1F2E9` 已落地（无 vibrancy，M1 加）
/// - PP Editorial New 字体未加载（M3 加），暂用系统衬线
/// - 一段"M0 工作正常"的提示文字
///
/// M1 会替换为：
/// - NSVisualEffectView 材质 + 92% canvas 色叠层
/// - 滑入 / 滑出动画（spring response 0.32, damping 0.78, 12pt content parallax）
/// - 全局热键 + 边缘悬停触发集成
struct SidebarPanelView: View {

    /// canvas 色 #F1F2E9（sage-tinted near-white）—— v1 light 主题主背景。
    /// M1 之后这一层会被 NSVisualEffectView + 92% 不透明 sage 叠层替换。
    private let canvas = Color(red: 0xF1 / 255.0, green: 0xF2 / 255.0, blue: 0xE9 / 255.0)

    /// 暖近黑文本主色 #1F1E18。
    private let textPrimary = Color(red: 0x1F / 255.0, green: 0x1E / 255.0, blue: 0x18 / 255.0)

    /// 次要文字 #75726A。
    private let textMuted = Color(red: 0x75 / 255.0, green: 0x72 / 255.0, blue: 0x6A / 255.0)

    /// Sage refined rosemary #6E8060 —— v1 唯一的 accent。
    private let accent = Color(red: 0x6E / 255.0, green: 0x80 / 255.0, blue: 0x60 / 255.0)

    var body: some View {
        ZStack {
            canvas

            VStack(spacing: 16) {
                Spacer()

                Text("side-note")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(textPrimary)

                Text("M0 · scaffolding works")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(accent)
                    .textCase(.uppercase)

                Text("Click the menu bar icon to toggle this panel.\nNext milestone (M1): the slide-in spike.")
                    .font(.system(size: 13))
                    .foregroundStyle(textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                Spacer()

                // Visual canary: a pinned-pin sketch using the sage accent.
                // In M3 this becomes the real ceramic pin shape. M0 just shows the color reads correctly.
                Circle()
                    .fill(accent)
                    .frame(width: 10, height: 10)
                    .padding(.bottom, 32)
            }
        }
        .frame(width: 380, height: 720)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("Sidebar · M0") {
    SidebarPanelView()
}
