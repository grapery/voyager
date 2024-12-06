import SwiftUI
import Kingfisher

let defaultAvator = "https://grapery-1301865260.cos.ap-shanghai.myqcloud.com/avator/tmp3evp1xxl.png"

// 添加消息类型枚举
enum MessageType {
    case text
    case image
    case video
    case audio
}

// 添加消息状态枚举
enum MessageStatus {
    case sending
    case sent
    case failed
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
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .background(Color(.systemGray6))
            }
            .navigationBarHidden(true)
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
        )) {
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
        if newMessageContent == "" {
            return
        }
        var chatMsg = Common_ChatMessage()
        chatMsg.message = newMessageContent
        chatMsg.chatID = self.viewModel.msgContext.chatID
        chatMsg.userID = self.viewModel.userId
        chatMsg.roleID = (self.viewModel.role?.role.roleID)!
        chatMsg.sender = Int32(self.viewModel.userId)
        let tempMessage = ChatMessage(
            id: Int64(Date().timeIntervalSince1970 * 1000),
            msg: chatMsg,
            status: .sending
        )
        // 添加到消息列表
        self.viewModel.messages.append(tempMessage)
        
        let (_,err) = await self.viewModel.sendMessage(msg: chatMsg)
        if let error = err {
            // 更新消息状态为失败
            if let index = self.viewModel.messages.firstIndex(where: { $0.id == tempMessage.id }) {
                self.viewModel.messages[index].status = .failed
            }
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } else {
            // 更新消息状态为已发送
            if let index = self.viewModel.messages.firstIndex(where: { $0.id == tempMessage.id }) {
                self.viewModel.messages[index].status = .sent
            }
            // 清空输入
            newMessageContent = ""
            selectedImage = nil
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
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var messageBubble: some View {
        Group {
            switch message.type {
            case .text:
                textBubble
            case .image:
                imageBubble
            case .video:
                videoBubble
            case .audio:
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
            case .sending:
                ProgressView()
                    .scaleEffect(0.7)
            case .sent:
                Image(systemName: "checkmark")
                    .foregroundColor(.gray)
                    .font(.caption2)
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
                    .font(.caption2)
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






