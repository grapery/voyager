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
        VStack(spacing: 0) {
            List{
                
            }
        }
        .navigationBarHidden(true)
    }
}

struct MessageContextCellView: View{
    var msgCtxId: Int64
    var roleId = 0
    var lastMessageContent = "hello"
    var curUserId: Int64
    var roleAvatar = ""
    init(msgCtxId: Int64, curUserId: Int64) {
        self.msgCtxId = msgCtxId
        self.curUserId = curUserId
    }
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading){
                HStack {
                    KFImage(URL(string: defaultAvator))
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                }
            }
            VStack(alignment: .trailing){
                HStack {
                    Text("\(self.lastMessageContent)")
                        .font(.subheadline)
                }
            }
        }
        .navigationBarHidden(true)
    }
}


struct MessageContextView: View {
    @ObservedObject var viewModel: MessageContextViewModel
    @State private var newMessageContent: String = ""
    @State var role: StoryRole?
    @FocusState private var isInputFocused: Bool
    init(userId: Int64, roleId: Int64,role: StoryRole) {
        self.role = role
        self.viewModel  = MessageContextViewModel.create(userId: userId, roleId: roleId)!
        self.isInputFocused = false
    }
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    // 返回操作
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Button(action: {
                    // 返回操作
                }) {
                    Image(systemName: "face.smiling")
                }
                Spacer()
                
                Button(action: {
                    // 更多操作
                }) {
                    Image(systemName: "ellipsis")
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
                Button(action: {
                    // 表情选择
                }) {
                    Image(systemName: "face.smiling")
                }
                
                TextField("发送消息", text: $newMessageContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                
                Button(action: {
                    // 图片选择
                }) {
                    Image(systemName: "photo")
                }
                
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Text("发送")
                }
                .disabled(newMessageContent.isEmpty)
            }
            .padding()
            .background(Color.white)
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






