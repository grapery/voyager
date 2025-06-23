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

// MARK: - 新的故事板条目视图 (New Storyboard Item View)
struct ForkedStoryboardItemView: View {
    let storyboard: Common_StoryBoardActive

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 封面图片
            KFImage(URL(string: convertImagetoSenceImage(url: storyboard.summary.storyAvatar, scene: .content)))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220) // 根据设计图调整一个合适的高度
                .clipped()
            
            // 2. 文本内容区域
            VStack(alignment: .leading, spacing: 10) {
                // 标题
                Text(storyboard.summary.storyTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(Color.theme.primaryText)

                // 作者信息
                HStack(spacing: 8) {
                    KFImage(URL(string: convertImagetoSenceImage(url: storyboard.creator.userAvatar, scene: .small)))
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(storyboard.creator.userName)
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.secondaryText)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading) // 确保VStack横向填满
        }
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal) // 在卡片两侧留出空间
    }
}


// MARK: - 主视图 (Main View)
struct StoryForkListView: View {
    // 初始故事板ID，用于获取其所有分支
    let initialStoryboardId: Int64
    let userId: Int64
    @Environment(\.dismiss) private var dismiss
    
    // 使用 `@StateObject` 创建独立的 ViewModel
    @StateObject private var viewModel: StoryForkListViewModel
    
    // 当前水平分页的索引
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
                    // 水平分页视图
                    TabView(selection: $currentStoryIndex) {
                        ForEach(Array(viewModel.forkedStoryboards.enumerated()), id: \.offset) { index, storyboard in
                            // 使用新的自定义视图来展示故事板摘要
                            ForkedStoryboardItemView(storyboard: storyboard)
                                .tag(index)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.theme.primaryText)
                    }
                }
            }
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
