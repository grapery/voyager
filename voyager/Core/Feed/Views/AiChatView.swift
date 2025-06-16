//
//  AiChatView.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/16.
//


// 发现视图

import SwiftUI
import Kingfisher
import ActivityIndicatorView

struct DiscoveryView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage]
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isFocused: Bool
    @State private var isShowingKeyboard = false
    @State private var navigateToStory = false
    @State private var selectedStory: Story?
    @Binding var showTabBar: Bool
    
    init(viewModel: FeedViewModel, messageText: String, showTabBar: Binding<Bool>) {
        self.viewModel = viewModel
        self.messageText = ""
        self.messages = [ChatMessage]()
        self._showTabBar = showTabBar
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 聊天消息区背景
            TrapezoidTriangles()
                .opacity(0.81)
                .ignoresSafeArea()
            // 内容区域
            VStack(spacing: 0) {
                // 聊天消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                // 空状态
                                VStack {
                                    Spacer()
                                    Text("没有聊天消息")
                                        .foregroundColor(.gray)
                                        .padding()
                                    Spacer()
                                }
                            } else {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .padding(.horizontal, 16)
                                        .id(message.id)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .onTapGesture {
                                            if message.msg.sender == 42 { // AI消息可点击查看故事
                                                handleMessageTap(message)
                                            }
                                        }
                                }
                                
                                Color.clear
                                    .frame(height: 10)
                                    .id("bottom")
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .background(Color.theme.background.opacity(0.85))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isFocused {
                            isFocused = false
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            // 键盘隐藏按钮 - 只在键盘显示时出现
            if isFocused {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isFocused = false
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.gray.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                    }
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: keyboardHeight > 0 ? keyboardHeight - 45 : 0)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
            // 新输入栏
            InputBar(
                text: $messageText,
                isFocused: $isFocused,
                onSend: sendMessage
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(
            // 导航链接跳转到故事页
            NavigationLink(value: selectedStory) {
                EmptyView()
            }
        )
        .onAppear {
            self.showTabBar = false
            setupInitialMessages()
            setupKeyboardNotifications()
        }
        .onDisappear {
            self.showTabBar = true
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func handleMessageTap(_ message: ChatMessage) {
        print("tap message: ",message as Any)
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self.keyboardHeight = 0
            }
        }
    }
    
    private func setupInitialMessages() {
        var msg1 = Common_ChatMessage()
        msg1.message = "欢迎您来到AI世界，请问您有什么想要了解的事情呢？"
        msg1.sender = 42
        msg1.roleID = 42
        msg1.userID = 1
        self.messages.append(ChatMessage(id: 1, msg: msg1, status: .MessageSendSuccess))
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 创建用户消息
        var userMsg = Common_ChatMessage()
        userMsg.message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        userMsg.sender = 1
        userMsg.roleID = 42
        userMsg.userID = 1
        
        // 添加用户消息到列表
        withAnimation {
            self.messages.append(ChatMessage(id: Int64(Date().timeIntervalSince1970), msg: userMsg, status: .MessageSendSuccess))
        }
        
        // 清空输入框
        let sentMessage = messageText
        messageText = ""
        
        // 模拟AI回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var aiMsg = Common_ChatMessage()
            aiMsg.message = getAIResponse(to: sentMessage)
            aiMsg.sender = 42
            aiMsg.roleID = 42
            aiMsg.userID = 1
            
            withAnimation {
                self.messages.append(ChatMessage(id: Int64(Date().timeIntervalSince1970), msg: aiMsg, status: .MessageSendSuccess))
            }
        }
    }
    
    // 简单的AI回复逻辑
    private func getAIResponse(to message: String) -> String {
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("你好") || lowercasedMessage.contains("嗨") || lowercasedMessage.contains("hi") {
            return "你好！我是AI助手，很高兴为您服务。点击此消息可以查看推荐故事。"
        } else if lowercasedMessage.contains("名字") {
            return "我是AI助手，您可以叫我小助手。"
        } else if lowercasedMessage.contains("天气") {
            return "抱歉，我目前无法获取实时天气信息。不过我可以回答您其他方面的问题。"
        } else if lowercasedMessage.contains("谢谢") || lowercasedMessage.contains("感谢") {
            return "不客气！有什么问题随时问我。"
        } else {
            return "我理解您说的是'你好'。请问还有其他我能帮助您的吗？"
        }
    }
}

// 新增 InputBar 组件
private struct InputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            .frame(width: 36, height: 36)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("请输入您的问题...")
                        .foregroundColor(Color.gray.opacity(0.8))
                        .padding(.leading, 4)
                }
                TextField("", text: $text)
                    .focused(isFocused)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(18)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(text.isEmpty ? Color.gray.opacity(0.6) : .blue)
                    .rotationEffect(.degrees(45))
            }
            .frame(width: 36, height: 36)
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 0)
        .overlay(
            Divider(), alignment: .top
        )
    }
}

// 更新聊天气泡组件
private struct ChatBubble: View {
    let message: ChatMessage
    
    private var isFromCurrentUser: Bool {
        return message.msg.sender == 1 // 假设1是当前用户ID
    }
    
    private var isClickable: Bool {
        return !isFromCurrentUser // 只有AI消息可点击
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromCurrentUser {
                // AI头像
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("AI")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Spacer()
            }
            
            // 消息气泡
            Text(message.msg.message)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    isFromCurrentUser
                        ? Color.blue.opacity(0.8)
                        : Color(.systemGray5)
                )
                .foregroundColor(isFromCurrentUser ? .white : .black)
                .cornerRadius(18)
                .overlay(
                    isClickable ?
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        : nil
                )
            
            if isFromCurrentUser {
                // 用户头像
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("我")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// 角色统计信息视图
private struct RoleStatsView: View {
    let role: StoryRole
    
    var body: some View {
        HStack(spacing: 16) {
            Label("\(role.role.likeCount)", systemImage: role.role.currentUserStatus.isLiked ? "heart.fill" : "heart")
                .font(.system(size: 12))
                .foregroundColor(Color.red)
            
            Label("\(role.role.followCount)", systemImage: role.role.currentUserStatus.isFollowed ? "bell.fill" : "bell")
                .font(.system(size: 12))
                .foregroundColor(Color.blue)

            Label("\(role.role.storyboardNum)", systemImage: "book")
                .font(.system(size: 12))
                .foregroundColor(Color.theme.tertiaryText)
        }
    }
}

// 角色关注按钮
private struct RoleFollowButton: View {
    let role: StoryRole
    let viewModel: FeedViewModel
    
    var body: some View {
        if role.role.currentUserStatus.isFollowed {
            Button {
                Task {
                    _ = await viewModel.unfollowStoryRole(userId: viewModel.user.userID, roleId: role.Id, storyId: role.role.storyID)
                    role.role.currentUserStatus.isFollowed = false
                }
            } label: {
                Text("已关注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.theme.tertiaryText)
                    .frame(width: 50, height: 24)
                    .background(
                        Capsule()
                            .fill(Color.theme.secondaryBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.tertiaryText, lineWidth: 1)
                    )
            }
        } else {
            Button {
                Task {
                    _ = await viewModel.followStoryRole(userId: viewModel.user.userID, roleId: role.Id, storyId: role.role.storyID)
                    role.role.currentUserStatus.isFollowed = true
                }
            } label: {
                Text("关注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 24)
                    .background(
                        Capsule()
                            .fill(Color.theme.accent)
                    )
            }
        }
    }
}
