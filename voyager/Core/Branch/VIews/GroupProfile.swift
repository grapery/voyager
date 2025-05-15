//
//  GroupProfile.swift
//  voyager
//
//  Created by grapestree on 2024/9/30.
//

import SwiftUI
import Kingfisher
import Combine
import ActivityIndicatorView

struct GroupProfileTabBar: View {
    @Binding var selectedTab: Int
    var body: some View {
        HStack {
            Button(action: { selectedTab = 0 }) {
                VStack {
                    Text("群组信息")
                        .font(.headline)
                        .foregroundColor(selectedTab == 0 ? .blue : .gray)
                    Rectangle()
                        .fill(selectedTab == 0 ? Color.blue : Color.clear)
                        .frame(height: 2)
                }
            }
            .frame(maxWidth: .infinity)
            Button(action: { selectedTab = 1 }) {
                VStack {
                    Text("成员列表")
                        .font(.headline)
                        .foregroundColor(selectedTab == 1 ? .blue : .gray)
                    Rectangle()
                        .fill(selectedTab == 1 ? Color.blue : Color.clear)
                        .frame(height: 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .padding(.top, 8)
    }
}

struct GroupInfoTab: View {
    let group: BranchGroup
    let onQuit: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("群组名称：\(group.info.name)")
                    .font(.title2)
                    .padding(.top, 16)
                Text("群组公告：\(group.info.desc)")
                    .font(.body)
                Text("群组描述：\(group.info.desc)")
                    .font(.body)
                Spacer(minLength: 20)
                Button(action: onQuit) {
                    Text("退出小组")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.top, 40)
            }
            .padding(.horizontal, 20)
        }
    }
}


struct GroupMembersTab: View {
    let members: [Common_GroupMemberInfo]
    let isLoadingMore: Bool
    let hasMore: Bool
    let loadMore: () -> Void
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(members, id: \ .userID) { member in
                    VStack(spacing: 4) {
                        KFImage(URL(string: convertImagetoSenceImage(url: member.avatar, scene: .small)))
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                        Text(member.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            if hasMore {
                Button(action: loadMore) {
                    if isLoadingMore {
                        ProgressView()
                    } else {
                        Text("点击加载更多")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
    }
}

struct GroupProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var members: [Common_GroupMemberInfo] = []
    @State private var isLoadingMore = false
    @State private var hasMore = true
    let group: BranchGroup
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                GroupProfileTabBar(selectedTab: $selectedTab)
                Divider()
                if selectedTab == 0 {
                    GroupInfoTab(group: group) {
                        // 退出小组逻辑
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    GroupMembersTab(members: members, isLoadingMore: isLoadingMore, hasMore: hasMore, loadMore: loadMoreMembers)
                }
            }
            .navigationTitle("群组设置")
            .navigationBarItems(leading: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    private func loadMoreMembers() {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        // 模拟异步加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // 加载更多成员逻辑
            // 更新 members 和 hasMore
            isLoadingMore = false
        }
    }
}
