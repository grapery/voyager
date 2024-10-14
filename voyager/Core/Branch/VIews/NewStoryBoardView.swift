//
//  NewStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI

struct NewStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    
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

