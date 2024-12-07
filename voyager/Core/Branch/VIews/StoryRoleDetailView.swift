//
//  StoryRoleDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher


struct CharacterCell: View {
    let character: StoryRole
    var viewModel: StoryDetailViewModel
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: 2) {
            // 角色头像
            if !character.role.characterAvatar.isEmpty {
                KFImage(URL(string: character.role.characterAvatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                KFImage(URL(string: defaultAvator))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Divider()
            // 角色信息
            VStack(alignment: .leading, spacing: 8) {
                Text(character.role.characterName)
                    .font(.headline)
                
                Text(character.role.characterDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                Divider()
                // 操作按钮
                HStack(spacing: 4) {
                    // 点赞按钮
                    Spacer()
                    Button(action: {
                        // TODO: 实现点赞功能
                    }) {
                        Image(systemName: "heart")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 关注按钮
                    Button(action: {
                        // TODO: 实现关注功能
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 聊天按钮
                    Button(action: {
                        // TODO: 跳转到聊天界面
                    }) {
                        Image(systemName: "message")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 详情按钮
                    Button(action: {
                        showingDetail = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    .navigationDestination(isPresented: $showingDetail) {
                        StoryRoleDetailView(
                            storyId: character.role.storyID,
                            roleId: character.role.roleID,
                            userId: character.role.creatorID,
                            role: character
                        )
                    }
                    Spacer()
                }
            }
        }
        .padding(4)
        .background(Color(.systemBackground))
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}


// 角色详情视图
struct StoryRoleDetailView: View {
    let storyId: Int64
    var boardIds: [Int64]
    let roleId: Int64
    let userId: Int64
    @State var role: StoryRole?
    @State var viewModel: StoryRoleModel?
    @State private var showingEditView = false
    @State private var showingChatView = false
    @State private var showingPosterView = false
    
    init(storyId: Int64, roleId: Int64, userId: Int64,role: StoryRole? = nil){
        self.storyId = storyId
        self.roleId = roleId
        self.role = role
        self.viewModel = StoryRoleModel(story: nil, storyId: 0, userId: userId)
        self.boardIds = [Int64]()
        self.userId = userId
        print("StoryRoleDetailView role: ",self.role?.role.characterName as Any)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部操作栏
                    topActionBar
                    
                    // 角色基本信息卡片
                    profileCard
                    
                    // 统计信息卡片
                    if let role = role {
                        statsCard(role: role)
                    }
                    
                    // 详细信息卡片
                    if let role = role {
                        detailsCard(role: role)
                    }
                    
                    // 底部操作按钮
                    if role?.role.roleID != 0 {
                        bottomActionButtons
                    }
                }
                .padding(.horizontal)
            }
            .fullScreenCover(isPresented: $showingEditView) {
                NavigationStack {
                    EditStoryRoleDetailView(role: role, userId: self.userId, viewModel: self.$viewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    showingEditView = false
                                }
                            }
                        }
                }
            }
            .fullScreenCover(isPresented: $showingChatView) {
                NavigationStack {
                    MessageContextView(userId: self.userId, roleId: (role?.role.roleID)!, role: self.role!)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    showingChatView = false
                                }
                            }
                        }
                }
            }
            .fullScreenCover(isPresented: $showingPosterView) {
                // 添加海报视图的导航目标
                // PosterView() // 取决于你的海报视图���现
            }
        }
    }
    
    // 顶部操作栏
    private var topActionBar: some View {
        HStack {
            Spacer()
            Button(action: { showingEditView = true }) {
                Label("编辑", systemImage: "pencil.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
    
    // 角色基本信息卡片
    private var profileCard: some View {
        VStack(spacing: 16) {
            if let role = role {
                // 头像
                KFImage(URL(string: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                // 名称
                Text(role.role.characterName)
                    .font(.system(size: 24, weight: .bold))
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // 统计信息卡片
    private func statsCard(role: StoryRole) -> some View {
        HStack(spacing: 24) {
            InteractionStatView(
                icon: "heart.fill",
                color: .red,
                value: role.role.likeCount,
                title: "点赞"
            )
            
            InteractionStatView(
                icon: "person.2.fill",
                color: .blue,
                value: role.role.followCount,
                title: "关注"
            )
            
            InteractionStatView(
                icon: "book.fill",
                color: .green,
                value: role.role.storyboardNum,
                title: "故事"
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // 详细信息卡片
    private func detailsCard(role: StoryRole) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailSection(
                title: "角色描述",
                content: role.role.characterDescription,
                placeholder: "角色比较神秘，没有介绍！"
            )
            
            Divider()
            
            DetailSection(
                title: "角色提示词",
                content: role.role.characterPrompt,
                placeholder: "提示词为空",
                showIcon: true
            )
            
            Divider()
            
            // 其他信息
            VStack(alignment: .leading, spacing: 8) {
                Text("其他信息")
                    .font(.headline)
                
                HStack {
                    Label(formatDate(timestamp: role.role.ctime), systemImage: "clock")
                    Spacer()
                    Label("ID: \(role.role.creatorID)", systemImage: "person.circle")
                }
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // 底部操作按钮
    private var bottomActionButtons: some View {
        HStack(spacing: 20) {
            RoleActionButton(
                title: "聊天",
                icon: "message.fill",
                action: { showingChatView = true }
            )
            
            RoleActionButton(
                title: "海报",
                icon: "photo.fill",
                action: { showingPosterView = true }
            )
        }
    }
    
    private func loadRoleData() {
        // TODO: 实现从 viewModel 或网络加载角色数据的逻辑
        // role = viewModel.getRoleById(roleId)
    }
    
    // 在 struct StoryRoleDetailView 之前添加
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// 辅助视图组件
struct InteractionStatView: View {
    let icon: String
    let color: Color
    let value: Int64
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    let placeholder: String
    var showIcon: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            if !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                HStack {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                    if showIcon {
                        Image(systemName: "rectangle.dashed.and.paperclip")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct RoleActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .medium))
        }
    }
}

