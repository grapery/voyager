//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

struct UserProfileView: View {
    @State private var selectedFilter: UserProfileFilterViewModel = .storys
    @State private var showingEditProfile = false
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    @State private var stories: [Story] = []
    @State private var groups: [BranchGroup] = []
    @State private var roles: [StoryRole] = []
    @State private var isLoading = false
    init(user: User) {
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
                    
                    HStack{
                        VStack{
                            Text("加入 \(viewModel.profile.numGroup) 个群组")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 5)
                            Spacer()
                        }
                        VStack{
                            Text("参与 \(viewModel.profile.contributStoryNum) 个故事")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 5)
                            Spacer()
                        }
                        VStack{
                            Text("创建 \(viewModel.profile.createdStoryNum) 个故事")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 5)
                            Spacer()
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
                    
                    switch selectedFilter {
                    case .storys:
                        StoriesGridView(stories: stories)
                    case .groups:
                        GroupsListView(groups: groups)
                    case .roles:
                        RolesListView(roles: roles)
                    }
                }
                .padding()
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
    }
    private func loadFilteredContent(for filter: UserProfileFilterViewModel) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch filter {
            case .storys:
                // 调用获取用户创建的故事的 API
                let result = try! await viewModel.fetchUserStories(userId: user.userID)
                await MainActor.run {
                    stories = result.0!
                }
                
            case .groups:
                // 调用获取用户加入的群组的 API
                let result = try! await viewModel.fetchUserGroups(userId: user.userID)
                await MainActor.run {
                    groups = result.0!
                }
                
            case .roles:
                // 调用获取用户参与的故事的 API
                let result = try! await viewModel.fetchUserStoryRoles(userId: user.userID)
                await MainActor.run {
                    roles = result.0!
                }
            }
        } catch {
            print("Error loading content: \(error)")
            // 这里可以添加错误处理逻辑
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
        VStack{
            
        }
    }
}
    

struct GroupsListView: View {
    let groups: [BranchGroup]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(groups, id: \.id) { group in
                GroupRowView()
                    .padding(.horizontal)
            }
        }
    }
}

struct GroupRowView: View{
    var body: some View{
        VStack{
            
        }
    }
}

struct RolesListView: View {
    let roles: [StoryRole]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(roles, id: \.id) { role in
                StoryRoleRowView()
                    .padding(.horizontal)
            }
        }
    }
}

struct StoryRoleRowView: View{
    var body: some View{
        VStack{
            
        }
    }
}
