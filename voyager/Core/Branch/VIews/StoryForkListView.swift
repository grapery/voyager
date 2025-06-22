//
//  StoryForkListView.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/21.
//

import SwiftUI
import Combine
import Kingfisher
import Foundation
import ActivityIndicatorView

// MARK: - 主视图 (Main View)
struct StoryForkListView: View {
    // 初始故事板ID，用于获取其所有分支
    let initialStoryboardId: Int64
    let userId: Int64
    
    // 使用 `@StateObject` 创建独立的 ViewModel
    @StateObject private var viewModel: StoryForkListViewModel
    
    // 当前垂直分页的索引
    @State private var currentStoryIndex = 0
    
    // 初始化时创建 ViewModel
    init(initialStoryboardId: Int64, userId: Int64,) {
        self.initialStoryboardId = initialStoryboardId
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: StoryForkListViewModel(storyboardId: initialStoryboardId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 背景
                Color.theme.background.ignoresSafeArea()
                
                // 根据加载状态显示不同内容
                if viewModel.isLoading {
                    ActivityIndicatorView(isVisible: .constant(true), type: .growingArc(Color.theme.accent))
                        .frame(width: 64, height: 64)
                        .foregroundColor(Color.theme.accent)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // 垂直分页视图
                    TabView(selection: $currentStoryIndex) {
                        ForEach(Array(viewModel.forkedStoryboards.enumerated()), id: \.offset) { index, storyboard in
                            // 复用 StoryboardSummary 的核心展示逻辑
                           Text("wati")
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // 横向分支选择器 (仅当分支数 > 1 时显示)
                    if viewModel.forkedStoryboards.count > 1 {
                        HorizontalForkSelectorView(
                            storyboards: viewModel.forkedStoryboards,
                            currentIndex: $currentStoryIndex
                        )
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("故事板分支")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 首次出现时加载数据
                if viewModel.forkedStoryboards.isEmpty {
                    viewModel.fetchForks()
                }
            }
        }
    }
}


// MARK: - 横向分支选择器 (Horizontal Fork Selector)
struct HorizontalForkSelectorView: View {
    let storyboards: [Common_StoryBoardActive]
    @Binding var currentIndex: Int
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(storyboards.enumerated()), id: \.offset) { index, storyboard in
                        ForkThumbnailView(
                            storyboard: storyboard,
                            isSelected: currentIndex == index
                        )
                        .id(index) // 给每个缩略图一个ID
                        .onTapGesture {
                            withAnimation(.spring()) {
                                currentIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { newIndex in
                // 当外部索引变化时（例如，用户垂直滑动），滚动到对应的缩略图
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(height: 60)
        .background(Color.black.opacity(0.2))
        .cornerRadius(30)
    }
}

// MARK: - 分支缩略图 (Fork Thumbnail)
struct ForkThumbnailView: View {
    let storyboard: Common_StoryBoardActive
    let isSelected: Bool
    
    var body: some View {
        KFImage(URL(string: convertImagetoSenceImage(url: storyboard.creator.userAvatar, scene: .small)))
            .cacheMemoryOnly()
            .fade(duration: 0.25)
            .resizable()
            .scaledToFill()
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        isSelected ? Color.theme.accent : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .opacity(isSelected ? 1.0 : 0.7)
            .animation(.spring(), value: isSelected)
    }
}
