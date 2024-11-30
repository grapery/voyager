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
    @State private var isLoading = false
    init(user: User) {
        print("user :", user)
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .foregroundColor(.primary)
                                .font(.title)
                                .bold()
                            
                            Text(user.desc)
                                .font(.subheadline)
                        }
                        Spacer()
                        CircularProfileImageView(avatarUrl: user.avatar.isEmpty ? defaultAvator : user.avatar, size: .profile)
                    }
                    VStack{
                        HStack{
                            Image(systemName: "mountain.2")
                                .foregroundColor(.blue)
                            Text("\(viewModel.profile.createdStoryNum) 个故事")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }
                        HStack{
                            Image(systemName: "poweroutlet.type.k")
                                .foregroundColor(.gray)
                            Text("\(viewModel.profile.createdRoleNum) 个故事角色")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }
                    }
                    Divider()
                    HStack {
                        ForEach(UserProfileFilterViewModel.allCases, id: \.rawValue) { item in
                            VStack {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == item ? .semibold : .regular)
                                    .foregroundColor(selectedFilter == item ? .primary : .secondary)
                                
                                Capsule()
                                    .foregroundColor(selectedFilter == item ? .primary : .secondary)
                                    .frame(height: 3)
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedFilter = item
                                    Task {
                                        await loadFilteredContent(for: item)
                                    }
                                }
                            }
                        }
                    }
                    .overlay(Divider().offset(x: 0, y: 17))
                    
                    TabView(selection: $selectedFilter) {
                        StoryboardRowView(boards: self.viewModel.storyboards)
                            .tag(UserProfileFilterViewModel.storyboards)
                            .padding(.horizontal, 1)
                        
                        RolesListView(roles: self.viewModel.storyRoles)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                    } label: {
                        Image(systemName: "gearshape.circle")
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile.toggle()
                    } label : {
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
            if self.viewModel.profile.userID == 0 {
                self.viewModel.profile = await self.viewModel.fetchUserProfile()
            }
            switch filter {
            case .storyboards:
                if self.viewModel.storyboards.isEmpty || forceRefresh {
                    let (boards, _) = try await viewModel.fetchUserCreatedStoryboards(userId: user.userID, groupId: 0, storyId: 0)
                    if let boards = boards {
                        await MainActor.run {
                            self.viewModel.storyboards = boards
                        }
                    }
                }
                
            case .roles:
                if self.viewModel.storyRoles.isEmpty || forceRefresh {
                    let (roles, _) = try await viewModel.fetchUserCreatedStoryRoles(userId: user.userID, groupId: 0, storyId: 0)
                    print("roles list info :",roles as Any)
                    if let roles = roles {
                        await MainActor.run {
                            self.viewModel.storyRoles = roles
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
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(roles, id: \.id) { role in
                    StoryRoleRowView(role: role)
                        .padding(.horizontal, 4)
                }
            }
        }
        .simultaneousGesture(DragGesture().onChanged { _ in })
    }
}

struct StoryRoleRowView: View {
    var role: StoryRole
    
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
