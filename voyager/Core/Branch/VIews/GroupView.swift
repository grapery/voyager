//
//  GroupView.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import SwiftUI
import Kingfisher
import Combine

struct GroupView: View {
    @StateObject var viewModel: GroupViewModel
    @State private var isShowingNewGroupView = false  // 添加这一行
    @State private var selectedGroup: BranchGroup?  // 添加这一行

    init(user: User) {
        self._viewModel = StateObject(wrappedValue: GroupViewModel(user: user))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.groups) { group in
                    NavigationLink(destination: GroupDetailView(user: self.viewModel.user, group: Binding.constant(group))) {
                        GroupCellView(group: group, viewModel: self.viewModel)
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listStyle(PlainListStyle())
            .navigationTitle("加入的群组")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingNewGroupView = true  // 修改这里
                    }) {
                        Image(systemName: "plus.circle")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            Task{
                await viewModel.fetchGroups()
            }
        }
        .sheet(isPresented: $isShowingNewGroupView) {  // 添加这个 sheet
            NewGroupView(userId: self.viewModel.user.userID).onDisappear(){
                Task{
                    isShowingNewGroupView = false
                    await viewModel.fetchGroups()
                }
            }
            
        }
    }
}

struct GroupCellView: View {
    @State public var group: BranchGroup
    @State private var groupProfile: GroupProfile?
    @StateObject private var viewModel: GroupViewModel
    
    init(group: BranchGroup, viewModel: GroupViewModel) {
        self.group = group
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                KFImage(URL(string: self.group.info.avatar))
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
                
                Text(group.info.name)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // 更多操作
                }) {
                    Image(systemName: "ellipsis")
                }
            }
            
            // Content - Avatar Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(0..<min(1, 9), id: \.self) { index in
                    KFImage(URL(string: group.info.avatar))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                }
            }
            
            // Footer
            HStack(spacing: 4) {
                Spacer()
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bell.circle")
                            .font(.headline)
                        Text("关注")
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
            .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .onAppear {
            Task {
                await viewModel.fetchGroupProfile(groupdId: group.info.groupID)
                if let profile = viewModel.groupsProfile[group.info.groupID] {
                    self.groupProfile = profile
                }
            }
        }
    }
}
