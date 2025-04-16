//
//  GroupView.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import SwiftUI
import Kingfisher
import Combine

// MARK: - Main Group View
struct GroupView: View {
    @StateObject var viewModel: GroupViewModel
    @State private var isShowingNewGroupView = false
    @State private var searchText = ""
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: GroupViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GroupViewHeaderView(
                    searchText: $searchText,
                    onAddTapped: { isShowingNewGroupView = true }
                )
                
                GroupViewListView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingNewGroupView) {
                NewGroupView(userId: viewModel.user.userID, viewModel: viewModel)
            }
            .onAppear {
                Task {
                    await viewModel.fetchGroups()
                }
            }
            .background(Color.theme.background)
        }
    }
}

// MARK: - Group Header View
struct GroupViewHeaderView: View {
    @Binding var searchText: String
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            CommonNavigationBar(
                title: "小组",
                onAddTapped: onAddTapped
            )
            
            CommonSearchBar(
                searchText: $searchText,
                placeholder: "搜索小组"
            )
        }
    }
}

// MARK: - Group List View
struct GroupViewListView: View {
    @ObservedObject var viewModel: GroupViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupListHeaderView(viewModel: viewModel)
                
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.groups) { group in
                        GroupViewListItemView(group: group, viewModel: viewModel)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
        .background(Color.theme.background)
    }
}

// MARK: - Group List Header View
struct GroupListHeaderView: View {
    @ObservedObject var viewModel: GroupViewModel
    
    var body: some View {
        HStack {
            Text("我的小组")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.theme.primaryText)
            Spacer()
            NavigationLink {
                AllGroupsView(viewModel: viewModel)
            } label: {
                Text("查看全部")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.accent)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Group List Item View
struct GroupViewListItemView: View {
    let group: BranchGroup
    @ObservedObject var viewModel: GroupViewModel
    @State private var showGroupDetail = false
    @State private var showingStoryInfo = false
    
    var body: some View {
        Button(action: {
            showGroupDetail = true
        }) {
            VStack(spacing: 0) {
                GroupItemContentView(group: group, viewModel: viewModel, showingStoryInfo: $showingStoryInfo)
                
                if group.id != viewModel.groups.last?.id {
                    Divider()
                        .background(Color.theme.divider)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showGroupDetail) {
            NavigationStack {
                GroupDetailView(user: viewModel.user, group: group)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showGroupDetail = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(Color.theme.primaryText)
                            }
                        }
                    }
            }
        }
        .overlay(
            Group {
                if showingStoryInfo {
                    GroupStoryInfoOverlay(
                        groupName: group.info.name,
                        storyCount: Int(group.info.profile.groupStoryNum),
                        isPresented: $showingStoryInfo
                    )
                }
            }
        )
        .animation(.spring(), value: showingStoryInfo)
    }
}

// MARK: - Group Item Content View
struct GroupItemContentView: View {
    let group: BranchGroup
    @ObservedObject var viewModel: GroupViewModel
    @Binding var showingStoryInfo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupHeaderInfoView(group: group)
            
            if !group.info.desc.isEmpty {
                Text(group.info.desc)
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(2)
            }
            
            GroupInteractionButtonsView(
                group: group,
                viewModel: viewModel,
                showingStoryInfo: $showingStoryInfo
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.theme.secondaryBackground)
    }
}

// MARK: - Group Header Info View
struct GroupHeaderInfoView: View {
    let group: BranchGroup
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: group.info.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(group.info.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
            }
            Spacer()
        }
    }
}

// MARK: - Group Interaction Buttons View
struct GroupInteractionButtonsView: View {
    let group: BranchGroup
    @ObservedObject var viewModel: GroupViewModel
    @Binding var showingStoryInfo: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            InteractionButton(
                icon: group.info.currentUserStatus.isFollowed ? "bell.fill" : "bell",
                count: Int(group.info.profile.groupFollowerNum),
                isActive: group.info.currentUserStatus.isFollowed,
                action: {
                    Task {
                        await handleFollowAction()
                    }
                }
            )
            
            InteractionButton(
                icon: "book",
                count: Int(group.info.profile.groupStoryNum),
                isActive: false,
                action: {
                    showingStoryInfo = true
                }
            )
            
            InteractionButton(
                icon: "person",
                count: Int(group.info.profile.groupMemberNum),
                isActive: false,
                action: {}
            )
        }
        .padding(.top, 4)
    }
    
    private func handleFollowAction() async {
        if group.info.currentUserStatus.isFollowed {
            let err = await viewModel.unfollowGroup(
                userId: viewModel.user.userID,
                groupId: group.info.groupID
            )
            if err == nil {
                group.info.currentUserStatus.isFollowed = false
                group.info.profile.groupFollowerNum -= 1
            }
        } else {
            let err = await viewModel.followGroup(
                userId: viewModel.user.userID,
                groupId: group.info.groupID
            )
            if err == nil {
                group.info.currentUserStatus.isFollowed = true
                group.info.profile.groupFollowerNum += 1
            }
        }
    }
}

// MARK: - Group Story Info Overlay
struct GroupStoryInfoOverlay: View {
    let groupName: String
    let storyCount: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            GroupStoryInfoView(
                groupName: groupName,
                storyCount: storyCount,
                isPresented: $isPresented
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Utility Views
struct CategoryTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color.theme.accent : Color.theme.tertiaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.theme.accent.opacity(0.1) : Color.clear)
                .cornerRadius(16)
        }
    }
}

struct GroupStoryInfoView: View {
    let groupName: String
    let storyCount: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            GroupStoryInfoHeaderView(groupName: groupName, isPresented: $isPresented)
            GroupStoryInfoContentView(storyCount: storyCount)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.theme.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct GroupStoryInfoHeaderView: View {
    let groupName: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            Text(groupName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.theme.primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .frame(height: 44)
        .background(Color.theme.secondaryBackground)
    }
}

struct GroupStoryInfoContentView: View {
    let storyCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.theme.accent)
                
                Text("故事数量：\(storyCount)")
                    .font(.system(size: 18))
                    .foregroundColor(.theme.primaryText)
            }
            .padding(.top, 24)
            
            Text("这个小组目前已经创作了 \(storyCount) 个精彩故事")
                .font(.system(size: 14))
                .foregroundColor(.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}


