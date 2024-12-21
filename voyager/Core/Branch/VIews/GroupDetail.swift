//
//  GroupDetail.swift
//  voyager
//
//  Created by grapestree on 2024/9/30.
//

import SwiftUI
import Kingfisher
import Combine

struct GroupDetailView: View {
    var user: User
    var currentUser: User
    @State var group: BranchGroup?
    @State var naviItemPressed: Bool = false
    @State var showNewStoryView: Bool = false
    @State var showDelStoryView: Bool = false
    
    @State var viewModel: GroupDetailViewModel
    @State private var selectedTab = 0
    @State private var showUpdateGroupView = false
    @State private var needsRefresh = false
    @State private var isRefreshing = false

    init(user: User, group: BranchGroup) {
        self.user = user
        self.currentUser = user
        self.group = group
        self.viewModel = GroupDetailViewModel(user: user, groupId: (group.info.groupID))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Group Info Header
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink(destination: UpdateGroupView(group: self.group!, userId: self.user.userID)) {
                    HStack(spacing: 12) {
                        KFImage(URL(string: group!.info.avatar))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group!.info.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("成员: \(10)") // 可以添加实际成员数
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await self.viewModel.JoinGroup(groupdId: self.viewModel.groupId)
                            }
                        }) {
                            Text("已加入")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                if !group!.info.desc.isEmpty {
                    Text(group!.info.desc)
                        .font(.system(size: 15))
                        .lineLimit(3)
                        .padding(.vertical, 8)
                }
            }
            .padding(8)
            .background(Color.white)
            
            // Custom Tab View
            CustomTabView(selectedTab: $selectedTab)
                .padding(.vertical, 8)
            Divider()
            
            // Story List
            if selectedTab == 0 {
                ScrollView {
                    RefreshControl(isRefreshing: $isRefreshing) {
                        await viewModel.fetchGroupStorys(groupdId: group!.info.groupID)
                        isRefreshing = false
                    }
                    
                    if viewModel.storys.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("暂无关注的故事")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.storys) { story in
                                NavigationLink(destination: StoryView(story: story, userId: self.user.userID)) {
                                    StoryCellView(story: story, userId: self.user.userID, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else if selectedTab == 1 {
                ScrollView {
                    RefreshControl(isRefreshing: $isRefreshing) {
                        await viewModel.fetchGroupStorys(groupdId: group!.info.groupID)
                        isRefreshing = false
                    }
                    
                    if viewModel.storys.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("暂无最新故事")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.storys.sorted { $0.storyInfo.ctime > $1.storyInfo.ctime }) { story in
                                NavigationLink(destination: StoryView(story: story, userId: self.user.userID)) {
                                    StoryCellView(story: story, userId: self.user.userID, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarItems(trailing: HStack(spacing: 8) {
            Button(action: {
                naviItemPressed = true
                showNewStoryView = true
                needsRefresh = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Button(action: {
                naviItemPressed = true
                showDelStoryView = true
                needsRefresh = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        })
        .sheet(isPresented: $naviItemPressed) {
            if showNewStoryView{
                NewStoryView(groupId:(self.group?.info.groupID)!,userId: self.user.userID).onDisappear(){
                    Task{
                        showNewStoryView = false
                        await viewModel.fetchGroupStorys(groupdId:(self.group?.info.groupID)! )
                    }
                }
            }else if showDelStoryView{
                DeleteGroupView(group:self.group!).onDisappear(){
                    Task{
                        showDelStoryView = false
                        await viewModel.fetchGroupStorys(groupdId:(self.group?.info.groupID)! )
                    }
                }
            }
            
        }
        .onChange(of: needsRefresh) { _ in
            if needsRefresh {
                Task {
                    await viewModel.fetchGroupStorys(groupdId: group!.info.groupID)
                    needsRefresh = false
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchGroupStorys(groupdId: group!.info.groupID)
            }
        }
    }
}
 


struct CustomTabView: View {
    @Binding var selectedTab: Int
    let tabs = ["关注", "最近"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<tabs.count) { index in
                    Button(action: {
                        withAnimation { selectedTab = index }
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? .primary : .gray)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                                .animation(.spring(), value: selectedTab)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct StoryCellView: View {
    let story: Story
    var userId: Int64
    var currentUserId: Int64
    var viewModel: GroupDetailViewModel
    
    init(story: Story, userId: Int64, viewModel: GroupDetailViewModel) {
        self.story = story
        self.userId = userId
        self.currentUserId = userId
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                KFImage(URL(string: story.storyInfo.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                HStack {
                    Text(story.storyInfo.name)
                        .font(.headline)
                    Spacer()
                    Text(formatDate(timestamp: story.storyInfo.ctime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
            }
            
            Text(story.storyInfo.origin)
                .font(.body)
            
            KFImage(URL(string: story.storyInfo.avatar))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(8)
            
            HStack {
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.watchStory(storyId: self.story.storyInfo.id, userId: self.currentUserId)
                    }
                }) {
                    HStack {
                        Image(systemName: "bell.circle")
                            .font(.headline)
                        Text("订阅")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.likeStory(userId: self.currentUserId, storyId: story.storyInfo.id)
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.circle")
                            .font(.headline)
                        Text("点赞")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                Button(action: {
                    print("share story")
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.circle")
                            .font(.headline)
                        Text("分享")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
    }
}

func formatDate(timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// 添加 RefreshControl 组件
struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                Spacer()
                    .onAppear {
                        guard !isRefreshing else { return }
                        isRefreshing = true
                        Task {
                            await action()
                        }
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
        }
        .frame(height: 5)
    }
}
