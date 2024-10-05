//
//  StoryView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine

struct StoryView: View {
    @State var viewModel: StoryViewModel
    @State private var isEditing: Bool = false
    @State public var storyId: Int64
    var userId: Int64
    init(storyId: Int64,userId:Int64) {
        self.storyId = storyId
        self.userId = userId
        self.viewModel = StoryViewModel(storyId: storyId,userId:userId)
    }
    
    var body: some View {
        VStack{
            HStack{
                KFImage(URL(string: (self.viewModel.story?.storyInfo.avatar)!))
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
                
                Text((self.viewModel.story?.storyInfo.name)!)
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .blur(radius: CGFloat(0.5))
            Spacer()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        storyContent(self.viewModel.story!)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Story Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task{
                            await viewModel.updateStory()
                        }
                    }
                    isEditing.toggle()
                }
            }
        }
        .onAppear {
            Task{
                await viewModel.fetchStory(withBoards: true)
            }
        }
    }
    
    @ViewBuilder
    private func storyContent(_ story: Story) -> some View {
        VStack(spacing: 16) {
            // 其他 story 内容...
            
            if let boards = viewModel.storyboards {
                ForEach(boards, id: \.id) { board in
                    StoryBoardCellView(board: board, userId: userId, groupId: story.storyInfo.groupID, storyId: storyId)
                }
            }
        }
    }
}

struct StoryBoardCellView: View {
    var board: StoryBoard?
    var userId: Int64
    var groupId: Int64
    var storyId: Int64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(board?.boardInfo.title ?? "无标题故事章节")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let description = board?.boardInfo.content, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let createdAt = board?.boardInfo.ctime {
                Text("创建于 : \(formatDate(timestamp: createdAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}



