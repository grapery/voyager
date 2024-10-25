import SwiftUI

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
            // ... 其他代码保持不变 ...
            
            // 输入框
            HStack(spacing: 10) {
                Button(action: {
                    // 表情选择
                }) {
                    Image(systemName: "face.smiling")
                }
                
                TextField("发送消息", text: $newMessageContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    // 图片选择
                }) {
                    Image(systemName: "photo")
                }
                
                Button(action: {
                    newMessageContent = ""
                }) {
                    Text("发送")
                }
                .disabled(newMessageContent.isEmpty)
            }
            .padding()
            .background(Color.white)
        }
        .navigationBarHidden(true)
    }
}

struct MessageContextCellView: View{
    var msgCtxId: Int64
    var roleId = 0
    var lastMessageContent = ""
    var curUserId: Int64
    init(msgCtxId: Int64, curUserId: Int64) {
        self.msgCtxId = msgCtxId
        self.curUserId = curUserId
    }
    var body: some View {
        VStack(){
            
        }
    }
}


struct MessageContextView: View {
    var viewModel: MessageContextViewModel
    @State var newMessage: Message
    @State var role: StoryRole
    
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
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        MessageCellView(message: message)
                    }
                }
                .padding()
            }
            
            // 输入框
            HStack(spacing: 10) {
                Button(action: {
                    // 表情选择
                }) {
                    Image(systemName: "face.smiling")
                }
                
                TextField("发送消息", text: $newMessage.content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    // 图片选择
                }) {
                    Image(systemName: "photo")
                }
                
                Button(action: {
                    Task{
                        await viewModel.sendMessage()
                    }
                }) {
                    Text("发送")
                }
            }
            .padding()
            .background(Color.white)
        }
        .navigationBarHidden(true)
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
                Text(message.content)
                    .padding(10)
                    .background(message.isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
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






