import Foundation

import SwiftUI

struct TimelineButton: View {
    let title: String
    let icon: String
    var isCompleted: Bool
    var isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isActive ? .bold : .regular))
                    .foregroundColor(iconColor)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isActive)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isActive ? .medium : .regular)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.blue.opacity(0.1) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            )
        }
    }
    
    private var iconColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var textColor: Color {
        if isActive {
            return .primary
        } else {
            return .gray
        }
    }
}

// Timeline Step Enum
enum TimelineStep: CaseIterable {
    case write
    case complete
    case draw
    case narrate
    
    var title: String {
        switch self {
        case .write: return "续写"
        case .complete: return "创建"
        case .draw: return "绘画"
        case .narrate: return "发布"
        }
    }
    
    var icon: String {
        switch self {
        case .write: return "pencil.circle"
        case .complete: return "checkmark.circle"
        case .draw: return "paintbrush.fill"
        case .narrate: return "text.bubble"
        }
    }
    
    func isCompleted(
        isInputCompleted: Bool,
        isStoryGenerated: Bool,
        isImageGenerated: Bool,
        isNarrationCompleted: Bool
    ) -> Bool {
        switch self {
        case .write: return isInputCompleted
        case .complete: return isStoryGenerated
        case .draw: return isImageGenerated
        case .narrate: return isNarrationCompleted
        }
    }
    
    func color(
        isInputCompleted: Bool,
        isStoryGenerated: Bool,
        isImageGenerated: Bool,
        isNarrationCompleted: Bool
    ) -> Color {
        let completed = isCompleted(
            isInputCompleted: isInputCompleted,
            isStoryGenerated: isStoryGenerated,
            isImageGenerated: isImageGenerated,
            isNarrationCompleted: isNarrationCompleted
        )
        return completed ? Color.green.opacity(0.6) : Color.red.opacity(0.6)
    }
}
