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

    init(user: User, group: BranchGroup) {
        self.user = user
        self.currentUser = user
        self.group = group
        self.viewModel = GroupDetailViewModel(user: user, groupId: (group.info.groupID))
        print("group: ",group)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Group Info Header
            VStack(alignment: .leading,spacing: 8) {
                NavigationLink(destination: UpdateGroupView(group: self.group!, userId: self.user.userID)) {
                    HStack{
                        VStack(alignment: .leading) {
                            KFImage(URL(string: group!.info.avatar))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text((self.group?.info.name)!)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        Spacer().scaledToFit()
                        VStack(alignment: .trailing, spacing: 2){
                            Button(action: {
                                Task{
                                    await self.viewModel.JoinGroup(groupdId: self.viewModel.groupId)
                                }
                            }) {
                                Text("已加入")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                VStack(alignment: .leading){
                    Text(group!.info.desc)
                        .font(.body)
                        .lineLimit(3)
                }
            }
            .padding()
            .background(Color.white)
            .onTapGesture {
                showUpdateGroupView = true
            }
            
            // Tab View
            CustomTabView(selectedTab: $selectedTab)
            Divider()
            
            // Story List
            if selectedTab == 0 {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.storys) { story in
                            NavigationLink(destination: StoryView(story: story, userId: self.user.userID)) {
                                StoryCellView(story: story, userId: self.user.userID)
                            }
                        }
                    }
                }
            }else if selectedTab == 1 {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.storys) { story in
                            NavigationLink(destination: StoryView(story: story, userId: self.user.userID)) {
                                StoryCellView(story: story, userId: self.user.userID)
                            }
                        }
                    }
                }
            }else if selectedTab == 2 {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.storys) { story in
                            NavigationLink(destination: StoryView(story: story,userId: self.user.userID)) {
                                VStack{
                                    StoryCellView(story: story, userId: self.user.userID)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarItems(trailing: 
            VStack{
                Button(action: {
                    naviItemPressed = true
                    showNewStoryView = true
                    needsRefresh = true
                }) {
                    Image(systemName: "plus")
                }
            }
        )
        .navigationBarItems(trailing:
            VStack{
                Button(action: {
                    naviItemPressed = true
                    showDelStoryView = true
                    needsRefresh = true
                }) {
                    Image(systemName: "trash")
                }
            }
        )
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
    }
}
 


struct CustomTabView: View {
    @Binding var selectedTab: Int
    let tabs = ["关注","最近","标星"]
    
    var body: some View {
        HStack {
            Spacer().scaledToFit()
            ForEach(0..<tabs.count) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tabs[index])
                        .foregroundColor(selectedTab == index ? .black : .gray)
                        .padding(.vertical, 8)
                }
                Spacer().scaledToFit()
            }
        }
        .padding(.horizontal)
    }
}

struct StoryCellView: View {
    let story: Story
    var userId: Int64
    var currentUserId: Int64
    init(story: Story,userId:Int64) {
        self.story = story
        self.userId = userId
        self.currentUserId = userId
        
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bell.circle")
                            .font(.headline)
                        Text("订阅")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bubble.circle")
                            .font(.headline)
                        Text("评论")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                Button(action: {}) {
                    HStack {
                        Image(systemName: "heart.circle")
                            .font(.headline)
                        Text("点赞")
                            .font(.headline)
                    }
                    .scaledToFill()
                }
                Spacer()
                Button(action: {}) {
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
