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
    @State private var isShowingNewGroupView = false
    @State private var searchText = ""
    @State private var selectedTab = "全部"
    
    let tabs = ["全部", "都市", "传说", "鬼神", "冒险", "历史架空", "模拟live", "ACG"]
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: GroupViewModel(user: user))
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("搜索小组", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    
                    // 我的小组标题
                    HStack {
                        Text("我的小组")
                            .font(.title2)
                            .bold()
                        Spacer()
                        NavigationLink {
                            AllGroupsView(viewModel: viewModel)
                        } label: {
                            Text("全部 >")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        Task{
                            await viewModel.fetchGroups()
                        }
                    }
                    
                    // 小组网格
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(120))], spacing: 15) {
                            ForEach(viewModel.groups) { group in
                                GroupGridItemView(group: group, viewModel: self.viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 分类标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(tabs, id: \.self) { tab in
                                Text(tab)
                                    .foregroundColor(selectedTab == tab ? .green : .gray)
                                    .onTapGesture {
                                        selectedTab = tab
                                    }
                            }
                        }
                        .padding()
                    }
                    
                    // 替换 List 为 LazyVStack
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.groups) { group in
                            GroupDiscussionCell(group: group, viewModel: viewModel)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarItems(trailing: Button(action: {
                isShowingNewGroupView = true
            }) {
                Image(systemName: "plus.circle")
            })
            .sheet(isPresented: $isShowingNewGroupView) {
                NewGroupView(userId: viewModel.user.userID, viewModel: viewModel)
            }
        }
    }
}

// 网格项视图
struct GroupGridItemView: View {
    @State public var group: BranchGroup
    @State private var groupProfile: GroupProfile?
    @ObservedObject private var viewModel: GroupViewModel
    
    init(group: BranchGroup, viewModel: GroupViewModel) {
        self.group = group
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationLink(destination: GroupDetailView(user: self.viewModel.user, group: self.group)) {
            VStack(alignment: .center) {
                KFImage(URL(string: group.info.avatar))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                
                Text(group.info.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("999+")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle()) 
    }
}

// 讨论单元格
struct GroupDiscussionCell: View {
    let group: BranchGroup
    @ObservedObject var viewModel: GroupViewModel
    @State private var showGroupDetail = false
    
    init(group: BranchGroup, viewModel: GroupViewModel) {
        self.group = group
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.info.name)
                Text("・")
                Text("小组")
                Spacer()
                Text("更新时间")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(group.info.desc)
                .lineLimit(2)
            
            KFImage(URL(string: group.info.avatar))
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
        }
        .onTapGesture {
            showGroupDetail = true
        }
        .simultaneousGesture(DragGesture().onChanged { _ in })
        .fullScreenCover(isPresented: $showGroupDetail) {
            NavigationView {
                GroupDetailView(user: self.viewModel.user, group: group)
                    .navigationBarItems(leading: Button(action: {
                        showGroupDetail = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    })
            }
        }
    }
}
