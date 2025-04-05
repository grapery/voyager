//
//  Storyboardsummary.swift
//  voyager
//
//  Created by grapestree on 2025/4/5.
//

import SwiftUI
import Kingfisher
import Combine
import AVKit

struct StoryboardSummary: View {
    let storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @StateObject var viewModel: StoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var currentSceneIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack(spacing: 12) {
                    // 返回按钮
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .imageScale(.large)
                    }
                    
                    // 故事信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(storyBoardActive.summary.storyTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.theme.primaryText)
                        
                        Text(storyBoardActive.summary.storyDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.theme.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // 故事统计信息
                HStack(spacing: 24) {
                    // 故事板数量
                    VStack(spacing: 4) {
                        Text("\(storyBoardActive.summary.totalLikeCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.theme.primaryText)
                        Text("故事板")
                            .font(.system(size: 12))
                            .foregroundColor(.theme.tertiaryText)
                    }
                    
                    // 总点赞数
                    VStack(spacing: 4) {
                        Text("\(storyBoardActive.totalLikeCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.theme.primaryText)
                        Text("点赞")
                            .font(.system(size: 12))
                            .foregroundColor(.theme.tertiaryText)
                    }
                    
                    // 总评论数
                    VStack(spacing: 4) {
                        Text("\(storyBoardActive.totalCommentCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.theme.primaryText)
                        Text("评论")
                            .font(.system(size: 12))
                            .foregroundColor(.theme.tertiaryText)
                    }
                }
                .padding(.vertical, 16)
                .background(Color.theme.secondaryBackground)
                
                // 故事板内容
                VStack(alignment: .leading, spacing: 16) {
                    // 故事板标题和内容
                    Text(storyBoardActive.storyboard.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.theme.primaryText)
                        .padding(.horizontal, 16)
                    
                    Text(storyBoardActive.storyboard.content)
                        .font(.system(size: 14))
                        .foregroundColor(.theme.secondaryText)
                        .padding(.horizontal, 16)
                    
                    // 场景图片展示
                    let scenes = storyBoardActive.storyboard.sences.list
                    if !scenes.isEmpty {
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
                    
                    // 交互按钮
                    HStack(spacing: 24) {
                        // 点赞按钮
                        Button(action: {
                            Task {
                                await viewModel.likeStoryBoard(
                                    storyId: storyBoardActive.storyboard.storyID,
                                    boardId: storyBoardActive.storyboard.storyBoardID,
                                    userId: userId
                                )
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: storyBoardActive.isliked ? "heart.fill" : "heart")
                                    .foregroundColor(storyBoardActive.isliked ? .theme.error : .theme.tertiaryText)
                                Text("\(storyBoardActive.totalLikeCount)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.theme.tertiaryText)
                            }
                        }
                        
                        // 评论按钮
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.theme.tertiaryText)
                                Text("\(storyBoardActive.totalCommentCount)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.theme.tertiaryText)
                            }
                        }
                        
                        // 分支按钮
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundColor(.theme.tertiaryText)
                                Text("\(storyBoardActive.totalForkCount)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.theme.tertiaryText)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 评论列表
                    VStack(alignment: .leading, spacing: 8) {
                        Text("评论 \(storyBoardActive.totalCommentCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.theme.primaryText)
                            .padding(.horizontal, 16)
                        
                        CommentListView(
                            storyId: storyBoardActive.storyboard.storyID,
                            storyboardId: storyBoardActive.storyboard.storyBoardID,
                            userId: userId
                        )
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .background(Color.theme.background)
    }
}
