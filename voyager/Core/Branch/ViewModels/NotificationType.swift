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
        case .success: return Color.theme.success
        case .error: return Color.theme.error
        case .warning: return Color.theme.warning
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.theme.success.opacity(0.3)
        case .error: return Color.theme.error.opacity(0.3)
        case .warning: return Color.theme.warning.opacity(0.3)
        }
    }
}
