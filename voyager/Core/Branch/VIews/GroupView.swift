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
                VStack(spacing: 16) {
                    // 搜索栏
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("搜索小组", text: $searchText)
                                .font(.system(size: 15))
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // 我的小组标题
                    HStack {
                        Text("我的小组")
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                        NavigationLink {
                            AllGroupsView(viewModel: viewModel)
                        } label: {
                            Text("查看全部")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 小组网格
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(120))], spacing: 16) {
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
                                CategoryTabButton(
                                    title: tab,
                                    isSelected: selectedTab == tab,
                                    action: { selectedTab = tab }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 小组列表
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.groups) { group in
                            GroupDiscussionCell(group: group, viewModel: viewModel)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: 
                Button(action: { isShowingNewGroupView = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $isShowingNewGroupView) {
                NewGroupView(userId: viewModel.user.userID, viewModel: viewModel)
            }
            .onAppear {
                Task {
                    await viewModel.fetchGroups()
                }
            }
        }
    }
}

// 新增的分类标签按钮组件
struct CategoryTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .blue : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(16)
        }
    }
}

// 优化后的网项视图
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
            VStack(alignment: .center, spacing: 8) {
                KFImage(URL(string: group.info.avatar))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                Text(group.info.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text("\(999)成员")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 优化后的讨论单元格
struct GroupDiscussionCell: View {
    let group: BranchGroup
    @ObservedObject var viewModel: GroupViewModel
    @State private var showGroupDetail = false
    
    var body: some View {
        Button(action: { showGroupDetail = true }) {
            VStack(alignment: .leading, spacing: 10) {
                // 头部信息
                HStack(spacing: 10) {
                    KFImage(URL(string: group.info.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 0.5))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.info.name)
                            .font(.system(size: 15, weight: .medium))
                        Text("成员: \(999)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                // 描述内容
                if !group.info.desc.isEmpty {
                    Text(group.info.desc)
                        .font(.system(size: 14))
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
                
                // 互动栏
                HStack(spacing: 20) {
                    InteractionButton(icon: "bell", count: 20, isActive: false)
                    InteractionButton(icon: "bubble.left", count: 30, isActive: false)
                    InteractionButton(icon: "heart", count: 40, isActive: false)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showGroupDetail) {
            NavigationStack {
                GroupDetailView(user: self.viewModel.user, group: group)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showGroupDetail = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
            }
        }
    }
}
