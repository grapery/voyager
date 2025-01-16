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
    @State private var currentSceneIndex = 0
    @State private var showEditView = false
    @State var viewModel: StoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showCommentSheet = false  // 添加状态变量
    
    var body: some View {
        ZStack {
            // 背景色
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    Spacer()
                    
                    Text(board?.boardInfo.title ?? "")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    
                    Button(action: {
                        showEditView = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    
                    Button(action: { /* 更多操作 */ }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                }
                .padding()
                
                // 主要内容区域
                if let scenes = board?.boardInfo.sences.list, !scenes.isEmpty {
                    // 添加主容器
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            // TabView
                            TabView(selection: $currentSceneIndex) {
                                ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                                    ScenePageView(scene: scene)
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            
                            // 底部进度指示器
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    ForEach(0..<scenes.count, id: \.self) { index in
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(height: 4)
                                            .opacity(currentSceneIndex >= index ? 1.0 : 0.3)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // 场景内容文字
                                if let scene = board?.boardInfo.sences.list[currentSceneIndex] {
                                    Text(scene.content)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .padding(.horizontal)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    // 底部信息栏
                    VStack(alignment: .leading, spacing: 8) {
                        // 交互按钮
                        HStack(spacing: 20) {
                            Spacer().scaledToFit()
                            
                            Button(action: {
                                Task{
                                    let err = await viewModel.likeStoryBoard(storyId: self.storyId, boardId: (self.board?.boardInfo.storyBoardID)!, userId: self.userId)
                                }
                            }) {
                                VStack {
                                    Image(systemName: "heart")
                                        .foregroundColor(.white)
                                    Text("270")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer().scaledToFit()
                            
                            Button(action: {
                                showCommentSheet = true
                            }) {
                                VStack {
                                    Image(systemName: "bubble.left")
                                        .foregroundColor(.white)
                                    Text("41")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer().scaledToFit()
                            
                            Button(action: {
                                Task{
                                    let err = await viewModel.likeStoryBoard(storyId: self.storyId, boardId: self.board?.id ?? 0, userId: self.userId)
                                }
                            }) {
                                VStack {
                                    Image(systemName: "star")
                                        .foregroundColor(.white)
                                    Text("94")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer().scaledToFit()
                            
                            Button(action: {
                                Task{
                                    let err = await viewModel.likeStoryBoard(storyId: self.storyId, boardId: self.board?.id ?? 0, userId: self.userId)
                                }
                            }) {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.white)
                                    Text("296")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            
                            Spacer().scaledToFit()
                        }
                        .padding(.vertical)
                    }
                    .background(Color.black.opacity(0.5))
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCommentSheet) {
            CommentSheetView(storyId: storyId, boardId: board?.boardInfo.storyBoardID ?? 0, userId: self.userId)
        }
        .fullScreenCover(isPresented: $showEditView) {
            EditStoryBoardView(
                storyId: storyId,
                boardId: (board?.boardInfo.storyBoardID)!,
                userId: self.userId,
                viewModel: self.viewModel
                )
        }
    }
}

// 添加评论框视图
struct CommentSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var commentText = ""
    @State private var comments: [Comment] = [] // 添加评论数据模型
    let storyId: Int64
    let boardId: Int64
    let userId: Int64
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏
            HStack {
                Text("评论")
                    .font(.headline)
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            
            // 评论列表
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .padding()
            }
            
            // 底部评论输入区域
            VStack {
                Divider()
                HStack(spacing: 8) {
                    // 评论输入框
                    TextField("发送友善评论", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: 36)
                    
                    // AI 渲染按钮
                    Button(action: {
                        // TODO: AI 渲染评论逻辑
                    }) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                    
                    // 发送按钮
                    Button(action: {
                        // TODO: 发送评论逻辑
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("发送")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 2)
        }
    }
}

// 评论行视图
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 用户头像
            AsyncImage(url: URL(string: comment.commentUser.avatar)) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 用户名和时间
                HStack {
                    Text(comment.commentUser.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(comment.realComment.mtime)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 评论内容
                Text(comment.realComment.content)
                    .font(.body)
            }
        }
    }
}


// 场景页面视图
private struct ScenePageView: View {
    let scene: Common_StoryBoardSence
    
    var body: some View {
        GeometryReader { geometry in
            if let urls = try? JSONDecoder().decode([String].self, from: scene.genResult.data(using: .utf8) ?? Data()) {
                TabView {
                    ForEach(urls, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
            }
        }
    }
}
// 图片占位图
struct ImagePlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray6))
            
            ProgressView()
                .scaleEffect(1.5)
        }
    }
}

// 头像占位图
struct AvatarPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
            
            Image(systemName: "person.fill")
                .foregroundColor(Color(.systemGray3))
                .font(.system(size: 20))
        }
    }
}

