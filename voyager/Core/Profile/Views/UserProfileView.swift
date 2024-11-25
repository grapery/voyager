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
                    
                    TabView(selection: $selectedFilter) {
                        StoryboardRowView(boards: self.viewModel.storyboards)
                            .tag(UserProfileFilterViewModel.storyboards)
                        
                        RolesListView(roles: self.viewModel.storyRoles)
                            .tag(UserProfileFilterViewModel.roles)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: selectedFilter) { newValue in
                        Task {
                            await loadFilteredContent(for: newValue)
                        }
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
        defer {
            isLoading = false
            print("")
        }
        
        do {
            switch filter {
            case .storyboards:
                // 调用获取用户创建的故事的 API
                Task{
                    let result = try! await viewModel.fetchUserCreatedStoryboards(userId: user.userID, groupId: 0, storyId: 0)
                    
                    self.viewModel.storyboards = result.0!
                    print("self.viewModel.storyboards : ",self.viewModel.storyboards)
                }
                
                
            case .roles:
                // 调用获取用户参与的故事的 API
                Task{
                    let result = try! await viewModel.fetchUserCreatedStoryRoles(userId: user.userID, groupId: 0, storyId: 0)
                    
                    self.viewModel.storyRoles = result.0!
                    print("self.viewModel.storyRoles : ",self.viewModel.storyRoles)
                    
                }
                
            }
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
        VStack(alignment: .center){
            Text("StoryRole")
        }
    }
}

struct StoryboardRowView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(boards, id: \.id) { role in
                StoryboardRowCellView()
                    .padding(.horizontal)
            }
        }
    }
}

struct StoryboardRowCellView: View{
    var body: some View{
        VStack(alignment: .center){
            Text("Storyboard")
        }
    }
}
