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
                VStack(alignment: .leading, spacing: 16) {
                    // Profile Header Card
                    VStack(spacing: 16) {
                        ProfileHeaderView(user: user)
                        ProfileDescriptionView(description: user.desc)
                        ProfileStatsView(
                            storyCount: Int(viewModel.profile.createdStoryNum),
                            roleCount: Int(viewModel.profile.createdRoleNum)
                        )
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                    
                    // Filter View
                    ProfileFilterView(selectedFilter: $selectedFilter)
                        .padding(.vertical, 8)
                    
                    // Content TabView
                    TabView(selection: $selectedFilter) {
                        StoryboardRowView(boards: viewModel.storyboards)
                            .tag(UserProfileFilterViewModel.storyboards)
                        
                        RolesListView(roles: viewModel.storyRoles, viewModel: self.viewModel)
                            .tag(UserProfileFilterViewModel.roles)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.height * 0.7)
                    .onChange(of: selectedFilter) { newValue in
                        Task {
                            await loadFilteredContent(for: newValue)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile.toggle()
                    } label: {
                        Image(systemName: "slider.vertical.3")
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
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
            LazyVStack(spacing: 16) {
                ForEach(roles, id: \.id) { role in
                    StoryRoleRowView(role: role, viewModel: viewModel, userId: viewModel.user!.userID)
                }
            }
        }
    }
}

struct StoryRoleRowView: View {
    var role: StoryRole
    @State private var showRoleDetail = false
    var viewModel: ProfileViewModel
    let userId: Int64
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Avatar
                    if !role.role.characterAvatar.isEmpty {
                        RectProfileImageView(avatarUrl: role.role.characterAvatar, size: .InProfile)
                    } else {
                        RectProfileImageView(avatarUrl: defaultAvator, size: .InProfile)
                    }
                    
                    // Name and Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role.role.characterName)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(role.role.characterDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                // Interaction buttons
                HStack(spacing: 24) {
                    InteractionButton(icon: "bubble.left", count: 0, isActive: false)
                    InteractionButton(icon: "heart", count: 0, isActive: false)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
            LazyVStack(spacing: 16) {
                ForEach(boards, id: \.id) { board in
                    StoryboardRowCellView(info: board)
                }
            }
        }
    }
}

struct StoryboardRowCellView: View {
    var info: StoryBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(info.boardInfo.title)
                    .font(.system(size: 16, weight: .semibold))
                
                if info.boardInfo.isAiGen {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("#\(info.boardInfo.num)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Content
            Text(info.boardInfo.content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Footer
            if !info.boardInfo.roles.isEmpty {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    Text("\(info.boardInfo.roles.count) 个角色")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            // Interaction buttons
            HStack(spacing: 24) {
                InteractionButton(icon: "bubble.left", count: 0, isActive: false)
                InteractionButton(icon: "heart", count: 0, isActive: false)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}
