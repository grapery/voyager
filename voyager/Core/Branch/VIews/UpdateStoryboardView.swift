//
//  EditStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/15.
//

import SwiftUI

struct EditStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var storyId: Int64
    @Binding var boardId: Int64
    @State var isRendering: Bool = false
    @State var isGenImages: Bool = false
    @State var isGenVideo: Bool = false
    @Binding var viewModel: StoryViewModel

    
    var body: some View {
        VStack {
            Text("Edit StoryBoard")
                .font(.largeTitle)
                .padding()
            
            // 这里添加编辑 StoryBoard 的相关控件
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}
