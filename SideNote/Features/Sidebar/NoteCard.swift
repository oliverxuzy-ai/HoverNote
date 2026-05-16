import SwiftUI

/// 单条笔记卡片。Bear 风格版式（用户实测后按截图重做）：
/// 加粗大标题 → 多行灰色预览 → 底部 pin 图标(仅置顶时) + 时间戳。
/// 颜色全走 sage 系统；玻璃/选中/hover 仍照 DESIGN.md。
///
/// 不做图片缩略图：v1 是纯 Markdown 文本、无图片附件（DESIGN.md 图片推 v1.1）。
struct NoteCard: View {

    let note: NoteFile
    var selected: Bool = false

    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(note.displayTitle)
                .font(Typography.bold(16.5))
                .foregroundStyle(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .tracking(-0.1)

            if !note.preview.isEmpty {
                Text(note.preview)
                    .font(Typography.listItem)
                    .foregroundStyle(.textMuted)
                    .lineLimit(3)
                    .lineSpacing(3)
            }

            footer
                .padding(.top, 3)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
        .overlay(alignment: .leading) {
            if selected {
                Rectangle().fill(.sage).frame(width: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .shadow(color: .black.opacity(selected ? 0.07 : 0.04),
                radius: selected ? 2 : 1, y: 1)
        .onHover { hovering = $0 }
        .animation(.cardState, value: hovering)
        .animation(.cardState, value: selected)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if note.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.sage)
                    .rotationEffect(.degrees(-40))
            }
            Text(note.relativeTimestamp)
                .font(Typography.meta)
                .tracking(0.2)
                .foregroundStyle(.textFaint)
        }
    }

    private var cardBackground: Color {
        if selected { return .cardFillSelected }
        if hovering  { return .cardFillHover    }
        return .cardFill
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            .stroke(hovering ? .hairline.opacity(1.4) : .hairline,
                    lineWidth: BorderWidth.hairline)
    }
}
