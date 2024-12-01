import Foundation

enum UserProfileFilterViewModel: Int, CaseIterable {
    case storyboards
    case roles
    
    var title: String {
        switch self {
        case .storyboards: return "故事板"
        case .roles: return "角色"
        }
    }
} 