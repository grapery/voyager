//
//  FeedView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

extension Date{
    var timeStamp: String{
        let formatter = DateFormatter()
        formatter.dateFormat = "s"
        return formatter.string(from: self)
    }
}

enum FeedType{
    case Groups
    case Story
    case StoryRole
    case StoryBoards
}
    
// 获取用户的关注以及用户参与的故事，以及用户关注或者参与的小组的故事动态。不可以用户关注用户，只可以关注小组或者故事,以及故事的角色
struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var selectedTab: FeedType = .Groups
    
    init(userId: Int64) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                // Tab selection
                Picker("Feed Type", selection: $selectedTab) {
                    Text("小组").tag(FeedType.Groups)
                    Text("故事").tag(FeedType.Story)
                    Text("角色").tag(FeedType.StoryRole)
                    Text("故事板").tag(FeedType.StoryBoards)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Spacer()
                VStack {
                    SearchBar(text: Binding(
                        get: { viewModel.searchText },
                        set: { newValue in
                            Task { @MainActor in
                                viewModel.searchText = newValue
                            }
                        }
                    ), onCommit: {
                        Task { @MainActor in
                            await viewModel.performSearch()
                        }
                    })
                    .padding(.horizontal)
                }
                Spacer()
                
                // Content based on selected tab with swipe support
                TabView(selection: $selectedTab) {
                    ScrollView {
                        GroupsList(groups: viewModel.groups)
                    }
                    .tag(FeedType.Groups)
                    
                    ScrollView {
                        StoriesList(stories: viewModel.storys)
                    }
                    .tag(FeedType.Story)
                    
                    ScrollView {
                        RolesList(roles: viewModel.roles)
                    }
                    .tag(FeedType.StoryRole)
                    
                    ScrollView {
                        BoardsList(boards: viewModel.boards)
                    }
                    .tag(FeedType.StoryBoards)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .onAppear {
                if selectedTab == .Groups{
                    Task{
                        await viewModel.fetchGroups()
                    }
                }else if selectedTab == .Story {
                    Task{
                        await viewModel.fetchStorys()
                    }
                }else if selectedTab == .StoryBoards {
                    Task{
                        await viewModel.fetchUserCreatedStoryBoards()
                    }
                }else if selectedTab == .StoryRole {
                    Task{
                        await viewModel.fetchStoryRoles()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "plus.circle")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        
    }
}

// Helper views for each feed type
struct GroupsList: View {
    @State var groups: [BranchGroup]
    var body: some View {
        ForEach(groups, id: \.id) { group in
            FeedBoardCellView(group: group, feedType: .Groups)
        }
    }
}

struct StoriesList: View {
    @State var stories: [Story]
    var body: some View {
        ForEach(stories, id: \.id) { story in
            FeedBoardCellView(story: story, feedType: .Story)
        }
    }
}

struct RolesList: View {
    @State var roles: [StoryRole]
    var body: some View {
        ForEach(roles, id: \.id) { role in
            FeedBoardCellView(role: role, feedType: .StoryRole)
        }
    }
}

struct BoardsList: View {
    @State var boards: [StoryBoard]
    var body: some View {
        ForEach(boards, id: \.id) { board in
            FeedBoardCellView(board: board, feedType: .StoryBoards)
        }
    }
}

struct FeedBoardCellView: View {
    @State var board: StoryBoard?
    @State var story: Story?
    @State var role: StoryRole?
    @State var group: BranchGroup?
    @State var user: User?
    @State var isLoading: Bool = false
    @State var error: Error?
    var feedType: FeedType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                avatarView
                titleView
                Spacer()
                timeView
            }
            
            descriptionView
            
            contentView
            
            actionView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    @ViewBuilder
    private var avatarView: some View {
        switch feedType {
        case .Groups:
            KFImage(URL(string: group?.info.avatar ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        case .Story:
            KFImage(URL(string: story?.storyInfo.avatar ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
        case .StoryRole:
            KFImage(URL(string: role?.role.characterAvatar ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        case .StoryBoards:
            KFImage(URL(string:  ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var titleView: some View {
        VStack(alignment: .leading) {
            switch feedType {
            case .Groups:
                Text(group?.info.name ?? "")
                    .font(.headline)
                Text("成员: \( 0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .Story:
                Text(story!.storyInfo.title)
                    .font(.headline)
                Text("作者: ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .StoryRole:
                Text(role?.role.characterName ?? "")
                    .font(.headline)
                Text(role?.role.characterDescription ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .StoryBoards:
                Text(board?.boardInfo.title ?? "")
                    .font(.headline)
            }
        }
    }
    
    @ViewBuilder
    private var timeView: some View {
        Text(getLastUpdateTime().timeAgoDisplay())
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var descriptionView: some View {
        switch feedType {
        case .Groups:
            Text(group?.info.desc ?? "")
                .font(.body)
                .lineLimit(2)
        case .Story:
            Text(story?.storyInfo.desc ?? "")
                .font(.body)
                .lineLimit(3)
        case .StoryRole:
            Text(role?.role.characterDescription ?? "")
                .font(.body)
                .lineLimit(2)
        case .StoryBoards:
            Text(board?.boardInfo.title ?? "")
                .font(.body)
                .lineLimit(2)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        // 这里可以根据需要添加更多的内容
        EmptyView()
    }
    
    @ViewBuilder
    private var actionView: some View {
        HStack {
            switch feedType {
            case .Groups:
                Image(systemName: "book.fill")
                Text("\( 0) 个故事")
            case .Story:
                Image(systemName: "person.2.fill")
                Text("\(0) 参与者")
            case .StoryRole:
                Image(systemName: "person.fill")
                Text("角色")
            case .StoryBoards:
                Image(systemName: "bubble.left.fill")
                Text("\( 0) 评论")
            }
            Spacer()
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private func getLastUpdateTime() -> Date {
        switch feedType {
        case .Groups:
            return Date()
        case .Story:
            return Date()
        case .StoryBoards:
            return Date()
        case .StoryRole:
            return Date()
        }
    }
}

// 辅助扩展，用于显示相对时间
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
