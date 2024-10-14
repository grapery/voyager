//
//  ThreadFilterViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

enum UserProfileFilterViewModel: Int, CaseIterable {
    case storyitems
    case groups
    case projects
    
    var title: String {
        switch self {
        case .storyitems: return "故事线"
        case .groups: return "加入的组织"
        case .projects: return "参与的活动"
        }
    }
}
