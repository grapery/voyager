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
    @State private var showingAvatarPreview = false

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
    @State private var showingDescriptionEditor = false
    @State private var showingPromptEditor = false
    @State private var showingInfoEditor = false
    @State private var showingAvatarPreview = false
    
    init(storyId: Int64, roleId: Int64, userId: Int64,role: StoryRole? = nil){
        self.storyId = storyId
        self.roleId = roleId
        self.role = role
        self.viewModel = StoryRoleModel(story: nil, storyId: 0, userId: userId)
        self.boardIds = [Int64]()
        self.userId = userId
    }

    init(roleId: Int64, userId: Int64) {
        self.viewModel = StoryRoleModel(userId: userId)
        self.boardIds = [Int64]()
        self.userId = userId
        self.roleId = roleId
        self.storyId = 0
    }
    
    // 添加新的加载方法
    private func loadRoleDetails() async {
        if let viewModel = viewModel {
            do {
                let (detail, err) = await viewModel.fetchStoryRoleDetail(roleId: roleId)
                if err == nil {
                    role = detail
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 角色基本信息卡片
                    if let role = role {
                        profileCard
                        // 添加全屏预览视图
                            .fullScreenCover(isPresented: $showingAvatarPreview) {
                                AvatarPreviewView(
                                    imageURL: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar,
                                    isPresented: $showingAvatarPreview
                                )
                            }
                            .onTapGesture {
                                showingAvatarPreview = true
                            }
                    }
                    // 统计信息卡片
                    if let role = role {
                        statsCard(role: role)
                    }
                    
                    // 详细信息卡片
                    if let role = role {
                        detailsCard(role: role)
                    }
                    
                    // 底部操作按钮
                    bottomActionButtons
                }
                .padding(.horizontal, 12)
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
                    MessageContextView(userId: self.userId, roleId: self.roleId, role: self.role!)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    showingChatView = false
                                }
                            }
                        }
                        .navigationBarHidden(true)
                }
            }
            .fullScreenCover(isPresented: $showingPosterView) {
                // 添加海报视图的导航目标
                // PosterView() // 取决于你的海报视图现
            }
            
        }
        .task {  // 或者使用 .onAppear
            await loadRoleDetails()
        }
    }
    
    // 角色基本信息卡片
    private var profileCard: some View {
        VStack(spacing: 12) {
            if let role = role {
                // 头像
                KFImage(URL(string: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                // 名称
                Text(role.role.characterName)
                    .font(.system(size: 20, weight: .bold))
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
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
        VStack(alignment: .leading, spacing: 12) {
            // 角色描述部分
            Button(action: { showingDescriptionEditor = true }) {
                DetailSection(
                    title: "角色描述",
                    content: role.role.characterDescription,
                    placeholder: "角色比较神秘，没有介绍！", showIcon: false,
                    fontSize: 14
                )
            }
            .sheet(isPresented: $showingDescriptionEditor) {
                EditDescriptionView(role: role, onSave: { /* 保存逻辑 */ })
            }
            
            Divider()
            
            // 角色提示词部分
            Button(action: { showingPromptEditor = true }) {
                DetailSection(
                    title: "角色提示词",
                    content: role.role.characterPrompt,
                    placeholder: "提示词为空",
                    showIcon: true,
                    fontSize: 14
                )
            }
            .sheet(isPresented: $showingPromptEditor) {
                EditPromptView(role: role, onSave: { /* 保存逻辑 */ })
            }
            
            Divider()
            
            // 其他信息部分
            Button(action: { showingInfoEditor = true }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("其他信息")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack {
                        Label(formatDate(timestamp: role.role.ctime), systemImage: "clock")
                        Spacer()
                        Label("ID: \(role.role.creatorID)", systemImage: "person.circle")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingInfoEditor) {
                EditInfoView(role: role, onSave: { /* 保存逻辑 */ })
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
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
    let fontSize: CGFloat
    init(title: String, content: String, placeholder: String,showIcon: Bool, fontSize: CGFloat) {
        self.title = title
        self.content = content
        self.placeholder = placeholder
        self.fontSize = fontSize
        self.showIcon = showIcon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: fontSize, weight: .medium))
            
            Text(content.isEmpty ? placeholder : content)
                .font(.system(size: fontSize))
                .foregroundColor(content.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.leading)
            
            if showIcon {
                HStack {
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
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

// MARK: - Edit Description View
struct EditDescriptionView: View {
    let role: StoryRole
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var description: String
    
    init(role: StoryRole, onSave: @escaping () -> Void) {
        self.role = role
        self.onSave = onSave
        _description = State(initialValue: role.role.characterDescription)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("编辑角色描述")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top)
                
                TextEditor(text: $description)
                    .font(.system(size: 14))
                    .padding(8)
                    .frame(maxHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // TODO: 实现保存逻辑
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Edit Prompt View
struct EditPromptView: View {
    let role: StoryRole
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String
    
    init(role: StoryRole, onSave: @escaping () -> Void) {
        self.role = role
        self.onSave = onSave
        _prompt = State(initialValue: role.role.characterPrompt)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("编辑角色提示词")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top)
                
                Text("提示词将用于AI对话中塑造角色性格")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $prompt)
                    .font(.system(size: 14))
                    .padding(8)
                    .frame(maxHeight: 300)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // TODO: 实现保存逻辑
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Edit Info View
struct EditInfoView: View {
    let role: StoryRole
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(role: StoryRole, onSave: @escaping () -> Void) {
        self.role = role
        self.onSave = onSave
        _name = State(initialValue: role.role.characterName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("角色名称")
                        Spacer()
                        TextField("输入角色名称", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Button(action: { showImagePicker = true }) {
                        HStack {
                            Text("更换头像")
                            Spacer()
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                KFImage(URL(string: role.role.characterAvatar))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Section(header: Text("其他信息")) {
                    HStack {
                        Text("创建时间")
                        Spacer()
                        Text(formatDate(timestamp: role.role.ctime))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("角色ID")
                        Spacer()
                        Text("\(role.role.roleID)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // TODO: 实现保存逻辑
                        onSave()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                SingleImagePicker(image: $selectedImage)
            }
        }
    }
}



