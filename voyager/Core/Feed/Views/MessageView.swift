import SwiftUI
import Kingfisher

let defaultAvator = "https://grapery-1301865260.cos.ap-shanghai.myqcloud.com/avator/tmp3evp1xxl.png"

struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var newMessageContent: String = ""
    @State var user: User?
    init( user: User? = nil) {
        self.user = user
        self.viewModel = MessageViewModel(userId: user!.userID, page: 0, pageSize: 10)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Text("消息")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding()
                
                // 消息列表
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.msgCtxs, id: \.id) { msgCtx in
                            VStack{
                                MessageContextCellView(
                                    msgCtxId: msgCtx.chatinfo.chatID,
                                    userId: user!.userID,
                                    user: msgCtx.chatinfo.user,
                                    role: StoryRole(Id: msgCtx.chatinfo.role.roleID,role: msgCtx.chatinfo.role),
                                    lastMessage: msgCtx.chatinfo.lastMessage
                                )
                                .padding(.horizontal)
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear{
                Task{
                    await self.viewModel.initUserChatContext()
                }
            }
        }
    }
}

struct MessageContextCellView: View{
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
            HStack(spacing: 2) {
                // Avatar
                RectProfileImageView(avatarUrl: defaultAvator, size: .InChat)
                
                // Message content and time
                VStack(alignment: .leading) {
                    // Name
                    Text(isFromUser ? (user?.name ?? "Me") : (role?.role.characterName ?? "Unknown"))
                        .font(.headline)
                    
                    // Last message
                    Text(lastMessage?.message ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time
                Text(formatTime(lastMessage?.timestamp ?? 0))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
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
    
    init(userId: Int64, roleId: Int64, role: StoryRole) {
        self.role = role
        self.currentUserId = userId
        self.viewModel = MessageContextViewModel(userId: userId, roleId: roleId)
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
        chatMsg.roleID = self.viewModel.roleId
        chatMsg.sender = Int32(self.viewModel.userId)
        let (_,err) = await self.viewModel.sendMessage(msg: chatMsg)
        if err != nil {
            errorMessage = err?.localizedDescription ?? "未知错误"
            showErrorAlert = true
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
        
        var body: some View {
            HStack(alignment: .bottom) {
                TextField("发送消息", text: $newMessageContent)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused(isInputFocused)
                
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                }
                
                Button(action: onSendMessage) {
                    Image(systemName: "paperplane.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                }
                .disabled(newMessageContent.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }
}

struct MessageCellView: View {
    let currentUserId: Int64
    let message: ChatMessage
    
    private var isFromCurrentUser: Bool {
        currentUserId == message.msg.userID
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer()
            }
            
            Text(message.msg.message)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isFromCurrentUser ? .white : .black)
                .cornerRadius(16)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = message.msg.message
                    }) {
                        Text("复制")
                        Image(systemName: "doc.on.doc")
                    }
                }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}






