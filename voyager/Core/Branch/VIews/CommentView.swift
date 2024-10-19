//
//  StoryDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/6.
//

import SwiftUI
import Kingfisher


struct CommentView: View {
    let storyId: Int64
    let boardId: Int64
    let userId: Int64
    @Binding var viewModel: StoryViewModel

    var body: some View {
        // 实现评论视图的内容
        Text("Comments")
        // ... 其他评论相关的 UI 元素 ...
    }
}
