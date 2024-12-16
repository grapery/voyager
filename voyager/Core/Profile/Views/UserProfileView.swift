//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

// MARK: - Main View
struct UserProfileView: View {
    @State private var selectedFilter: UserProfileFilterViewModel = .storyboards
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    @State private var showingSubView = false
    @State private var backgroundImage: UIImage?
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    UserProfileHeaderView(
                        user: user,
                        backgroundImage: backgroundImage,
                        onLongPress: handleHeaderLongPress
                    )
                    
                    FilterTabBar(
                        selectedFilter: $selectedFilter,
                        animation: animation
                    )
                    
                    ProfileContentView(
                        selectedFilter: selectedFilter,
                        dragOffset: dragOffset,
                        viewModel: viewModel,
                        onFilterChange: { filter in
                            withAnimation {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSettingsButton(action: handleSettingsPress)
                }
            }
            .sheet(isPresented: $showingSubView) {
                ProfileSheetContent(
                    showingEditProfile: showingEditProfile,
                    showingImagePicker: showingImagePicker,
                    user: user,
                    backgroundImage: $backgroundImage,
                    onDismiss: handleSheetDismiss
                )
            }
            .background(Color(.systemBackground))
            .refreshable { await refreshData() }
            .task { await loadUserData() }
            .onChange(of: selectedFilter) { newValue in
                Task {
                    await loadFilteredContent(for: newValue)
                }
            }
        }
    }
    
    // MARK: - Action Handlers
    private func handleHeaderLongPress() {
        showingSubView = true
        showingImagePicker = true
    }
    
    private func handleSettingsPress() {
        showingSubView = true
        showingEditProfile = true
    }
    
    private func handleSheetDismiss() {
        showingSubView = false
        showingEditProfile = false
        showingImagePicker = false
    }
    
    // MARK: - Data Loading Methods
    private func refreshData() async {
        await loadFilteredContent(for: selectedFilter, forceRefresh: true)
    }
    
    private func loadUserData() async {
        if viewModel.profile.userID == 0 {
            viewModel.profile = await viewModel.fetchUserProfile()
        }
        await loadFilteredContent(for: selectedFilter)
    }
    
    private func loadFilteredContent(for filter: UserProfileFilterViewModel, forceRefresh: Bool = false) async {
        do {
            switch filter {
            case .storyboards:
                if viewModel.storyboards.isEmpty || forceRefresh {
                    let (boards, _) = try await viewModel.fetchUserCreatedStoryboards(
                        userId: user.userID,
                        groupId: 0,
                        storyId: 0
                    )
                    if let boards = boards {
                        await MainActor.run {
                            viewModel.storyboards = boards
                        }
                    }
                }
                
            case .roles:
                if viewModel.storyRoles.isEmpty || forceRefresh {
                    let (roles, _) = try await viewModel.fetchUserCreatedStoryRoles(
                        userId: user.userID,
                        groupId: 0,
                        storyId: 0
                    )
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

// MARK: - Profile Header View
private struct UserProfileHeaderView: View {
    let user: User
    let backgroundImage: UIImage?
    let onLongPress: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            BackgroundImageView(image: backgroundImage)
            
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
            
            VStack(spacing: 16) {
                UserInfoHeader(user: user)
                ProfileStatsRow(viewModel: ProfileViewModel(user: user))
            }
            .padding(16)
        }
        .onLongPressGesture(perform: onLongPress)
    }
}

// MARK: - Background Image View
private struct BackgroundImageView: View {
    let image: UIImage?
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 280)
        }
    }
}

// MARK: - User Info Header
private struct UserInfoHeader: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            CircularProfileImageView(avatarUrl: user.avatar, size: .InProfile)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(user.desc.isEmpty ? "神秘的人物，没有简介！" : user.desc)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            Spacer()
        }
    }
}

// MARK: - Profile Stats Row
private struct ProfileStatsRow: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        HStack(spacing: 32) {
            StatView(
                icon: "mountain.2",
                count: Int64(viewModel.profile.createdStoryNum),
                title: "个故事"
            )
            
            StatView(
                icon: "person",
                count: Int64(viewModel.profile.createdRoleNum),
                title: "个故事角色"
            )
        }
    }
}

// MARK: - Filter Tab Bar
private struct FilterTabBar: View {
    @Binding var selectedFilter: UserProfileFilterViewModel
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(UserProfileFilterViewModel.allCases, id: \.self) { filter in
                TabButton(
                    title: filter.title,
                    isSelected: selectedFilter == filter
                ) {
                    withAnimation {
                        selectedFilter = filter
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Profile Content View
private struct ProfileContentView: View {
    let selectedFilter: UserProfileFilterViewModel
    let dragOffset: CGFloat
    let viewModel: ProfileViewModel
    let onFilterChange: (UserProfileFilterViewModel) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                StoryboardRowView(boards: viewModel.storyboards)
                    .frame(width: geometry.size.width)
                
                RolesListView(roles: viewModel.storyRoles, viewModel: viewModel)
                    .frame(width: geometry.size.width)
            }
            .offset(x: -CGFloat(selectedFilter.rawValue) * geometry.size.width)
            .offset(x: dragOffset)
            .animation(.interactiveSpring(), value: selectedFilter)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold = geometry.size.width * 0.25
                        if value.translation.width > threshold && selectedFilter != .storyboards {
                            onFilterChange(.storyboards)
                        } else if value.translation.width < -threshold && selectedFilter != .roles {
                            onFilterChange(.roles)
                        }
                    }
            )
        }
        .frame(height: UIScreen.main.bounds.height * 0.7)
    }
}

// MARK: - Profile Sheet Content
private struct ProfileSheetContent: View {
    let showingEditProfile: Bool
    let showingImagePicker: Bool
    let user: User
    @Binding var backgroundImage: UIImage?
    let onDismiss: () -> Void
    
    var body: some View {
        Group {
            if showingEditProfile {
                EditUserProfileView(user: user)
            } else if showingImagePicker {
                SingleImagePicker(image: $backgroundImage)
            }
        }
        .onDisappear(perform: onDismiss)
    }
}

// MARK: - Profile Settings Button
private struct ProfileSettingsButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.white)
        }
    }
}

// MARK: - Existing Supporting Views
// Keep the existing StatView, StoryCardRowView, RolesListView, etc.
// ... (rest of the supporting view implementations remain unchanged)

// MARK: - Stat View
struct StatView: View {
    let icon: String
    let count: Int64
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Text("\(count) \(title)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Storyboard Row View
struct StoryboardRowView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(boards, id: \.id) { board in
                    StoryboardRowCellView(info: board)
                }
            }
            .padding()
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
                ProfileInteractionButton(icon: "bubble.left", count: 0, isActive: false)
                ProfileInteractionButton(icon: "heart", count: 0, isActive: false)
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

// MARK: - Roles List View
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
            .padding()
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
            HStack(alignment: .top, spacing: 5) {
                // Avatar
                if !role.role.characterAvatar.isEmpty {
                    RectProfileImageView(avatarUrl: role.role.characterAvatar, size: .InProfile2)
                } else {
                    RectProfileImageView(avatarUrl: defaultAvator, size: .InProfile2)
                }
                
                // Right side content
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.role.characterName)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(3)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("\(10) 故事板")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .foregroundColor(.gray)
                            Text("\(10) 消息")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
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

// MARK: - Interaction Button
struct ProfileInteractionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text("\(count)")
                    .font(.system(size: 14))
            }
            .foregroundColor(isActive ? .blue : .gray)
        }
    }
}
