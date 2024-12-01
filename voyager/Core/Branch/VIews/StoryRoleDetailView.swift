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
                
                // 操作按钮
                HStack(spacing: 12) {
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
                            Image(systemName: "star")
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
                            boardIds: [Int64](),
                            roleId: character.role.roleID,
                            viewModel: self.viewModel
                        )
                    }
                    Spacer()
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}


// 角色详情视图
struct StoryRoleDetailView: View {
    let storyId: Int64
    let boardIds: [Int64]
    let roleId: Int64
    @State var role: StoryRole?
    var viewModel: StoryDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let role = role {
                    // 角色头像
                    if !role.role.characterAvatar.isEmpty {
                        RectProfileImageView(avatarUrl: role.role.characterAvatar, size: .profile)
                    }else{
                        RectProfileImageView(avatarUrl: defaultAvator, size: .profile)
                    }
                    
                    // 角色名称
                    Text(role.role.characterName)
                        .font(.title)
                        .bold()
                    
                    // 角色描述
                    if role.role.characterDescription.isEmpty {
                        Text(role.role.characterDescription)
                            .font(.body)
                    }else{
                        Text("角色比较神秘，没有介绍！")
                            .font(.body)
                    }
                    
                    // 角色提示词
                    if role.role.characterPrompt.isEmpty {
                        Text(role.role.characterPrompt)
                            .font(.body)
                    }else{
                        Text("角色比较神秘，没有介绍！")
                            .font(.body)
                    }
                } else {
                    ProgressView()
                }
            }
            .padding()
            HStack(spacing: 16) {
                // 点赞数
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(role?.role.likeCount ?? 0)")
                }
                .padding(4)
                
                // 关注数
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("\(role?.role.followCount ?? 0)")
                }
                .padding(4)
                
                // 故事板数量
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .foregroundColor(.green)
                    Text("\(role?.role.storyboardNum ?? 0)")
                }
                .padding(4)
                
                // 创建时间
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.gray)
                    Text(self.formatDate(timestamp: (role?.role.ctime)!))
                }
                .padding(4)
                
                // 创建者ID
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.purple)
                    Text("\(role?.role.creatorID ?? 0)")
                }
                .padding(4)
            }
            .font(.footnote)
            .padding(.horizontal)
        }
        .onAppear {
            // 在视图出现时加载角色数据
            loadRoleData()
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

