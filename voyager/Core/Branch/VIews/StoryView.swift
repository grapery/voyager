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
    @State private var selectedTab: Int64 = 0
    @State public var story: Story
    
    var userId: Int64
    
    // 新增的状态变量
    @State private var generatedStory: Common_RenderStoryDetail?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var buttonMsg: String = "生成故事"
    
    @State private var isShowingNewStoryBoard = false
    @State private var isShowingCommentView = false
    @State private var isForkingStory = false
    @State private var isLiked = false
    
    private func setButtonMsg() {
        if isGenerating {
            buttonMsg = "正在生成..."
        } else if generatedStory != nil {
            buttonMsg = "重新生成"
        } else if errorMessage != nil {
            buttonMsg = "重试"
        } else {
            buttonMsg = "生成故事"
        }
    }
    
    init(story: Story, userId: Int64) {
        self.story = story
        self.userId = userId
        self.storyId = story.storyInfo.id
        self.viewModel = StoryViewModel(story: story, userId: userId)
        setButtonMsg()
    }
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Story Info Header
            VStack(alignment: .leading, spacing: 8) {
                NavigationLink(destination: StoryDetailView(storyId: self.storyId, story: self.viewModel.story!)) {
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
                
                HStack{
                    Text(self.viewModel.story?.storyInfo.origin ?? "")
                        .font(.subheadline)
                        .lineLimit(5)
                    Spacer()
                    VStack(alignment: .leading, spacing: 8){
                        Button(action: {
                            generateStory()
                        }) {
                            Text(buttonMsg)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                }
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
            
            StoryTabView(selectedTab: $selectedTab)
                .padding(.top, 4) // 减少顶部间距

            GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if selectedTab == 0 {
                            // 故事线视图
                            storyLineView
                        } else {
                            // 故事生成视图
                            StoryGenView(generatedStory: $generatedStory,
                                         isGenerating: $isGenerating,
                                         errorMessage: $errorMessage,
                                         viewModel: $viewModel,
                                         selectedTab: $selectedTab)
                        }
                    }
                    .frame(minHeight: geometry.size.height)
            }
            .padding(.top, 0) // 移除 GeometryReader 的顶部间距
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
    
    private var storyLineView: some View {
        VStack {
            if viewModel.isLoading {
                VStack{
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let boards = viewModel.storyboards {
                ScrollView {
                    LazyVStack {
                        ForEach(boards, id: \.id) { board in
                            StoryBoardCellView(board: board, userId: userId, groupId: self.viewModel.story?.storyInfo.groupID ?? 0, storyId: storyId, viewModel: self.viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func generateStory() {
        isGenerating = true
        errorMessage = nil
        setButtonMsg()
        // 模拟生成故事的过程
        //DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            Task { @MainActor in
                let result = await self.viewModel.genStory(storyId: self.storyId, userId: self.userId)
                
                if let error = result.1 {
                    self.errorMessage = error.localizedDescription
                    self.generatedStory = nil
                } else {
                    self.generatedStory = result.0
                    self.errorMessage = nil
                }
                
                self.isGenerating = false
                self.setButtonMsg()
            }
        //}
    }
    
    private func getGenerateStory() {
        errorMessage = nil
        //DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            Task { @MainActor in
                let result = await self.viewModel.getGenStory(storyId: self.storyId, userId: self.userId)
                print("StoryView help getGenerateStory ")
                if let error = result.1 {
                    self.errorMessage = error.localizedDescription
                    self.generatedStory = nil
                } else {
                    self.generatedStory = result.0
                    self.errorMessage = nil
                }
            }
        //}
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
    @State var viewModel: StoryViewModel
    @State private var isShowingBoardDetail = false
    
    @State var isPressed = false
    @State var isShowingNewStoryBoard = false
    @State var isShowingCommentView = false
    @State var isForkingStory = false
    @State var isLiked = false
    
    init(board: StoryBoard? = nil, userId: Int64, groupId: Int64, storyId: Int64, isShowingBoardDetail: Bool = false,viewModel: StoryViewModel) {
        self.board = board
        self.userId = userId
        self.groupId = groupId
        self.storyId = storyId
        self.isShowingBoardDetail = isShowingBoardDetail
        self.viewModel = viewModel
        self.isPressed = false
        print("board info",board as Any)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                VStack(alignment: .leading) {
                    Text(board?.boardInfo.title ?? "无标题故事章节")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(formatDate(timestamp: (board?.boardInfo.ctime)!))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let description = board?.boardInfo.content, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // 处理创建逻辑
                    self.isPressed = true
                    self.isShowingNewStoryBoard = true
                }) {
                    HStack {
                        Image(systemName: "highlighter")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                    .scaledToFit()
                    .border(Color.green.opacity(0.3))
                Button(action: {
                    // 处理分叉逻辑
                    self.isPressed = true
                    self.isForkingStory = true
                }) {
                    HStack {
                        Image(systemName: "signpost.right.and.left")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                    .scaledToFit()
                    .border(Color.green.opacity(0.3))
                Button(action: {
                    // 处理评论逻辑
                    self.isPressed = true
                    self.isShowingCommentView = true
                    
                }) {
                    HStack {
                        Image(systemName: "bubble.middle.bottom")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                    .scaledToFit()
                    .border(Color.green.opacity(0.3))
                Button(action: {
                    // 处理点赞逻辑
                    self.isPressed = true
                    self.isLiked = true
                    
                }) {
                    HStack {
                        Image(systemName: "heart")
                            .font(.headline)
                    }
                    .scaledToFill()
                    
                }
                Spacer()
                Button(action: {
                    Task{
                        // 处理删除逻辑
                        await self.viewModel.deleteStoryBoard(storyId: self.storyId, boardId: (self.board?.boardInfo.storyBoardID)!, userId: self.userId)
                    }
                    
                }) {
                    HStack {
                        Image(systemName: "minus")
                            .font(.headline)
                    }
                    .scaledToFill()
                    
                }
                Spacer()
            }
            .foregroundColor(.secondary)
            .font(.caption)
            .sheet(isPresented: self.$isPressed) {
                if self.$isShowingNewStoryBoard.wrappedValue {
                    NewStoryBoardView(
                        storyId: self.viewModel.storyId,
                        boardId: (self.board?.boardInfo.storyBoardID)!,
                        prevBoardId: (self.board?.boardInfo.prevBoardID)!,
                        viewModel: self.$viewModel,
                        isForkingStory: false)
                }else if self.$isForkingStory.wrappedValue {
                    NewStoryBoardView(
                        storyId: self.viewModel.storyId,
                        boardId: (self.board?.boardInfo.storyBoardID)!,
                        prevBoardId: (self.board?.boardInfo.prevBoardID)!,
                        viewModel: self.$viewModel,
                        isForkingStory: true)
                }else if self.$isShowingCommentView.wrappedValue{
                    CommentView(
                        storyId: self.viewModel.storyId,
                        boardId: (self.board?.boardInfo.storyBoardID)!,
                        userId: self.viewModel.userId,
                        viewModel: self.$viewModel
                    )
                }else if self.$isLiked.wrappedValue{
                    NewStoryBoardView(
                        storyId: self.viewModel.storyId,
                        boardId: (self.board?.boardInfo.storyBoardID)!,
                        prevBoardId: (self.board?.boardInfo.prevBoardID)!,
                        viewModel: self.$viewModel,
                        isForkingStory: false)
                }
                
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
    @Binding var selectedTab: Int64
    let tabs = ["故事板", "故事线"]
    
    var body: some View {
        HStack {
            Spacer().padding(.horizontal, 2)
            ForEach(0..<2) { index in
                Button(action: {
                    selectedTab = Int64(index)
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
