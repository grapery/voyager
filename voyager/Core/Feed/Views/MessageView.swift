//
//  MessageContextView.swift
//  voyager
//
//  Created by grapestree on 2024/12/7.
//


import SwiftUI
import Kingfisher

let defaultAvator = "https://grapery-1301865260.cos.ap-shanghai.myqcloud.com/avator/tmp3evp1xxl.png"

// 添加消息类型枚举
enum MessageType: Int64 {
    case MessageTypeText = 1
    case MessageTypeImage = 2
    case MessageTypeVideo = 3
    case MessageTypeAudio = 4
}

// 添加消息状态枚举
enum MessageStatus: Int64 {
    case MessageSending = 1
    case MessageSendSuccess = 2
    case MessageSendFailed = 3
}


struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var newMessageContent: String = ""
    @State var user: User?
    @State private var searchText = ""
    @State private var isSearching = false
    
    init(user: User? = nil) {
        self.user = user
        self.viewModel = MessageViewModel(userId: user!.userID, page: 0, pageSize: 10)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 优化顶部导航栏
                HStack {
                    Text("消息")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                
                // 添加搜索栏
                SearchBar(text: $searchText, isSearching: $isSearching)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // 优化消息列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.msgCtxs, id: \.id) { msgCtx in
                            MessageContextCellView(
                                msgCtxId: msgCtx.chatinfo.chatID,
                                userId: user!.userID,
                                user: msgCtx.chatinfo.user,
                                role: StoryRole(Id: msgCtx.chatinfo.role.roleID, role: msgCtx.chatinfo.role),
                                lastMessage: msgCtx.chatinfo.lastMessage
                            )
                            .background(Color.white)
                            Divider().padding(.horizontal)
                        }
                    }
                }
                .background(Color(.systemGray6))
            }
            .onAppear {
                Task {
                    await self.viewModel.initUserChatContext()
                }
            }
        }
    }
}

// 优化搜索栏组件
struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索聊天记录", text: $text)
                    .font(.system(size: 15))
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// 优化消息单元格视图
struct MessageContextCellView: View {
    var msgCtxId: Int64
    var user: User?
    var userId: Int64
    var role: StoryRole?
    var lastMessage: Common_ChatMessage?
    init(msgCtxId: Int64, userId: Int64,user: User,role: StoryRole,lastMessage: Common_ChatMessage) {
        self.msgCtxId = msgCtxId
        self.userId = userId
        self.lastMessage = lastMessage
        self.user = user
        self.role = role
    }
    
    private var isFromUser: Bool {
        lastMessage!.sender == userId
    }
    
    private var avatarURL: String {
        if isFromUser {
            return user?.avatar ?? defaultAvator
        } else {
            return role?.role.characterAvatar ?? defaultAvator
        }
    }
    
    private func formatTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View { 
        NavigationLink(destination: MessageContextView(
            userId: userId,
            roleId: role?.Id ?? 0,
            role: role!
        )
            .toolbar(.visible, for: .tabBar)
        ) {
            HStack(spacing: 12) {
                // 优化头像显示
                RectProfileImageView(avatarUrl: avatarURL, size: .InChat)
                    .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isFromUser ? (user?.name ?? "Me") : (role?.role.characterName ?? "Unknown"))
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text(formatTime(lastMessage?.timestamp ?? 0))
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    
                    Text(lastMessage?.message ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}









