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
    
    var title: String {
        switch self {
        case .storyitems: return "参与的故事"
        case .groups: return "加入的小组"
        }
    }
}
