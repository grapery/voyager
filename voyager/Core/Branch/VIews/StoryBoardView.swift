//
//  StoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine

struct StoryBoardView: View {
    @State var board: StoryBoard?
    @State var userId: Int64
    @State var groupId: Int64
    @State var storyId: Int64
    @Environment(\.presentationMode) var presentationMode
    @State var AiGenFinStage: Int = 0
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(board?.boardInfo.title ?? "无标题故事章节")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(board?.boardInfo.content ?? "")
                        .font(.body)
                    
                    if let createdAt = board?.boardInfo.ctime {
                        Text("创建于: \(formatDate(timestamp: createdAt))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Add more details and interactions as needed
                }
                .padding()
            }
            .navigationBarTitle("章节详情", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
}
