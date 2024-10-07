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
    @State private var selectedTab = 0
    var userId: Int64
    
    init(storyId: Int64,userId:Int64) {
        self.storyId = storyId
        self.userId = userId
        self.viewModel = StoryViewModel(storyId: storyId,userId:userId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Story Info Header
            VStack(alignment: .leading, spacing: 8) {
                NavigationLink(destination: StoryDetailView(storyId: self.storyId,story: self.viewModel.story!)) {
                    HStack {
                        KFImage(URL(string: self.viewModel.story?.storyInfo.avatar ?? ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(self.viewModel.story?.storyInfo.name ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let createdAt = self.viewModel.story?.storyInfo.ctime {
                                Text("创建于: \(formatDate(timestamp: createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Text(self.viewModel.story?.storyInfo.origin ?? "")
                    .font(.subheadline)
                    .lineLimit(3)
                
                HStack {
                    Label("\(self.viewModel.story?.storyInfo.desc ?? "")", systemImage: "bubble.left")
                    Spacer()
                    Label("10", systemImage: "heart")
                    Spacer()
                    Label("1", systemImage: "bell")
                    Spacer()
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .padding()
            .background(Color.white)
            Spacer()
            StoryTabView(selectedTab:$selectedTab)
            Spacer()
            if self.selectedTab == 0 {
                // Storyboards ScrollView
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let boards = viewModel.storyboards {
                        LazyVStack {
                            ForEach(boards, id: \.id) { board in
                                StoryBoardCellView(board: board, userId: userId, groupId: self.viewModel.story?.storyInfo.groupID ?? 0, storyId: storyId)
                            }
                        }
                        .padding()
                    }
                }
            }else if self.selectedTab == 1 {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.storyboards!, id: \.id) { board in
                            StoryBoardCellView(board: board, userId: userId, groupId: self.viewModel.story?.storyInfo.groupID ?? 0, storyId: storyId)
                        }
                    }
                    .padding()
                }
            }
            
        }
        .navigationTitle("故事")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await viewModel.updateStory()
                        }
                    }
                    isEditing.toggle()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchStory(withBoards: true)
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
}

struct StoryBoardCellView: View {
    var board: StoryBoard?
    var userId: Int64
    var groupId: Int64
    var storyId: Int64
    @State private var isShowingBoardDetail = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
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
        .onTapGesture {
            isShowingBoardDetail = true
            print("Tapped on board: \(String(describing: board))")
        }
        .fullScreenCover(isPresented: $isShowingBoardDetail) {
            StoryBoardView(board: board, userId: userId, groupId: groupId, storyId: storyId)
        }
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

struct StoryTabView: View {
    @Binding var selectedTab: Int
    let tabs = ["故事线", "故事生成"]
    
    var body: some View {
        HStack {
            Spacer().padding(.horizontal, 2)
            ForEach(0..<2) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tabs[index])
                        .foregroundColor(selectedTab == index ? .black : .gray)
                        .padding(.vertical, 8)
                }
                Spacer().padding(.horizontal, 2)
            }
        }
        .padding(.horizontal)
    }
}




