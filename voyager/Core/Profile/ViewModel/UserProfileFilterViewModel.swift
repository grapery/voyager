//
//  ThreadFilterViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

enum UserProfileFilterViewModel: Int, CaseIterable {
    case storys
    case groups
    case roles
    
    var title: String {
        switch self {
        case .storys: return "参与的故事"
        case .groups: return "加入的小组"
        case .roles: return  "联系的角色"
        }
    }
}
