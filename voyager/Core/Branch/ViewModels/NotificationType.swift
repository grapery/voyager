import SwiftUI


// Notification type enum
enum NotificationType {
    case success
    case error
    case warning
    
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .yellow
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.3)
        case .error: return Color.red.opacity(0.3)
        case .warning: return Color.yellow.opacity(0.3)
        }
    }
}
