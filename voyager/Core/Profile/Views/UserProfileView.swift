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
                            Image(systemName: "mountain.2")
                                .foregroundColor(.blue)
                            Text("创建 \(viewModel.profile.createdStoryNum) 个故事")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }
                        VStack{
                            Image(systemName: "poweroutlet.type.k")
                                .foregroundColor(.gray)
                            Text("创建 \(viewModel.profile.createdRoleNum) 个故事角色")
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
                            .gesture(DragGesture().onChanged { _ in })
                        
                        RolesListView(roles: self.viewModel.storyRoles)
                            .tag(UserProfileFilterViewModel.roles)
                            .gesture(DragGesture().onChanged { _ in })
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.height * 0.7)
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
        .refreshable {
            await loadFilteredContent(for: selectedFilter, forceRefresh: true)
        }
    }
    private func loadFilteredContent(for filter: UserProfileFilterViewModel, forceRefresh: Bool = false) async {
        do {
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
