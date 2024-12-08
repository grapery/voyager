//
//  StoryView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine
import AVKit

struct StoryView: View {
    @StateObject var viewModel: StoryViewModel
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
    
    @State private var selectedBoard: StoryBoard?
    @State private var isShowingBoardDetail = false
    
    private func setButtonMsg() {
        if isGenerating {
            buttonMsg = "正在生成..."
        } else if generatedStory != nil {
            buttonMsg = "���生成"
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
        _viewModel = StateObject(wrappedValue: StoryViewModel(story: story, userId: userId))
        setButtonMsg()
    }
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Story Info Header
            VStack(alignment: .leading, spacing: 12) {
                // 用户信息部分
                NavigationLink(destination: StoryDetailView(storyId: self.storyId, story: self.viewModel.story!, userId: self.userId)) {
                    HStack(spacing: 12) {
                        KFImage(URL(string: self.viewModel.story?.storyInfo.avatar ?? ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(self.viewModel.story?.storyInfo.name ?? "")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if let createdAt = self.viewModel.story?.storyInfo.ctime {
                                Text(formatDate(timestamp: createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                
                // 故事简介部分
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.viewModel.story?.storyInfo.origin ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                    
                    Button(action: { generateStory() }) {
                        Text(buttonMsg)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                    .disabled(isGenerating)
                }
                
                // 交互按钮栏
                HStack(spacing: 24) {
                    StoryInteractionButton(count: "10", icon: "heart", color: .red)
                    StoryInteractionButton(count: "1", icon: "bell", color: .blue)
                    StoryInteractionButton(count: "分享", icon: "square.and.arrow.up", color: .green)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
            
            Divider()
            
            StoryTabView(selectedTab: $selectedTab)
                .padding(.top, 2) // 减少顶部间距

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
                                         viewModel: viewModel,
                                         selectedTab: $selectedTab)
                        }
                    }
                    .frame(minHeight: geometry.size.height)
            }
            .padding(.top, 0) // 移除 GeometryReader 的顶部间距
        }
        .navigationTitle("故事")
        .task {
            if viewModel.storyboards == nil {
                await viewModel.fetchStory(withBoards: true)
                print("task fetchStory :",viewModel.storyboards as Any)
            }
        }
    }

    
    private var storyLineView: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let boards = viewModel.storyboards {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(boards, id: \.id) { board in
                            StoryBoardCellView(
                                board: board,
                                userId: userId,
                                groupId: self.viewModel.story?.storyInfo.groupID ?? 0,
                                storyId: storyId,
                                viewModel: self.viewModel
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemBackground))
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

// 添加场景媒体项目结构
struct SceneMediaContent: Identifiable {
    let id: String
    let sceneTitle: String
    let mediaItems: [MediaItem]
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
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // 将 sceneMediaContents 改为普通属性而不是 @State
    let sceneMediaContents: [SceneMediaContent]
    
    
    init(board: StoryBoard? = nil, userId: Int64, groupId: Int64, storyId: Int64, isShowingBoardDetail: Bool = false, viewModel: StoryViewModel) {
        self.board = board
        self.userId = userId
        self.groupId = groupId
        self.storyId = storyId
        self.viewModel = viewModel
        self.isShowingBoardDetail = isShowingBoardDetail
        
        // 初始化 sceneMediaContents
        var tempSceneContents: [SceneMediaContent] = []
        
        if let scenes = board?.boardInfo.sences.list {
            print("Processing \(scenes.count) scenes")
            
            for scene in scenes {
                let genResult = scene.genResult
                if let data = genResult.data(using: .utf8),
                   let urls = try? JSONDecoder().decode([String].self, from: data) {
                    
                    var mediaItems: [MediaItem] = []
                    for urlString in urls {
                        if let url = URL(string: urlString) {
                            let item = MediaItem(
                                id: UUID().uuidString,
                                type: urlString.hasSuffix(".mp4") ? .video : .image,
                                url: url,
                                thumbnail: urlString.hasSuffix(".mp4") ? URL(string: urlString) : nil
                            )
                            mediaItems.append(item)
                        }
                    }
                    
                    let sceneContent = SceneMediaContent(
                        id: UUID().uuidString,
                        sceneTitle: scene.content,
                        mediaItems: mediaItems
                    )
                    tempSceneContents.append(sceneContent)
                    
                    print("Added scene with \(mediaItems.count) media items")
                }
            }
        }
        
        self.sceneMediaContents = tempSceneContents
        print("Initialized with \(self.sceneMediaContents.count) scenes")
    }
    
    private var storyboardCellHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(board?.boardInfo.title ?? "无标题故事章节")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(formatDate(timestamp: (board?.boardInfo.ctime)!))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var senceDetails: some View{
        VStack{
            ForEach(sceneMediaContents) { sceneContent in
                VStack(alignment: .leading) {
                    Text(sceneContent.sceneTitle)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    // 如果场景只有一张图片
                    if sceneMediaContents.count == 4 {
                        RectProfileImageView(avatarUrl: sceneContent.mediaItems[0].url.description, size: .InContent).clipped()
                            .cornerRadius(8)
                    }
                    // 如果场景有多张图片
                    else {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(Array(sceneContent.mediaItems.prefix(4).enumerated()), id: \.element.id) { index, item in
                                KFImage(item.url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: UIScreen.main.bounds.width / 2 - 16)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        // 如果有更多图片，在最后一张上显示剩余数量
                                        index == 3 && sceneContent.mediaItems.count > 4 ?
                                        ZStack {
                                            Color.black.opacity(0.4)
                                            Text("+\(sceneContent.mediaItems.count - 4)")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                        }
                                            .cornerRadius(8)
                                        : nil
                                    )
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    var body: some View {
        NavigationLink(destination: StoryBoardView(board: board!, userId: userId,groupId: self.groupId,storyId: self.storyId, viewModel: self.viewModel)) {
            VStack(alignment: .leading, spacing: 12) {
                storyboardCellHeader
                
                // Content
                VStack {
                    if sceneMediaContents.count <= 0 {
                        Text((board?.boardInfo.content)!)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    } else {
                        senceDetails
                    }
                }
                .padding(.vertical, 8)
                
                // Action buttons
                HStack(spacing: 32) {
                    ActionButton(icon: "pencil.circle", action: {
                        self.isPressed = true
                        self.isShowingNewStoryBoard = true
                    })
                    
                    ActionButton(icon: "signpost.right.and.left.circle", action: {
                        self.isPressed = true
                        self.isForkingStory = true
                    })
                    
                    ActionButton(icon: "heart.circle", action: {
                        self.isPressed = true
                        self.isLiked = true
                        Task {
                            await self.viewModel.likeStoryBoard(storyId: self.storyId, boardId: (self.board?.boardInfo.storyBoardID)!, userId: self.userId)
                        }
                    })
                    
                    if self.board?.boardInfo.creator == self.userId {
                        ActionButton(icon: "trash.circle", action: {
                            Task {
                                await self.viewModel.deleteStoryBoard(
                                    storyId: self.storyId,
                                    boardId: (self.board?.boardInfo.storyBoardID)!,
                                    userId: self.userId
                                )
                            }
                        })
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isPressed) {
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
            }
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

// 媒体项目类型
struct MediaItem: Identifiable {
    let id: String
    let type: MediaType
    let url: URL
    let thumbnail: URL?
}

enum MediaType {
    case image
    case video
}

// 媒体项目视图
struct MediaItemView: View {
    let item: MediaItem
    @State private var isPresented = false
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Group {
                switch item.type {
                case .image:
                    RectProfileImageView(avatarUrl: item.url.description, size: .InContent)
                case .video:
                    ZStack {
                        if let thumbnail = item.thumbnail {
                            KFImage(thumbnail)
                                .resizable()
                                .scaledToFill()
                        }
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .sheet(isPresented: $isPresented) {
            MediaDetailView(item: item)
        }
    }
}

// 媒体详情视图
struct MediaDetailView: View {
    let item: MediaItem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Group {
                switch item.type {
                case .image:
                    KFImage(item.url)
                        .resizable()
                        .scaledToFit()
                case .video:
                    VideoPlayer(url: item.url)
                }
            }
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 视频播放器视图
struct VideoPlayer: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// 新增的交互按钮组件
struct StoryInteractionButton: View {
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(count)
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 14, weight: .medium))
        }
    }
}

// 新增的操作按钮组件
struct ActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.secondary)
        }
    }
}


