//
//  StoryBoardDetail.swift
//  voyager
//
//  Created by grapestree on 2025/3/1.
//


import SwiftUI
import Kingfisher
import Combine
import AVKit


// 媒体项目类型
struct MediaItem: Identifiable {
    let id: String
    let type: MediaType
    let url: URL
    let thumbnail: URL?
}

// 添加场景媒体项目结构
struct SceneMediaContent: Identifiable {
    let id: String
    let sceneTitle: String
    let mediaItems: [MediaItem]
}

struct StoryBoardCellView: View {
    let board: StoryBoardActive
    let userId: Int64
    let groupId: Int64
    let storyId: Int64
    @ObservedObject var viewModel: StoryViewModel
    @State private var isLiked = false
    @State private var showDetail = false
    
    // 添加评论相关状态
    @State private var commentText: String = ""
    @State var commentViewModel = CommentsViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // 将 sceneMediaContents 改为普通属性而不是 @State
    let sceneMediaContents: [SceneMediaContent]
    
    init(board: StoryBoardActive? = nil, userId: Int64, groupId: Int64, storyId: Int64,viewModel: StoryViewModel) {
        self.board = board!
        self.userId = userId
        self.groupId = groupId
        self.storyId = storyId
        self.viewModel = viewModel
        
        // 初始化 sceneMediaContents
        var tempSceneContents: [SceneMediaContent] = []
        
        if let scenes = board?.boardActive.storyboard.sences.list {
            
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
                    
                }
            }
        }
        
        self.sceneMediaContents = tempSceneContents
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                KFImage(URL(string: defaultAvator))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(board.boardActive.storyboard.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Text(formatDate(timestamp: board.boardActive.storyboard.ctime))
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                Spacer()
            }
            
            // Content
            Text(board.boardActive.storyboard.title)
                .font(.system(size: 12))
                .foregroundColor(Color.theme.primaryText)
                .padding(.vertical, 1)
            
            // Images Grid
            if !self.sceneMediaContents.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(self.sceneMediaContents, id: \.id) { sceneContent in
                                VStack(alignment: .leading, spacing: 2) {
                                    // 场景图片（取第一张）
                                    if let firstMedia = sceneContent.mediaItems.first {
                                        KFImage(firstMedia.url)
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.theme.tertiaryBackground)
                                                    .overlay(
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle())
                                                    )
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 140, height: 200)
                                            .clipped()
                                            .cornerRadius(6)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                print("Tapped scene: \(sceneContent.sceneTitle)")
                                            }
                                    }
                                    
                                    // 场景标题
                                    Text(sceneContent.sceneTitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.theme.secondaryText)
                                        .lineLimit(2)
                                        .frame(width: 140)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Interaction Bar
            HStack(spacing: 24) {
                // Like Button
                StorySubViewInteractionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    count: "\(board.boardActive.totalLikeCount)",
                    color: isLiked ? Color.theme.error : Color.theme.tertiaryText,
                    action: {
                        withAnimation(.spring()) {
                            isLiked.toggle()
                        }
                    }
                )
                
                // Comment Button
                StorySubViewInteractionButton(
                    icon: "bubble.left",
                    count: "\(board.boardActive.totalCommentCount)",
                    color: Color.theme.tertiaryText,
                    action: {
                        showDetail = true
                    }
                )
                
                // Share Button
                StorySubViewInteractionButton(
                    icon: "square.and.arrow.up",
                    count: "\(board.boardActive.totalForkCount)",
                    color: Color.theme.tertiaryText,
                    action: {
                        // Share action
                    }
                )
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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

