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
                    VStack(alignment: .leading, spacing: 2){
                        Text("故事简介")
                            .font(.title)
                            .lineLimit(5)
                        Text(self.viewModel.story?.storyInfo.origin ?? "")
                            .font(.subheadline)
                            .lineLimit(5)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2){
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
                    Spacer().scaledToFit()
                    Label("10", systemImage: "heart.circle")
                    Spacer().scaledToFit()
                    Label("1", systemImage: "bell.circle")
                    Spacer().scaledToFit()
                    Label("分享", systemImage: "arrow.up.circle")
                    Spacer().scaledToFit()
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
                            Divider()
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
    
    // 添加评论相关状态
    @State private var commentText: String = ""
    @State var commentViewModel = CommentsViewModel()
    
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
        VStack(alignment: .leading) {
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
                        Image(systemName: "pencil.circle")
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
                        Image(systemName: "signpost.right.and.left.circle")
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
                        Image(systemName: "bubble.circle")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                .sheet(isPresented: $isShowingCommentView) {
                    CommentSheet(isPresented: $isShowingCommentView, commentText: $commentText) {
                        // 处理发布评论的回调
                        Task {
                            await submitComment()
                        }
                    }
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
                        Image(systemName: "heart.circle")
                            .font(.headline)
                    }
                    .scaledToFill()
                    
                }
                Spacer()
                    .scaledToFit()
                    .border(Color.green.opacity(0.3))
                Button(action: {
                    Task{
                        // 处理删除逻辑
                        await self.viewModel.deleteStoryBoard(storyId: self.storyId, boardId: (self.board?.boardInfo.storyBoardID)!, userId: self.userId)
                    }
                    
                }) {
                    HStack {
                        Image(systemName: "trash.circle")
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
                        roles: [StoryRole](), isForkingStory: false  )
                }else if self.$isForkingStory.wrappedValue {
                    NewStoryBoardView(
                        storyId: self.viewModel.storyId,
                        boardId: (self.board?.boardInfo.storyBoardID)!,
                        prevBoardId: (self.board?.boardInfo.prevBoardID)!,
                        viewModel: self.$viewModel,
                        roles: [StoryRole](),isForkingStory: true)
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
                        roles: [StoryRole](),isForkingStory: false)
                }
                
            }
            
        }
        .padding()
        .background(Color(.systemBackground))
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
    
    // 添加提交评论的方法
    private func submitComment() async {
        guard !commentText.isEmpty else { return }
        
        do {
            // 调用评论 API
            let err = await self.commentViewModel.submitCommentForStoryboard(
                commentText: commentText,
                storyId: storyId,
                boardId: board?.boardInfo.storyBoardID ?? 0,
                userId:  self.userId
            )
            
            if err != nil{
                // 处理错误
                print("Error submitting comment: \(String(describing: err))")
            } else {
                // 清空评论文本
                commentText = ""
                // 可能需要刷新评论列表
                await self.commentViewModel.fetchStoryboardComments()
            }
        }
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

// 添加 CommentSheet 视图
struct CommentSheet: View {
    @Binding var isPresented: Bool
    @Binding var commentText: String
    var onSubmit: () -> Void
    
    // 添加键盘相关状态
    @FocusState private var isFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("讨论")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    onSubmit()
                    isPresented = false
                }) {
                    Text("发布")
                        .foregroundColor(commentText.isEmpty ? .gray : .blue)
                }
                .disabled(commentText.isEmpty)
            }
            .padding()
            
            Divider()
            
            // 评论输入区域
            TextField("说点什么...", text: $commentText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .focused($isFocused)
                .onAppear {
                    isFocused = true // 自动弹出键盘
                }
            
            Spacer()
            
            // 底部工具栏
            HStack(spacing: 20) {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "at")
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .background(Color(.systemBackground))
        // 监听键盘事件
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        // 添加手势关闭键盘
        .gesture(
            TapGesture()
                .onEnded { _ in
                    isFocused = false
                }
        )
        // 调整视图位置以适应键盘
        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

