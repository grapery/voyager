//
//  UnpublishBoardView.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/25.
//

import SwiftUI
import Kingfisher
import PhotosUI
import ActivityIndicatorView



struct PendingTab: View {
    @ObservedObject var viewModel: UnpublishedStoryViewModel
    @State private var isRefreshing = false
    @State private var lastLoadedBoardId: Int64? = nil
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.unpublishedStoryboards.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack {
                            ActivityIndicatorView(isVisible: .constant(true), type: .growingArc(.cyan))
                                .frame(width: 64, height: 64)
                                .foregroundColor(.cyan)
                        }
                        .frame(height: 50)
                        Text("加载中......")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else if viewModel.unpublishedStoryboards.isEmpty {
                emptyStateView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        UnPublishedstoryBoardsListView
                            .id("storyboardList")
                        Button {
                                        
                        } label: {
                            Text("加载更多")
                                .font(.footnote)
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .onChange(of: viewModel.unpublishedStoryboards) { newBoards in
                        if let lastId = lastLoadedBoardId,
                           let _ = newBoards.firstIndex(where: { $0.id == lastId }) {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if self.$viewModel.unpublishedStoryboards.wrappedValue.isEmpty {
                Task {
                    await viewModel.fetchUnpublishedStoryboards()
                }
            }
        }
        .alert("加载失败", isPresented: $viewModel.hasError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("草稿箱是空的")
                .font(.system(size: 16))
                .foregroundColor(Color.theme.secondaryText)
            Spacer()
        }
        .frame(minHeight: 300)
    }
    
    private var UnPublishedstoryBoardsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.unpublishedStoryboards) { board in
                UnpublishedBoardCellWrapper(
                    board: board,
                    userId: viewModel.userId,
                    viewModel: viewModel
                )
                Divider()
                    .padding(.horizontal,16)
            }
            if viewModel.isLoading && viewModel.unpublishedStoryboards.count > 0 {
                loadingOverlay(isLoading: true)
            }
            if !viewModel.hasMorePages && !viewModel.unpublishedStoryboards.isEmpty {
                HStack {
                    Spacer()
                    Text("没有更多草稿了")
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.secondaryText)
                        .padding(.vertical, 8)
                    Spacer()
                }
            }
        }
    }
}

private struct UnpublishedBoardCellWrapper: View {
    let board: StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: UnpublishedStoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            UnpublishedStoryBoardCellView(
                board: board,
                userId: userId,
                viewModel: viewModel
            )
            .id(board.boardActive.storyboard.storyBoardID)
        }
    }
}

struct UnpublishedStoryBoardCellView: View {
    var board: StoryBoardActive
    var userId: Int64
    @ObservedObject var viewModel: UnpublishedStoryViewModel
    @State private var showingPublishAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var isAnimating = false
    @State private var errorMessage: String = ""
    @State private var showingErrorToast = false
    @State private var showingErrorAlert = false
    var sceneMediaContents: [SceneMediaContent]
    
    init(board: StoryBoardActive, userId: Int64, viewModel: UnpublishedStoryViewModel) {
        self.board = board
        self.userId = userId
        self.viewModel = viewModel
        var tempSceneContents: [SceneMediaContent] = []
        let scenes = board.boardActive.storyboard.sences.list
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
        self.sceneMediaContents = tempSceneContents
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部：标题与草稿标记同行对齐
            HStack(alignment: .firstTextBaseline) {
                Text(board.boardActive.storyboard.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(2)
                Spacer()
                StoryboardStatusView(status: board.boardStatus())
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            // 标题和内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 故事信息
                HStack(spacing: 4) {
                    Text("故事：")
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.tertiaryText)
                    Text(board.boardActive.summary.storyTitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.accent)
                }
                // 内容
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                if !self.sceneMediaContents.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(self.sceneMediaContents, id: \ .id) { sceneContent in
                                LazyVStack(alignment: .leading, spacing: 2) {
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
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.theme.border, lineWidth: 0.5)
                                            )
                                    }
                                    // 场景标题
                                    Text(sceneContent.sceneTitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.theme.secondaryText)
                                        .lineLimit(3)
                                        .frame(width: 140)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)

            // 底部：按钮与时间下沿对齐
            HStack(alignment: .lastTextBaseline) {
                HStack(spacing: 4) {
                    Button(action: { showingEditView = true }) {
                        InteractionStatItem(
                            icon: "paintbrush.pointed",
                            text: "编辑",
                            color: Color.theme.inputText
                        )
                        .cornerRadius(2)
                    }
                    Button(action: { showingPublishAlert = true }) {
                        InteractionStatItem(
                            icon: "mountain.2",
                            text: "发布",
                            color: Color.theme.inputText
                        )
                        .cornerRadius(2)
                    }
                    Button(action: { showingDeleteAlert = true }) {
                        InteractionStatItem(
                            icon: "trash",
                            text: "删除",
                            color: Color.theme.inputText
                        )
                        .cornerRadius(2)
                    }
                }
                .font(.system(size: 15)) // 保证和时间字号一致
                Spacer()
                Text(formatDate(board.boardActive.storyboard.ctime))
                    .font(.system(size: 13))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.theme.secondaryBackground)
        .overlay(errorToastOverlay)
        .fullScreenCover(isPresented: $showingEditView) {
            NavigationStack {
                EditStoryBoardView(
                    userId: userId,
                    storyId: board.boardActive.storyboard.storyID,
                    boardId: board.boardActive.storyboard.storyBoardID,
                    viewModel: StoryViewModel(storyId: board.boardActive.storyboard.storyID,  userId: userId),
                    isPresented: $showingEditView,
                )
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingEditView)
                .navigationTitle(board.boardActive.summary.storyTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingEditView = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .alert("确认发布", isPresented: $showingPublishAlert) {
            Button("取消", role: .cancel) { }
            Button("发布", role: .destructive) {
                Task {
                    // TODO: 调用发布API
                    // await viewModel.publishStoryBoard(boardId: board.id)
                }
            }
        } message: {
            Text("确定要发布这个故事板吗？发布后将无法修改。")
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    // TODO: 调用删除API
                    // await viewModel.deleteUnpublishedStoryBoard(boardId: board.id)
                }
            }
        } message: {
            Text("确定要删除这个故事板吗？此操作无法撤销。")
        }
    }
    
    private var errorToastOverlay: some View {
        Group {
            if showingErrorToast {
                UnpublishedToastView(message: errorMessage)
                    .animation(.easeInOut)
                    .transition(.move(edge: .top))
            }
        }
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Interaction Stat Item
private struct InteractionStatItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

private struct UnpublishedToastView: View {
    let message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.theme.secondary.opacity(0.9))
                .cornerRadius(8)
        }
        .padding(.top, 20)
    }
}

struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    let content: Content
    
    init(
        isRefreshing: Binding<Bool>,
        onRefresh: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                if geometry.frame(in: .global).minY > 50 {
                    Color.clear
                        .preference(key: RefreshKey.self, value: true)
                } else {
                    Color.clear
                        .preference(key: RefreshKey.self, value: false)
                }
            }
            .frame(height: 0)
            content
        }
        .onPreferenceChange(RefreshKey.self) { shouldRefresh in
            if shouldRefresh && !isRefreshing {
                isRefreshing = true
                onRefresh()
            }
        }
    }
}

private struct RefreshKey: PreferenceKey {
    static var defaultValue = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// 用户状态优先级逻辑
private var userStatus: String {
    // 这里可根据业务逻辑和用户选择返回一个状态
    // 示例：优先级顺序
    let all = ["忙碌", "勿扰", "有屏障", "AI存在中"]
    // 假设有 user.statusList: [String]，这里只取第一个
    // return user.statusList.first ?? ""
    return all.first ?? ""
}



private struct StoryboardStatusView: View {
    let status: StoryboardStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
            Text(statusText)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    private var iconName: String {
        switch status {
        case .draft: return "doc.plaintext"
        case .scene: return "rectangle.3.offgrid"
        case .image: return "photo.on.rectangle"
        case .finished: return "checkmark.seal"
        case .published: return "paperplane"
        }
    }
    private var statusText: String {
        switch status {
        case .draft: return "草稿"
        case .scene: return "场景"
        case .image: return "图片"
        case .finished: return "完成"
        case .published: return "已发布"
        }
    }
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .scene: return .orange
        case .image: return .blue
        case .finished: return .green
        case .published: return .green
        }
    }
}
