//
//  MessageContextView.swift
//  voyager
//
//  Created by grapestree on 2024/12/7.
//


import SwiftUI
import Kingfisher
import ActivityIndicatorView

let defaultAvator = "https://grapery-dev.oss-cn-shanghai.aliyuncs.com/default.png"

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
    @State private var showingDeleteAlert = false
    @State private var messageToDelete: Int64?
    let user: User

    init(user: User) {
        self.user = user
        self.viewModel = MessageViewModel(userId: user.userID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopBar()
                SearchBar()
                MessageList()
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
                Text("确定要删除这个聊天会话吗？此操作无法撤销。")
            }
            .background(Color.theme.background)
        }
    }

    // 顶部导航栏
    @ViewBuilder
    private func TopBar() -> some View {
        CommonNavigationBar(
            title: "消息",
            onAddTapped: { }
        )
    }

    // 搜索栏
    @ViewBuilder
    private func SearchBar() -> some View {
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
    }

    // 消息列表
    @ViewBuilder
    private func MessageList() -> some View {
        ZStack {
            TrapezoidTriangles()
                .opacity(0.64)
                .ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.msgCtxs.isEmpty && !viewModel.isLoading {
                        // 空状态
                        VStack {
                            Spacer()
                            Text("没有聊天会话")
                                .foregroundColor(.gray)
                                .padding()
                            Spacer()
                        }
                    } else {
                        ForEach(viewModel.msgCtxs, id: \.id) { msgCtx in
                            VStack(spacing: 0) {
                                MessageContextCellView(
                                    msgCtxId: msgCtx.chatinfo.chatID,
                                    user: msgCtx.chatinfo.user,
                                    userId: user.userID,
                                    role: StoryRole(Id: msgCtx.chatinfo.role.roleID, role: msgCtx.chatinfo.role),
                                    lastMessage: msgCtx.chatinfo.lastMessage,
                                    onDelete: { id in
                                        messageToDelete = id
                                        showingDeleteAlert = true
                                    }
                                )
                                if msgCtx.id != viewModel.msgCtxs.last?.id {
                                    Divider().background(Color.theme.divider)
                                }
                            }
                            .onAppear {
                                // 上拉加载更多
                                if msgCtx.id == viewModel.msgCtxs.last?.id && viewModel.hasMorePages && !viewModel.isLoading {
                                    Task {
                                        await viewModel.fetchMoreChatContexts()
                                    }
                                }
                            }
                        }
                        if viewModel.isLoading {
                            // 加载中
                            VStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    HStack {
                                        ActivityIndicatorView(isVisible: .constant(true), type: .growingArc(.cyan))
                                            .frame(width: 64, height: 64)
                                            .foregroundColor(.cyan)
                                    }
                                    .frame(height: 32)
                                    Text("加载中……")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                }
                                .frame(maxWidth: .infinity)
                                Spacer()
                            }
                        } else if !viewModel.hasMorePages && !viewModel.msgCtxs.isEmpty {
                            // 没有更多
                            Text("没有更多聊天会话了")
                                .foregroundColor(.gray)
                                .padding()
                                .font(.system(size: 12))
                        }
                    }
                }
            }
            .background(Color.theme.background.opacity(0.85))
            .refreshable {
                // 下拉刷新
                await viewModel.fetchInitialChatContexts()
            }
        }
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
    
    @State private var showMessageContext = false
    
    var body: some View {
        Button(action: {
            showMessageContext = true
        }) {
            // 主要内容
            HStack(spacing: 12) {
                // 头像
                RectProfileImageView(avatarUrl: avatarURL, size: .InChat)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.theme.border, lineWidth: 1)
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
                            .lineLimit(3)
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
        .fullScreenCover(isPresented: $showMessageContext) {
            MessageContextView(
                userId: userId,
                roleId: role?.Id ?? 0,
                role: role!
            )
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









