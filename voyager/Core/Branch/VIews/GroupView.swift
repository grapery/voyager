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
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: GroupViewModel(user: user))
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 使用通用导航栏
                CommonNavigationBar(
                    title: "小组",
                    onAddTapped: {
                        isShowingNewGroupView = true
                    }
                )
                
                // 使用通用搜索栏
                CommonSearchBar(
                    searchText: $searchText,
                    placeholder: "搜索小组"
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("我的小组")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color.theme.primaryText)
                            Spacer()
                            NavigationLink {
                                AllGroupsView(viewModel: viewModel)
                            } label: {
                                Text("查看全部")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.groups) { group in
                                VStack(spacing: 0) {
                                    GroupDiscussionCell(group: group, viewModel: viewModel)
                                    
                                    if group.id != viewModel.groups.last?.id {
                                        Divider()
                                            .background(Color.theme.divider)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical)
                }
                .background(Color.theme.background)
            }
            .sheet(isPresented: $isShowingNewGroupView) {
                NewGroupView(userId: viewModel.user.userID, viewModel: viewModel)
            }
            .onAppear {
                Task {
                    await viewModel.fetchGroups()
                }
            }
            .background(Color.theme.background)
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
                .foregroundColor(isSelected ? Color.theme.accent : Color.theme.tertiaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.theme.accent.opacity(0.1) : Color.clear)
                .cornerRadius(16)
        }
    }
}

// 优化后的网格项视图
struct GroupGridItemView: View {
    @State public var group: BranchGroup
    @ObservedObject private var viewModel: GroupViewModel
    
    init(group: BranchGroup, viewModel: GroupViewModel) {
        self.group = group
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationLink(destination: GroupDetailView(user: self.viewModel.user, group: self.group)) {
            VStack(alignment: .leading, spacing: 12) {
                // 头部区域
                HStack(spacing: 12) {
                    // 头像
                    KFImage(URL(string: group.info.avatar))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                    
                    // 名称和成员数
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.info.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                            .lineLimit(1)
                        
                        Text("\(999) 成员")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                }
                
                // 描述文本
                if !group.info.desc.isEmpty {
                    Text(group.info.desc)
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(width: 240)
            .padding(16)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.theme.border, lineWidth: 1)
            )
            .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GroupDiscussionCell: View {
    let group: BranchGroup
    @ObservedObject var viewModel: GroupViewModel
    @State private var showGroupDetail = false
    
    var body: some View {
        Button(action: {
            showGroupDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 头部信息
                HStack(spacing: 12) {
                    KFImage(URL(string: group.info.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.info.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        Text("成员: \(999)")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    
                    Spacer()
                }
                
                // 描述内容
                if !group.info.desc.isEmpty {
                    Text(group.info.desc)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.secondaryText)
                        .lineLimit(2)
                }
                
                // 更新互动栏实现
                HStack(spacing: 24) {
                    InteractionButton(
                        icon: "bell",
                        count: 20,
                        isActive: false,
                        action: {
                            Task{
                                print("send sub request")
                                await self.viewModel.followGroup(userId: self.viewModel.user.userID, groupId: self.group.info.groupID)
                            }
                        }
                    )
                    
                    InteractionButton(
                        icon: "bubble.left",
                        count: 30,
                        isActive: false,
                        action: { 
                            print("Comment tapped")
                        }
                    )
                    
                    InteractionButton(
                        icon: "heart",
                        count: 40,
                        isActive: false,
                        action: {
                            print("Heart tapped")
                            Task{
                                print("send like request")
                                await viewModel.likeGroup(userId: self.viewModel.user.userID, groupId: self.group.info.groupID)
                            }
                        }
                    )
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.theme.tertiaryText)
                            .font(.system(size: 14))
                    }
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.theme.secondaryBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showGroupDetail) {
            NavigationStack {
                GroupDetailView(user: self.viewModel.user, group: group)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showGroupDetail = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(Color.theme.primaryText)
                            }
                        }
                    }
            }
        }
    }
}


