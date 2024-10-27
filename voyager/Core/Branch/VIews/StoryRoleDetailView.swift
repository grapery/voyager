//
//  StoryRoleDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher



// 角色详情视图
struct StoryRoleDetailView: View {
    let storyId: Int64
    let boardIds: [Int64]
    let roleId: Int64
    @Binding var viewModel: StoryDetailViewModel
    
    var body: some View {
        Text("")
    }
}

// 角色简介视图
struct StoryRoleCellView: View {
    let storyId: Int64
    let boardIds: [Int64]
    let roleId: Int64
    @Binding var viewModel: StoryDetailViewModel
    
    var body: some View {
        Text("")
    }
}
