//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

struct UserProfileView: View {
    @State private var selectedFilter: UserProfileFilterViewModel = .storyboards
    @State private var showingEditProfile = false
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ProfileHeaderView(user: user)
                    ProfileDescriptionView(description: user.desc)
                    ProfileStatsView(
                        storyCount: Int(viewModel.profile.createdStoryNum),
                        roleCount: Int(viewModel.profile.createdRoleNum)
                    )
                    
                    Divider()
                    
                    ProfileFilterView(selectedFilter: $selectedFilter)
                    
                    TabView(selection: $selectedFilter) {
                        StoryboardRowView(boards: viewModel.storyboards)
                            .tag(UserProfileFilterViewModel.storyboards)
                            .padding(.horizontal, 1)
                        
                        RolesListView(roles: viewModel.storyRoles, viewModel: self.viewModel)
                            .tag(UserProfileFilterViewModel.roles)
                            .padding(.horizontal, 1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.height * 0.7)
                    .onChange(of: selectedFilter) { newValue in
                        Task {
                            await loadFilteredContent(for: newValue)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile.toggle()
                    } label: {
                        Image(systemName: "slider.vertical.3")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditUserProfileView(user: user)
        }
        .refreshable {
            await loadFilteredContent(for: selectedFilter, forceRefresh: true)
        }
    }
    
    private func loadFilteredContent(for filter: UserProfileFilterViewModel, forceRefresh: Bool = false) async {
        do {
            if viewModel.profile.userID == 0 {
                viewModel.profile = await viewModel.fetchUserProfile()
            }
            switch filter {
            case .storyboards:
                if viewModel.storyboards.isEmpty || forceRefresh {
                    let (boards, _) = try await viewModel.fetchUserCreatedStoryboards(userId: user.userID, groupId: 0, storyId: 0)
                    if let boards = boards {
                        await MainActor.run {
                            viewModel.storyboards = boards
                        }
                    }
                }
                
            case .roles:
                if viewModel.storyRoles.isEmpty || forceRefresh {
                    let (roles, _) = try await viewModel.fetchUserCreatedStoryRoles(userId: user.userID, groupId: 0, storyId: 0)
                    if let roles = roles {
                        await MainActor.run {
                            viewModel.storyRoles = roles
                        }
                    }
                }
            }
        } catch {
            print("Error loading filtered content: \(error)")
        }
    }
}

struct StoriesGridView: View {
    let stories: [Story]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(stories, id: \.id) { story in
                StoryCardRowView()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding()
    }
}

struct StoryCardRowView: View{
    var body: some View{
        VStack(alignment: .center){
           Text("Story")
        }
    }
}
    
struct RolesListView: View {
    let roles: [StoryRole]
    var viewModel: ProfileViewModel
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(roles, id: \.id) { role in
                    StoryRoleRowView(role: role,viewModel: viewModel, userId: viewModel.user!.userID)
                        .padding(.horizontal, 4)
                }
            }
        }
        .simultaneousGesture(DragGesture().onChanged { _ in })
    }
}

struct StoryRoleRowView: View {
    var role: StoryRole
    @State private var showRoleDetail = false
    var viewModel: ProfileViewModel
    let userId: Int64
    
    var body: some View {
        HStack(spacing: 12) {
            // 头像
            if !role.role.characterAvatar.isEmpty {
                RectProfileImageView(avatarUrl: role.role.characterAvatar, size: .profile)
            }else{
                RectProfileImageView(avatarUrl: defaultAvator, size: .profile)
            }
            
            // 名称和描述
            VStack(alignment: .leading, spacing: 4) {
                Text(role.role.characterName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(role.role.characterDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onTapGesture {
            showRoleDetail = true
        }
        .sheet(isPresented: $showRoleDetail) {
            StoryRoleDetailView(
                storyId: role.role.storyID,
                roleId: role.role.roleID,
                userId: self.userId,
                role: self.role
            )
        }
    }
}

struct StoryboardRowView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(boards, id: \.id) { board in
                    StoryboardRowCellView(info: board)
                        .padding(.horizontal, 4)
                }
            }
        }
        .simultaneousGesture(DragGesture().onChanged { _ in })
    }
}

struct StoryboardRowCellView: View {
    var info: StoryBoard
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 标题和AI标记
            HStack {
                Text(info.boardInfo.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if info.boardInfo.isAiGen {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("#\(info.boardInfo.num)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 内容预览
            Text(info.boardInfo.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 角色信息
            if !info.boardInfo.roles.isEmpty {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    Text("\(info.boardInfo.roles.count) 个角色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
