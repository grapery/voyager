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
    @State var board: StoryBoardActive?
    @State var userId: Int64
    @State var groupId: Int64
    @State var storyId: Int64
    @State private var currentSceneIndex = 0
    @State var viewModel: StoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var commentText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack(spacing: 12) {
                // 返回按钮
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .imageScale(.large)
                }
                
                // 用户信息
                HStack(spacing: 8) {
                    KFImage(URL(string: (board?.boardActive.creator.userAvatar)!))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text((board?.boardActive.creator.userName)!)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
                
                Spacer()
                
                // 关注按钮
                Button(action: {
                    // 关注操作
                }) {
                    Text("关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.theme.error)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题和内容
                    Text(board?.boardActive.storyboard.title ?? "")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 16)
                    
                    Text(board?.boardActive.storyboard.content ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    // 图片区域
                    if let scenes = board?.boardActive.storyboard.sences.list, !scenes.isEmpty {
                        ZStack(alignment: .bottom) {
                            TabView(selection: $currentSceneIndex) {
                                ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                                    if let data = scene.genResult.data(using: .utf8),
                                       let urls = try? JSONDecoder().decode([String].self, from: data),
                                       let firstUrl = urls.first {
                                        KFImage(URL(string: firstUrl))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 400)
                                            .clipped()
                                            .tag(index)
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            
                            // 进度指示器
                            VStack(spacing: 8) {
                                // 进度线
                                HStack(spacing: 4) {
                                    ForEach(0..<scenes.count, id: \.self) { index in
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(height: 4)
                                            .opacity(currentSceneIndex == index ? 1.0 : 0.3)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                                
                                // 场景描述
                                let scene = scenes[currentSceneIndex]
                                Text(scene.content)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                                    .lineLimit(2)
                            }
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0),
                                        Color.black.opacity(0.5)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 400)
                    }
                    Divider()
                    // 评论区域
                    VStack(alignment: .leading, spacing: 8) {
                        // 评论数量
                        Text("共 \(board?.boardActive.totalCommentCount ?? 0) 条评论")
                            .font(.system(size: 14))
                            .foregroundColor(.theme.tertiaryText)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    // 评论列表
                    CommentListView(storyId: self.storyId, storyboardId: self.board?.boardActive.storyboard.storyBoardID, userId: self.userId)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// 交互按钮组件
private struct StoryboardDetailInteractionButton: View {
    let icon: String
    let count: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(count)
                    .font(.system(size: 12))
            }
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
//                    Text("\(comment.realComment.mtime)")
//                        .font(.caption)
//                        .foregroundColor(.gray)
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

