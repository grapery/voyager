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
    @State private var isShowingMediaPicker = false
    @State private var selectedImage: UIImage?
    
    init(userId: Int64, roleId: Int64, role: StoryRole) {
        self.role = role
        self.currentUserId = userId
        self.viewModel = MessageContextViewModel(userId: userId, roleId: roleId,role: role)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ChatNavigationBar(title: role?.role.characterName ?? "", onDismiss: { dismiss() })
            
            ChatMessageList(messages: viewModel.messages, currentUserId:self.currentUserId)
            
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
            id: Int64(Date().timeIntervalSince1970 * 1000),
            msg: chatMsg,
            status: .MessageSending
        )
        chatMsg.uuid = tempMessage.uuid!.uuidString
        tempMessage.msg.uuid = tempMessage.uuid!.uuidString
        do {
            // 保存待发送消息到本地
            try CoreDataManager.shared.savePendingMessage(tempMessage)
            // 发送消息
            let (relpyMsg, error) = await viewModel.sendMessage(msg: chatMsg)
            // 更新UI
            
            if let error = error {
                // 更新消息状态为失败
                try CoreDataManager.shared.updateMessageStatusByUUID(uuid: tempMessage.uuid!.uuidString, status: .MessageSendFailed)
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            } else {
                tempMessage.msg.id = relpyMsg![0].id
                tempMessage.status = .MessageSendSuccess
                DispatchQueue.main.async {
                    self.viewModel.messages.append(tempMessage)
                    self.newMessageContent = ""
                }
                // 更新消息状态为成功
                try CoreDataManager.shared.updateMessageStatusByUUID(uuid: tempMessage.uuid!.uuidString, status: .MessageSendSuccess)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
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
        let messages: [ChatMessage]?
        let currentUserId: Int64
        
        var body: some View {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if let messages = messages {
                            ForEach(messages) { message in
                                MessageCellView(currentUserId: currentUserId, message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: messages?.count) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
                .onAppear {
                    scrollToBottom(proxy: scrollProxy)
                }
            }
        }
        
        private func scrollToBottom(proxy: ScrollViewProxy) {
            if let lastMessage = messages?.last {
                withAnimation {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
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
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
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
    let message: ChatMessage
    
    @State private var isAnimating = false
    
    private var isFromCurrentUser: Bool {
        currentUserId == message.msg.userID
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromCurrentUser {
                AvatarView(roleId: message.msg.roleID)
            }
            
            if isFromCurrentUser {
                Spacer()
                messageStatusIndicator
            }
            
            messageBubble
                .scaleEffect(isAnimating ? 1 : 0.5)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            if !isFromCurrentUser {
                Spacer()
            } else {
                AvatarView(userId: currentUserId)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var messageBubble: some View {
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
            KFImage(URL(string: url))
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
    
    var body: some View {
        AsyncImage(url: URL(string: getAvatarUrl())) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
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


