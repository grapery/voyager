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
    @State private var showNewItemView = false
    
    // 定义标签页数组
    let tabs: [(type: FeedType, title: String)] = [
        (.Groups, "小组"),
        (.Story, "故事"),
        (.StoryRole, "角色"),
        (.StoryBoards, "故事板")
    ]
    
    init(userId: Int64) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab View
                FeedCustomTabView(selectedTab: $selectedTab, tabs: tabs)
                
                // TabView for swipeable content
                TabView(selection: $selectedTab) {
                    ForEach(tabs, id: \.type) { tab in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                switch tab.type {
                                case .Groups:
                                    GroupsList(groups: viewModel.groups)
                                case .Story:
                                    StoriesList(stories: viewModel.storys)
                                case .StoryRole:
                                    RolesList(roles: viewModel.roles)
                                case .StoryBoards:
                                    BoardsList(boards: viewModel.boards)
                                }
                            }
                        }
                        .tag(tab.type)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("最新动态")
            .navigationBarItems(trailing:
                Button(action: {
                    showNewItemView = true
                }) {
                    Image(systemName: "plus.circle")
                }
            )
        }
        .onAppear {
            fetchData()
        }
        .onChange(of: selectedTab) { _ in
            fetchData()
        }
        .sheet(isPresented: $showNewItemView) {
            // Implement the appropriate view for creating new items
            Text("New Item View")
        }
    }
    
    private func fetchData() {
        Task {
            switch selectedTab {
            case .Groups:
                await viewModel.fetchGroups()
            case .Story:
                await viewModel.fetchStorys()
            case .StoryBoards:
                await viewModel.fetchUserCreatedStoryBoards()
            case .StoryRole:
                await viewModel.fetchStoryRoles()
            }
        }
    }
}

struct FeedCustomTabView: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.type) { tab in
                Button(action: {
                    selectedTab = tab.type
                }) {
                    Text(tab.title)
                        .foregroundColor(selectedTab == tab.type ? .black : .gray)
                        .padding(.vertical, 8)
                }
                if tab.type != tabs.last?.type {
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
}

// Helper views for each feed type
struct GroupsList: View {
    let groups: [BranchGroup]
    
    var body: some View {
        ForEach(groups, id: \.id) { group in
            FeedCellView(item: group)
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct StoriesList: View {
    let stories: [Story]
    
    var body: some View {
        ForEach(stories, id: \.id) { story in
            NavigationLink(destination: StoryView(story: story, userId: 0)) {
                FeedCellView(item: story)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct RolesList: View {
    let roles: [StoryRole]
    
    var body: some View {
        ForEach(roles, id: \.id) { role in
            FeedCellView(item: role)
        }
    }
}

struct BoardsList: View {
    let boards: [StoryBoard]
    
    var body: some View {
        ForEach(boards, id: \.id) { board in
            FeedCellView(item: board)
        }
    }
}

struct FeedCellView: View {
    let item: Any
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                avatarView
                titleView
                Spacer()
                Image(systemName: "ellipsis")
            }
            
            descriptionView
            
            // Add more content here as needed
            
            actionButtons
        }
        .padding()
        .background(Color.white)
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let group = item as? BranchGroup {
            KFImage(URL(string: group.info.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else if let story = item as? Story {
            KFImage(URL(string: story.storyInfo.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var titleView: some View {
        if let group = item as? BranchGroup {
            Text(group.info.name)
                .font(.headline)
        } else if let story = item as? Story {
            Text(story.storyInfo.name)
                .font(.headline)
        } else if let role = item as? StoryRole {
            Text(role.role.characterName)
                .font(.headline)
        } else if let board = item as? StoryBoard {
            Text(board.boardInfo.title)
                .font(.headline)
        }
    }
    
    @ViewBuilder
    private var descriptionView: some View {
        if let group = item as? BranchGroup {
            Text(group.info.desc)
                .font(.subheadline)
                .lineLimit(2)
        } else if let story = item as? Story {
            Text(story.storyInfo.origin)
                .font(.subheadline)
                .lineLimit(2)
        } else if let role = item as? StoryRole {
            Text(role.role.characterDescription)
                .font(.subheadline)
                .lineLimit(2)
        } else if let board = item as? StoryBoard {
            Text(board.boardInfo.content)
                .font(.subheadline)
                .lineLimit(2)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell.circle")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bubble.circle")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "heart.circle")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up.circle")
            }
            Spacer()
        }
        .foregroundColor(.secondary)
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
