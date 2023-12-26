//
//  ThreadFilterViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

enum LeafFilterViewModel: Int, CaseIterable {
    case leaves
    case replies
    
    var title: String {
        switch self {
        case .leaves: return "Leaves"
        case .replies: return "Replies"
        }
    }
}
