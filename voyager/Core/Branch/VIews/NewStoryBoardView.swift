//
//  NewStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI

struct NewStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var storyId: Int64
    @Binding var prevBoardId: Int64
    var isRendering: Bool = false
    var isGenImages: Bool = false
    var isGenVideo: Bool = false
    @Binding var viewModel: StoryViewModel
    
    var body: some View {
        VStack {
            Text("Create New StoryBoard")
                .font(.largeTitle)
                .padding()
            
            // 这里添加创建 StoryBoard 的相关控件
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}

