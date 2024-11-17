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
                    TabView(selection: $currentSceneIndex) {
                        ForEach(Array(scenes.enumerated()), id: \.element.content) { index, scene in
                            ScenePageView(scene: scene)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // 底部信息栏
                    VStack(alignment: .leading, spacing: 8) {
                        if let scene = board?.boardInfo.sences.list[currentSceneIndex] {
                            Text(scene.content)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(.horizontal)
                        }
                        
                        // 交互按钮
                        HStack(spacing: 20) {
                            Spacer().scaledToFit()
                            
                            Button(action: { /* 点赞操作 */ }) {
                                VStack {
                                    Image(systemName: "heart")
                                        .foregroundColor(.white)
                                    Text("270")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer().scaledToFit()
                            
                            Button(action: { /* 评论操作 */ }) {
                                VStack {
                                    Image(systemName: "bubble.left")
                                        .foregroundColor(.white)
                                    Text("41")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer().scaledToFit()
                            
                            Button(action: { /* 收藏操作 */ }) {
                                VStack {
                                    Image(systemName: "star")
                                        .foregroundColor(.white)
                                    Text("94")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer().scaledToFit()
                            
                            Button(action: { /* 分享操作 */ }) {
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
        .fullScreenCover(isPresented: $showEditView) {
            EditStoryBoardView(
                storyId: storyId,
                boardId: (board?.boardInfo.storyBoardID)!,
                viewModel: self.viewModel
            )
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

