//
//  UserProfileSubView.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/25.
//

import SwiftUI
import Kingfisher
import PhotosUI
import ActivityIndicatorView


struct StoryboardCell: View {
    let board: StoryBoardActive
    var sceneMediaContents: [SceneMediaContent]
    @Binding var selectedStoryId: Int64?
    @Binding var isShowingStoryView: Bool
    init(board: StoryBoardActive, selectedStoryId: Binding<Int64?>, isShowingStoryView: Binding<Bool>) {
        self.board = board
        self._selectedStoryId = selectedStoryId
        self._isShowingStoryView = isShowingStoryView
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
            // 主要内容
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text(board.boardActive.storyboard.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    Spacer()
                    
                    Text(formatDate(board.boardActive.storyboard.ctime))
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                // 内容
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if !self.sceneMediaContents.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(self.sceneMediaContents, id: \.id) { sceneContent in
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
                                            .lineLimit(2)
                                            .frame(width: 140)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
                // 底部统计
                HStack(spacing: 8) {
                    StatLabel(
                        icon: "heart",
                        count: Int(board.boardActive.totalLikeCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "bubble.left",
                        count: Int(board.boardActive.totalCommentCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "signpost.right.and.left",
                        count: Int(board.boardActive.totalForkCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    Spacer()
                    HStack{
                        KFImage(URL(string: convertImagetoSenceImage(url: board.boardActive.summary.storyAvatar, scene: .small)))
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.theme.border, lineWidth: 0.5)
                            )
                        Text("故事:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Button(action: {
                            selectedStoryId = board.boardActive.summary.storyID
                            Task { @MainActor in
                                isShowingStoryView = true
                            }
                        }) {
                            Text(board.boardActive.summary.storyTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.theme.primaryText)
                        }
                    }
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.border, lineWidth: 1)
                    )
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color.theme.secondaryBackground)
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}



// 修改 StoryboardsListView
private struct StoryboardsListView: View {
    let boards: [StoryBoardActive]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(boards, id: \.id) { board in
                StoryboardActiveCell(board: board)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
