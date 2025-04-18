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
    @State private var showingDeleteAlert = false
    @State private var messageToDelete: Int64? = nil
    @State private var isLoading = false
    
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
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.theme.tertiaryText)
                    TextField("搜索消息", text: $searchText)
                        .foregroundColor(Color.theme.inputText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.theme.tertiaryText)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.theme.tertiaryBackground)
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // 消息列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.msgCtxs, id: \.id) { msgCtx in
                            VStack(spacing: 0) {
                                MessageContextCellView(
                                    msgCtxId: msgCtx.chatinfo.chatID,
                                    user: msgCtx.chatinfo.user,
                                    userId: user!.userID,
                                    role: StoryRole(Id: msgCtx.chatinfo.role.roleID, role: msgCtx.chatinfo.role),
                                    lastMessage: msgCtx.chatinfo.lastMessage,
                                    onDelete: { id in
                                        messageToDelete = id
                                        showingDeleteAlert = true
                                    }
                                )
                                
                                if msgCtx.id != viewModel.msgCtxs.last?.id {
                                    Divider()
                                        .background(Color.theme.divider)
                                }
                            }
                        }
                    }
                }
                .background(Color.theme.background)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let id = messageToDelete {
                        Task {
                            //await viewModel.deleteMessageContext(msgCtxId: id)
                        }
                    }
                }
            } message: {
                Text("确定要删除这条消息吗？此操作无法撤销。")
            }
            .onAppear {
                Task {
                    isLoading = true
                    await self.viewModel.initUserChatContext()
                    isLoading = false
                }
            }
            .background(Color.theme.background)
            .overlay {
                if isLoading {
                    loadingOverlay
                }
            }
        }
        .background(Color.theme.background)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("正在获取消息...")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.theme.secondary.opacity(0.8))
            .cornerRadius(12)
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
    }
}




// 修改消息单元格视图
struct MessageContextCellView: View {
    var msgCtxId: Int64
    var user: User?
    var userId: Int64
    var role: StoryRole?
    var lastMessage: Common_ChatMessage?
    var onDelete: (Int64) -> Void
    
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
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete(msgCtxId)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
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









