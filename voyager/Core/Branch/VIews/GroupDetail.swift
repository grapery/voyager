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
    @Binding var group: BranchGroup?
    @State var showNewStoryView: Bool = false
    @State var viewModel: GroupDetailViewModel
    @State private var selectedTab = 0
    
    init(user: User, group: Binding<BranchGroup?>) {
        self.user = user
        self._group = group
        self.viewModel = GroupDetailViewModel(user: user, groupId: (group.wrappedValue?.info.groupID)!)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Group Info Header
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    KFImage(URL(string: group!.info.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(group!.info.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    Spacer()
                    
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
                }
                
                Text(group!.info.desc)
                    .font(.subheadline)
                    .lineLimit(3)
            }
            .padding()
            .background(Color.white)
            
            
            // Tab View
            CustomTabView(selectedTab: $selectedTab)
            
            // Story List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.storys) { story in
                        NavigationLink(destination: StoryView(storyId: story.storyInfo.id, userId: self.user.userID)) {
                            StoryCellView(story: story)
                        }
                    }
                }
            }
        }
        .navigationBarItems(trailing: 
            Button(action: {
                showNewStoryView = true
            }) {
                Image(systemName: "plus")
            }
        )
        .sheet(isPresented: $showNewStoryView) {
            NewStoryView(groupId:(self.group?.info.groupID)!,userId: self.user.userID).onDisappear(){
                Task{
                    showNewStoryView = false
                    await viewModel.fetchGroupStorys(groupdId:(self.group?.info.groupID)! )
                }
            }
        }
    }
}
 


struct CustomTabView: View {
    @Binding var selectedTab: Int
    let tabs = ["关注", "最近","参与"]
    
    var body: some View {
        HStack {
            Spacer().padding(.horizontal, 2)
            ForEach(0..<tabs.count) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tabs[index])
                        .foregroundColor(selectedTab == index ? .black : .gray)
                        .padding(.vertical, 8)
                }
                Spacer().padding(.horizontal, 2)
            }
        }
        .padding(.horizontal)
    }
}

struct StoryCellView: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                KFImage(URL(string: story.storyInfo.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(story.storyInfo.name)
                        .font(.headline)
                    Text(String(story.storyInfo.ctime))
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
                Button(action: {}) {
                    Image(systemName: "bubble.left")
                    Text("\(story.storyInfo.desc)")
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "heart")
                    Text("\(10)")
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享")
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
