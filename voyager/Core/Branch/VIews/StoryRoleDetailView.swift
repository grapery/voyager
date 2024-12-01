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
                HStack(spacing: 8) {
                    // 点赞按钮
                    Spacer()
                    Button(action: {
                        // TODO: 实现点赞功能
                    }) {
                        VStack {
                            Image(systemName: "heart")
                            Text("点赞")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 关注按钮
                    Button(action: {
                        // TODO: 实现关注功能
                    }) {
                        VStack {
                            Image(systemName: "bell")
                            Text("关注")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 聊天按钮
                    Button(action: {
                        // TODO: 跳转到聊天界面
                    }) {
                        VStack {
                            Image(systemName: "message")
                            Text("聊天")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 详情按钮
                    Button(action: {
                        showingDetail = true
                    }) {
                        VStack {
                            Image(systemName: "info.circle")
                            Text("详情")
                                .font(.caption2)
                        }
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
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add edit button to the top
                HStack {
                    Spacer()
                    Button(action: {
                        showingEditView = true
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                
                // 头像和基本信息区域
                VStack(spacing: 16) {
                    if let role = role {
                        // 头像
                        if !role.role.characterAvatar.isEmpty {
                            RectProfileImageView(avatarUrl: role.role.characterAvatar, size: .profile)
                                .frame(width: 120, height: 120)
                        } else {
                            RectProfileImageView(avatarUrl: defaultAvator, size: .profile)
                                .frame(width: 120, height: 120)
                        }
                        
                        
                        // 名称
                        Text(role.role.characterName)
                            .font(.title2)
                            .bold()
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                // 统计信息
                if let role = role {
                    HStack(spacing: 24) {
                        StatView(image: "heart.fill", color: .red, value: role.role.likeCount, title: "点赞")
                        StatView(image: "person.2.fill", color: .blue, value: role.role.followCount, title: "关注")
                        StatView(image: "book.fill", color: .green, value: role.role.storyboardNum, title: "故事")
                    }
                    .padding(.horizontal)
                    
                    // 详细信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(title: "角色描述") {
                            if !role.role.characterDescription.isEmpty {
                                Text(role.role.characterDescription)
                            } else {
                                Text("角色比较神秘，没有介绍！")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        InfoSection(title: "角色提示词") {
                            if !role.role.characterPrompt.isEmpty {
                                Text(role.role.characterPrompt)
                            } else {
                                HStack {
                                    Text("提示词为空")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "rectangle.dashed.and.paperclip")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Divider()
                        
                        InfoSection(title: "其他信息") {
                            HStack {
                                Label(formatDate(timestamp: role.role.ctime), systemImage: "clock")
                                Spacer()
                                Label("ID: \(role.role.creatorID)", systemImage: "person.circle")
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    .padding(.horizontal)
                }
                
                // Add bottom buttons after the last card
                if let role = role {
                    HStack(spacing: 20) {
                        Button(action: {
                            showingChatView = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("聊天")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingPosterView = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("海报")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
        }
        .navigationDestination(isPresented: $showingEditView) {
            EditStoryRoleDetailView(role: role,userId: self.userId,viewModel: self.$viewModel)
        }
        .navigationDestination(isPresented: $showingChatView) {
            MessageContextView(userId: self.userId, roleId: (role?.role.roleID)!,role: self.role!)
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

// 辅助视图
struct StatView: View {
    let image: String
    let color: Color
    let value: Int64
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: image)
                .foregroundColor(color)
            Text("\(value)")
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
                .font(.body)
        }
    }
}

