import SwiftUI

let defaultAvator = "https://grapery-1301865260.cos.ap-shanghai.myqcloud.com/avator/tmp3evp1xxl.png"

struct MessageView: View {
    @State private var messages: [Message] = sampleMessages()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                // 添加标题
                Text("发送私信")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.white)
                    .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
                
                Spacer()
                Spacer()
                
                // 消息列表
                List {
                    ForEach(messages) { message in
                        MessageContextView(message: message)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "tray.full")
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "plus.circle")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}



struct MessageContextView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(message.avatarName)
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    message.unreadCount > 0 ?
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(message.unreadCount)")
                                .foregroundColor(.white)
                                .font(.caption2)
                        )
                        .offset(x: 15, y: -15)
                    : nil
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(message.senderName)
                    .font(.headline)
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(message.timeAgo)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}



