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
    
    init(userId: Int64, roleId: Int64,role: StoryRole) {
        self.role = role
        self.viewModel  = MessageContextViewModel(userId: userId, roleId: roleId)
        self.isInputFocused = false
    }
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    // 返回操作
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text((role?.role.characterName)!)
                Spacer()
                
                Button(action: {
                    // 更多操作
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
            
            // 消息列表
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageCellView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
            }
            
            // 输入框
            HStack(alignment: .bottom) {
                TextField("发送消息", text: $newMessageContent)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: {
                    // 图片选择
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                }
                
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
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
        .navigationBarHidden(true)
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    private func sendMessage() async {
        newMessageContent = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageCellView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
                KFImage(URL(string: defaultAvator))
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
                
                if !message.content.isEmpty {
                    Text(message.content)
                        .padding(10)
                        .background(message.isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(message.isFromCurrentUser ? .white : .black)
                        .cornerRadius(10)
                }
                
                Text(message.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
}






