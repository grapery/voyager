//
//  NewStoryRole.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher

// 创建角色视图
struct NewStoryRole: View {
    let storyId: Int64
    let boardId: Int64
    let userId: Int64
    @Binding var viewModel: StoryDetailViewModel
    
    var body: some View {
        Text("新的角色")
    }
}
