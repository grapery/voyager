import SwiftUI

/// 通用输入栏组件，可用于聊天、提问等场景
struct CommonInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var placeholder: String
    var onSend: () -> Void
    @State private var isShowingMediaOptions = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                // 媒体按钮（可扩展）
                Button(action: {
                    withAnimation { isShowingMediaOptions.toggle() }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 32))
                        .foregroundColor(Color.theme.blur)
                }
                .frame(width: 32, height: 32)

                // 输入框
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color.theme.tertiaryText)
                            .padding(.leading, 6)
                    }
                    TextField("", text: $text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .focused(isFocused)
                        .frame(minHeight: 36, maxHeight: 44)
                }
                .frame(minHeight: 36, maxHeight: 44)

                // 发送按钮
                Button(action: onSend) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.theme.tertiaryText : Color.theme.blur)
                }
                .frame(width: 32, height: 32)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 4)
        }
    }
} 
