//
//  MessageContextView.swift
//  voyager
//
//  Created by grapestree on 2024/12/7.
//

import SwiftUI
import Kingfisher

struct MessageContextView: View {
    @ObservedObject var viewModel: MessageContextViewModel
    @State private var newMessageContent: String = ""
    @State var role: StoryRole?
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    var currentUserId: Int64
    var currentRoleId: Int64
    @State private var isShowingMediaPicker = false
    @State private var selectedImage: UIImage?

    @State private var isLoadingHistory = false
    @State private var hasMoreMessages = true  // 新增：标记是否还有更多消息
    
    
    init(userId: Int64, roleId: Int64, role: StoryRole) {
        self.role = role
        self.currentUserId = userId
        self.currentRoleId = roleId
        self.viewModel = MessageContextViewModel(userId: userId, roleId: roleId,role: role)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ChatNavigationBar(title: role?.role.characterName ?? "", onDismiss: { dismiss() })
            
            ChatMessageList(
                messages: $viewModel.messages,
                currentUserId: self.currentUserId,
                currentRoleId: self.currentRoleId,
                onLoadMore: loadMoreMessages
            )
            
            ChatInputBar(
                newMessageContent: $newMessageContent,
                isInputFocused: $isInputFocused,
                onSendMessage: {
                    Task {
                        await sendMessage()
                    }
                }
            )
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden, for: .tabBar)
        .onTapGesture {
            isInputFocused = false
        }
        .alert("发送失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendMessage() async {
        guard !newMessageContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 创建消息
        var chatMsg = Common_ChatMessage()
        chatMsg.message = newMessageContent
        chatMsg.chatID = viewModel.msgContext.chatID
        chatMsg.userID = viewModel.userId
        chatMsg.roleID = (viewModel.role?.role.roleID)!
        chatMsg.sender = Int32(viewModel.userId)
        
        let tempMessage = ChatMessage(
            id: Int64(Date().timeIntervalSince1970),
            msg: chatMsg,
            status: .MessageSending
        )
        chatMsg.uuid = tempMessage.uuid!.uuidString
        tempMessage.msg.uuid = tempMessage.uuid!.uuidString
        
        do {
            // 保存待发送消息到本地
            try CoreDataManager.shared.savePendingMessage(tempMessage)
            // 立即清空输入框并显示发送中的消息
            DispatchQueue.main.async {
                self.viewModel.messages.append(tempMessage)
                self.newMessageContent = ""
            }
            // 发送消息
            let (relpyMsg, error) = await viewModel.sendMessage(msg: chatMsg)
            if let error = error {
                // 更新消息状态为失败
                try CoreDataManager.shared.updateMessageStatusByUUID(uuid: tempMessage.uuid!.uuidString, id:-1, status: .MessageSendFailed)
                // 更新UI中对应消息的状态
                DispatchQueue.main.async {
                    if let index = self.viewModel.messages.firstIndex(where: { $0.uuid == tempMessage.uuid }) {
                        self.viewModel.messages[index].status = .MessageSendFailed
                        print(self.viewModel.messages[index].msg.message)
                    }
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            } else {
                // 更新临时消息的ID和状态
                try CoreDataManager.shared.updateMessageStatusByUUID(
                    uuid: tempMessage.uuid!.uuidString,
                    id: relpyMsg![0].id,
                    status: .MessageSendSuccess
                )
                DispatchQueue.main.async {
                    if let index = self.viewModel.messages.firstIndex(where: { $0.uuid == tempMessage.uuid }) {
                        self.viewModel.messages[index].status = .MessageSendSuccess
                        self.viewModel.messages[index].msg.id = relpyMsg![0].id
                        self.viewModel.messages[index].id = relpyMsg![0].id
                        print("消息更新成功: ID=\(relpyMsg![0].id), 内容=\(self.viewModel.messages[index].msg.message)")
                    }
                }
                // 添加服务器返回的其他消息
                if relpyMsg!.count > 1 {
                    for i in 1..<relpyMsg!.count {
                        let serverMessage = relpyMsg![i]
                        let newChatMessage = ChatMessage(
                            id: serverMessage.id,
                            msg: serverMessage,
                            status: .MessageSendSuccess
                        )
                        
                        try CoreDataManager.shared.savePendingMessage(newChatMessage)
                        
                        DispatchQueue.main.async {
                            self.viewModel.messages.append(newChatMessage)
                        }
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                if let index = self.viewModel.messages.firstIndex(where: { $0.uuid == tempMessage.uuid }) {
                    self.viewModel.messages[index].status = .MessageSendFailed
                }
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    
    private func loadMoreMessages() async {
        guard !isLoadingHistory && hasMoreMessages else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            // 获取最早的消息ID作为分页标记
            let earliestMessageTimestamp = viewModel.messages.first?.msg.timestamp ?? 0
            
            // 从本地数据库加历史消息
            let localMessages =  try CoreDataManager.shared.fetchRecentMessagesByTimestamp(
                chatId: viewModel.msgContext.chatID,
                timestamp: earliestMessageTimestamp
            )
            
            if !localMessages.isEmpty {
                // 如果本地有历史消息，直接添加到消息列表前面
                DispatchQueue.main.async {
                    withAnimation {
                        viewModel.messages.insert(contentsOf: localMessages, at: 0)
                    }
                }
            } else {
                // 如果本地没有更多消息，从服务器获取
                let (msgs,err) = await viewModel.fetchRemoteHistoryMessages(
                    chatCtxId: viewModel.msgContext.chatID,
                    timestamp: earliestMessageTimestamp
                )
                if err != nil{
                    print("Failed to load history messages: \(err as Any)")
                    self.hasMoreMessages = false
                }else{
                    print("histiry msg length: ",msgs as Any)
                }
                
            }
        } catch {
            print("Failed to load history messages: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "加载历史消息失败"
                self.showErrorAlert = true
                // 出错时也要更新状态
                self.hasMoreMessages = false
            }
        }
    }
    
    // 顶部导航栏组件
    private struct ChatNavigationBar: View {
        let title: String
        let onDismiss: () -> Void
        
        var body: some View {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(title)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
        }
    }
    
    // 消息列表组件
    private struct ChatMessageList: View {
        @Binding var messages: [ChatMessage]
        let currentUserId: Int64
        let currentRoleId: Int64
        @State private var isLoading = false
        let onLoadMore: () async -> Void
        @State var isinit: Bool = false
        
        var body: some View {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { message in
                            MessageCellView(
                                currentUserId: currentUserId,
                                currentRoleId: currentRoleId,
                                message: message
                            )
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: messages) { _ in
                    if isinit {
                        withAnimation(.easeOut(duration: 0.3)) {
                            scrollProxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    scrollProxy.scrollTo("bottom", anchor: .bottom)
                    isinit = true
                }
            }
        }
    }
    
    // 新增加载指示器组件
    private struct LoadingIndicator: View {
        let isLoading: Bool
        @State private var rotation: Double = 0
        
        var body: some View {
            VStack {
                if isLoading {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.2.circlepath")
                            .rotationEffect(.degrees(rotation))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    rotation = 360
                                }
                            }
                        Text("加载更多消息...")
                    }
                    .foregroundColor(.gray)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    // 输入栏组件
    private struct ChatInputBar: View {
        @Binding var newMessageContent: String
        var isInputFocused: FocusState<Bool>.Binding
        let onSendMessage: () -> Void
        @State private var isShowingMediaOptions = false
        
        var body: some View {
            VStack(spacing: 0) {
                if isShowingMediaOptions {
                    mediaOptionsView
                        .transition(.move(edge: .bottom))
                }
                
                HStack(alignment: .bottom) {
                    Button(action: {
                        withAnimation {
                            isShowingMediaOptions.toggle()
                        }
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .rotationEffect(.degrees(isShowingMediaOptions ? 45 : 0))
                            .animation(.spring(), value: isShowingMediaOptions)
                    }
                    
                    TextField("发送消息", text: $newMessageContent)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused(isInputFocused)
                    
                    Button(action: onSendMessage) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(newMessageContent.isEmpty ? .gray : .orange)
                            .animation(.easeInOut, value: newMessageContent.isEmpty)
                    }
                    .disabled(newMessageContent.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .animation(.easeInOut, value: isShowingMediaOptions)
            }
        }
        
        private var mediaOptionsView: some View {
            HStack(spacing: 20) {
                mediaOption(icon: "photo", title: "相册")
                mediaOption(icon: "camera", title: "拍摄")
                mediaOption(icon: "mic", title: "语音")
                mediaOption(icon: "location", title: "位置")
            }
            .padding()
            .background(Color(.systemBackground))
        }
        
        private func mediaOption(icon: String, title: String) -> some View {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.orange)
                    .cornerRadius(10)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct MessageCellView: View {
    let currentUserId: Int64
    let currentRoleId: Int64
    @State var message: ChatMessage
    
    @State private var isAnimating = false
    init(currentUserId: Int64, currentRoleId: Int64, message: ChatMessage) {
        self.currentUserId = currentUserId
        self.currentRoleId = currentRoleId
        self.message = message
    }
    private var isFromCurrentUser: Bool {
        currentUserId == message.msg.sender
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isFromCurrentUser {
                AvatarView(userId: self.currentUserId,roleId: self.currentRoleId)
                    .frame(width: 40, height: 40)
            } else {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading) {
                messageBubble
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    }
            }
            
            if isFromCurrentUser {
                AvatarView(userId: self.currentUserId,roleId: self.currentRoleId)
                    .frame(width: 40, height: 40)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var messageBubble: some View {
        HStack {
            if isFromCurrentUser {
                messageStatusIndicator
            }
            
            Group {
                switch message.type {
                case .MessageTypeText:
                    textBubble
                case .MessageTypeImage:
                    imageBubble
                case .MessageTypeVideo:
                    videoBubble
                case .MessageTypeAudio:
                    audioBubble
                }
            }
        }
    }
    
    private var textBubble: some View {
        Text(message.msg.message)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isFromCurrentUser ? .white : .black)
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = message.msg.message
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    // 实现转发功能
                }) {
                    Label("转发", systemImage: "arrowshape.turn.up.right")
                }
                
                if isFromCurrentUser {
                    Button(role: .destructive, action: {
                        // 实现删除功能
                    }) {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
    }
    
    private var messageStatusIndicator: some View {
        Group {
            switch message.status {
            case .MessageSending:
                ProgressView()
                    .scaleEffect(0.7)
            case .MessageSendSuccess:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.gray)
                    .font(.caption2)
            case .MessageSendFailed:
                Button(action: {
                    Task {
                        //await viewModel.retryMessage(message)
                    }
                }) {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(.red)
                        .font(.caption2)
                }
            }
        }
        .frame(width: 20)
    }
    
    // 图片消息气泡
    private var imageBubble: some View {
        if let url = message.mediaURL {
            KFImage(URL(string: convertImagetoSenceImage(url: url, scene: .content)))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 200)
                .cornerRadius(16) as! Color
        } else {
            Color.clear
        }
    }
    
    // 视频消息气泡
    private var videoBubble: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.1))
            .frame(width: 200, height: 150)
            .overlay(
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
    
    // 语音消息气泡
    private var audioBubble: some View {
        HStack {
            Image(systemName: "waveform")
            Text("0:15")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
        )
        .foregroundColor(isFromCurrentUser ? .white : .black)
    }
}

// 新增头像组件
struct AvatarView: View {
    var userId: Int64? = nil
    var roleId: Int64? = nil
    @State private var navigateToRoleDetail = false
    init(userId: Int64? = nil, roleId: Int64? = nil) {
        self.userId = userId
        self.roleId = roleId
    }
    var body: some View {
        NavigationLink(destination: roleId != nil ? StoryRoleDetailView(roleId: roleId!,userId: userId!): nil, isActive: $navigateToRoleDetail) {
            AsyncImage(url: URL(string: getAvatarUrl())) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .onTapGesture {
                if roleId != nil {
                    navigateToRoleDetail = true
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func getAvatarUrl() -> String {
        if let userId = userId {
            return defaultAvator
        } else if let roleId = roleId {
            return defaultAvator
        }
        return ""
    }
}


