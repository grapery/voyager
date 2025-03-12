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
enum MessageStatus: Int64 {
    case MessageSending = 1
    case MessageSendSuccess = 2
    case MessageSendFailed = 3
}


struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    @State var user: User?
    
    init(user: User? = nil) {
        self.user = user
        self.viewModel = MessageViewModel(userId: user!.userID, page: 0, pageSize: 10)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 使用通用导航栏
                CommonNavigationBar(
                    title: "消息",
                    onAddTapped: {
                        // 处理添加新消息操作
                    }
                )
                
                // 使用通用搜索栏
                CommonSearchBar(
                    searchText: $searchText,
                    placeholder: "搜索消息"
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // 消息列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.msgCtxs, id: \.id) { msgCtx in
                            MessageContextCellView(
                                msgCtxId: msgCtx.chatinfo.chatID,
                                userId: user!.userID,
                                user: msgCtx.chatinfo.user,
                                role: StoryRole(Id: msgCtx.chatinfo.role.roleID, role: msgCtx.chatinfo.role),
                                lastMessage: msgCtx.chatinfo.lastMessage
                            )
                        }
                    }
                    .padding(.top, 16)
                }
                .background(Color.theme.background)
            }
            .onAppear {
                Task {
                    await self.viewModel.initUserChatContext()
                }
            }
            .background(Color.theme.background)
        }
    }
}

// 添加颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// 修改消息单元格视图
struct MessageContextCellView: View {
    var msgCtxId: Int64
    var user: User?
    var userId: Int64
    var role: StoryRole?
    var lastMessage: Common_ChatMessage?
    
    init(msgCtxId: Int64, userId: Int64, user: User, role: StoryRole, lastMessage: Common_ChatMessage) {
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
    
    var body: some View {
        NavigationLink(destination: MessageContextView(
            userId: userId,
            roleId: role?.Id ?? 0,
            role: role!
        )
            .toolbar(.visible, for: .tabBar)
        ) {
            // 主要内容
            HStack(spacing: 12) {
                // 头像
                RectProfileImageView(avatarUrl: avatarURL, size: .InChat)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.theme.border, lineWidth: 0.5)
                    )
                
                // 消息内容
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        Text(isFromUser ? (user?.name ?? "Me") : (role?.role.characterName ?? "Unknown"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        
                        Spacer()
                        
                        Text(formatTime(lastMessage?.timestamp ?? 0))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    
                    Text(lastMessage?.message ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.dateComponents([.day], from: date, to: now).day! < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
}









