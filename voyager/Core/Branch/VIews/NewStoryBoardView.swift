//
//  NewStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI

struct NewStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    // params
    @State public var storyId: Int64
    @State public var boardId: Int64
    @State public var prevBoardId: Int64
    @Binding var viewModel: StoryViewModel
    
    // input
    @State public var title: String = ""
    @State public var description: String = ""
    @State public var background: String = ""
    @State public var roles: [StoryRole]
    @State public var images: [UIImage]?
    
    // tech detail
    @State public var prompt = ""
    @State public var nevigatePrompt = ""
    
    // generated detail
    @State public var generatedStoryTitle: String = ""
    @State public var generatedStoryContent: String = ""
    @State public var generatedImage: UIImage?
    
    @State public var showImagePicker: Bool = false
    @State var err: Error?
    
    let isForkingStory: Bool

    // Add states for tracking completion status
    @State private var isInputCompleted: Bool = false
    @State private var isStoryGenerated: Bool = false
    @State private var isImageGenerated: Bool = false
    @State private var isNarrationCompleted: Bool = false
    
    // Add states for story scene details
    @State private var sceneDescription: String = ""
    @State private var sceneCharacters: String = ""
    @State private var imagePrompt: String = ""

    // Add state for current step
    @State private var currentStep: TimelineStep = .write

    // Add states for notifications
    @State private var isLoading: Bool = false
    @State private var loadingMessage: String = ""
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    @State private var notificationType: NotificationType = .success

    // 添加一个变量来记录最后执行的操作
    @State private var lastOperation: (() async -> Void)?

    // 添加状态变量
    @State private var editingSceneIndex: Int?
    @State private var editedContent: String = ""
    @State private var editedCharacters: String = ""
    @State private var editedImagePrompt: String = ""
    @State private var isEditing: Bool = false
    @State private var isRegenerating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(isForkingStory ? "故事分支" : "新的故事板")
                    .font(.largeTitle)
                    .padding()
                
                // Content sections with TabView
                contentSections
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Bottom timeline buttons
            timelineButtons
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .edgesIgnoringSafeArea(.bottom)
                )
        }
        .overlay(loadingOverlay)
        .overlay(notificationOverlay)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $images)
        }
    }
    
    // Enhanced loading overlay with consistent style
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    // Loading icon with rotation animation
                    Image(systemName: "hourglass.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.indigo)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: isLoading
                        )
                    
                    // Title
                    Text("加载中")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    // Loading message
                    Text(loadingMessage)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                .frame(width: 300)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(), value: isLoading)
            }
        }
    }
    
    // Notification overlay for success/error messages
    private var notificationOverlay: some View {
        Group {
            if showNotification {
                VStack(spacing: 20) {
                    // Icon
                    if isLoading {
                        Image(systemName: "hourglass.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.indigo)
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1)
                                    .repeatForever(autoreverses: false),
                                value: isLoading
                            )
                    }
                    
                    // Title
                    Text(notificationType == .success ? "成功" : "提示")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    // Message
                    Text(notificationMessage)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Buttons
                    if notificationType == .error {
                        HStack(spacing: 16) {
                            // Cancel button
                            Button(action: { hideNotification() }) {
                                Text("取消")
                                    .foregroundColor(.gray)
                                    .frame(width: 90, height: 44)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(22)
                            }
                            
                            // Retry button
                            Button(action: {
                                hideNotification()
                                // 重试上一次失败的操作
                                retryLastOperation()
                            }) {
                                Text("重试")
                                    .foregroundColor(.white)
                                    .frame(width: 90, height: 44)
                                    .background(Color.indigo)
                                    .cornerRadius(22)
                            }
                        }
                    } else {
                        // Single confirm button for success
                        Button(action: { hideNotification() }) {
                            Text("确定")
                                .foregroundColor(.white)
                                .frame(width: 200, height: 44)
                                .background(Color.indigo)
                                .cornerRadius(22)
                        }
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                .frame(width: 300)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(), value: showNotification)
            }
        }
    }
    
    // Helper functions for notifications
    private func showNotification(message: String, type: NotificationType, operation: (() async -> Void)? = nil) {
        withAnimation {
            notificationMessage = message
            notificationType = type
            showNotification = true
            if type == .error {
                lastOperation = operation
            }
        }
    }
    
    private func hideNotification() {
        withAnimation {
            showNotification = false
        }
    }
    
    // MARK: - View Components
    private var contentSections: some View {
        TabView(selection: $currentStep) {
            // Write step - Basic info and characters
            VStack(alignment: .leading, spacing: 10) {
                storyBasicInfoSection
                charactersSection
            }
            .padding(.horizontal)
            .tag(TimelineStep.write)
            
            // Complete step - Generated story content
            VStack(alignment: .leading, spacing: 25) {
                if !generatedStoryTitle.isEmpty || !generatedStoryContent.isEmpty {
                    generatedContentSection
                }
            }
            .padding(.horizontal)
            .tag(TimelineStep.complete)
            
            // Draw step - Image generation and prompts
            VStack(alignment: .leading, spacing: 25) {
                if viewModel.storyScenes.isEmpty {
                    // 空状态提示
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("暂无场景数据")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("请先生成故事场景")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            Task {
                                await generateStoryboardPrompt()
                            }
                        }) {
                            Text("生成场景")
                                .foregroundColor(.white)
                                .frame(width: 200, height: 44)
                                .background(Color.blue)
                                .cornerRadius(22)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    // 场景列表
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(viewModel.storyScenes, id: \.sceneIndex) { scene in
                                VStack(alignment: .leading, spacing: 16) {
                                    // 场景编号
                                    HStack {
                                        Text("场景 \(scene.sceneIndex)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    
                                    // 场景故事
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("场景故事")
                                            .font(.headline)
                                        TextEditor(text: .constant(scene.content))
                                            .frame(minHeight: 50)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .disabled(true)
                                    }
                                    
                                    // 参与人物
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("参与人物")
                                            .font(.headline)
                                        TextEditor(text: .constant(scene.characters))
                                            .frame(minHeight: 50)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .disabled(true)
                                    }
                                    
                                    // 图片提示词
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("图片生成提示词")
                                            .font(.headline)
                                        TextEditor(text: .constant(scene.imagePrompt))
                                            .frame(minHeight: 50)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .disabled(true)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .tag(TimelineStep.draw)
            
            // Narrate step - Final display
            VStack(alignment: .leading, spacing: 25) {
                if let generatedImage = generatedImage {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("生成的场景")
                            .font(.headline)
                        
                        Image(uiImage: generatedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                        
                        Text("场景描述")
                            .font(.headline)
                        Text(sceneDescription)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("参与人物")
                            .font(.headline)
                        Text(sceneCharacters)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .tag(TimelineStep.narrate)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
    }
    
    private var timelineButtons: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress bar
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: calculateProgress(totalWidth: geometry.size.width), height: 4)
                        .animation(.easeInOut, value: calculateProgressValue())
                }
            }
            .frame(height: 4)
            .padding(.top, 8)
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            // Timeline buttons
            HStack(spacing: 20) {
                ForEach(TimelineStep.allCases, id: \.self) { step in
                    TimelineButton(
                        title: step.title,
                        icon: step.icon,
                        isCompleted: step.isCompleted(
                            isInputCompleted: isInputCompleted,
                            isStoryGenerated: isStoryGenerated,
                            isImageGenerated: isImageGenerated,
                            isNarrationCompleted: isNarrationCompleted
                        ),
                        action: {
                            handleTimelineAction(step)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }
    
    // Helper function to calculate progress bar width
    private func calculateProgress(totalWidth: CGFloat) -> CGFloat {
        let progressValue = calculateProgressValue()
        return totalWidth * progressValue
    }
    
    // Helper function to calculate progress value (0.0 to 1.0)
    private func calculateProgressValue() -> CGFloat {
        var completedSteps = 0
        
        if isInputCompleted { completedSteps += 1 }
        if isStoryGenerated { completedSteps += 1 }
        if isImageGenerated { completedSteps += 1 }
        if isNarrationCompleted { completedSteps += 1 }
        
        return CGFloat(completedSteps) / CGFloat(TimelineStep.allCases.count)
    }
    
    private func handleTimelineAction(_ step: TimelineStep) {
        withAnimation {
            currentStep = step
        }
        
        switch step {
        case .write:
            Task {
//                guard validateInput() else {
//                    showNotification(message: "请填写所有必要信息", type: .error)
//                    return
//                }
                showLoading(message: "正在生成故事内容...")
                do {
                    isInputCompleted = true
                    await generateStory()
                    isStoryGenerated = true
                    hideLoading()
                    showNotification(message: "故事生成成功", type: .success)
                } catch {
                    handleError(error)
                }
            }
        case .complete:
            Task {
                guard isStoryGenerated else { return }
                showLoading(message: "正在创建故事板...")
                do {
                    await saveStoryBoard()
                    hideLoading()
                    showNotification(message: "故事板创建成功", type: .success)
                } catch {
                    handleError(error)
                }
            }
        case .draw:
            Task {
                guard isStoryGenerated else { return }
                showLoading(message: "正在生成场景图片...")
                do {
                    await generateStoryboardPrompt()
                    isImageGenerated = true
                    hideLoading()
                    showNotification(message: "场景图片生成成功", type: .success)
                } catch {
                    handleError(error)
                }
            }
        case .narrate:
            Task {
                guard isImageGenerated else { return }
                showLoading(message: "正在发布故事...")
                do {
                    try? await publishStoryBoard()
                    isNarrationCompleted = true
                    hideLoading()
                    showNotification(message: "故事发布成功", type: .success)
                    // 可能需要在发布成功后关闭当前视图
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    private func validateInput() -> Bool {
        !title.isEmpty && !description.isEmpty && !background.isEmpty && !roles.isEmpty
    }
    
    private var storyBasicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("标题")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("请输入标题", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("描述")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Background
            VStack(alignment: .leading, spacing: 8) {
                Text("背景设定")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $background)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("角色设定")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    Button(action: {
                        // 添加新角色的操作
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                            Text("添加角色")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("图片素材")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Image picker button
            Button(action: { showImagePicker = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("选择图片")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Selected images
            if let images = images {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var generatedContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Generated content
            if !generatedStoryTitle.isEmpty || !generatedStoryContent.isEmpty {
                Text("生成的故事内容")
                    .font(.headline)
                    .foregroundColor(.primary)
                VStack(alignment: .leading, spacing: 12) {
                    Text("标题")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(generatedStoryTitle)
                        .font(.title2)
                        .padding(.vertical, 4)
                    Text("内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(generatedStoryContent)
                        .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// MARK: - Supporting Views
struct TimelineButton: View {
    let title: String
    let icon: String
    var isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// Timeline Step Enum
enum TimelineStep: CaseIterable {
    case write
    case complete
    case draw
    case narrate
    
    var title: String {
        switch self {
        case .write: return "续写"
        case .complete: return "创建"
        case .draw: return "绘画"
        case .narrate: return "发布"
        }
    }
    
    var icon: String {
        switch self {
        case .write: return "pencil.circle"
        case .complete: return "checkmark.circle"
        case .draw: return "paintbrush.fill"
        case .narrate: return "text.bubble"
        }
    }
    
    func isCompleted(
        isInputCompleted: Bool,
        isStoryGenerated: Bool,
        isImageGenerated: Bool,
        isNarrationCompleted: Bool
    ) -> Bool {
        switch self {
        case .write: return isInputCompleted
        case .complete: return isStoryGenerated
        case .draw: return isImageGenerated
        case .narrate: return isNarrationCompleted
        }
    }
    
    func color(
        isInputCompleted: Bool,
        isStoryGenerated: Bool,
        isImageGenerated: Bool,
        isNarrationCompleted: Bool
    ) -> Color {
        let completed = isCompleted(
            isInputCompleted: isInputCompleted,
            isStoryGenerated: isStoryGenerated,
            isImageGenerated: isImageGenerated,
            isNarrationCompleted: isNarrationCompleted
        )
        return completed ? Color.green.opacity(0.6) : Color.red.opacity(0.6)
    }
}

// Notification type enum
enum NotificationType {
    case success
    case error
    case warning
    
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .yellow
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.3)
        case .error: return Color.red.opacity(0.3)
        case .warning: return Color.yellow.opacity(0.3)
        }
    }
}

// Error handling extension
extension NewStoryBoardView {
    private func handleError(_ error: Error) {
        hideLoading()
        showNotification(
            message: "操作失败: \(error.localizedDescription)",
            type: .error
        )
    }
    
    // Helper functions for loading state
    private func showLoading(message: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.loadingMessage = message
            self.isLoading = true
        }
    }
    
    private func hideLoading() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    // Example usage in async operations
    private func generateStory() async {
        do {
            showLoading(message: "正在生成故事内容...")
            let ret = await self.viewModel.conintueGenStory(
                storyId: self.viewModel.storyId,
                userId: self.viewModel.userId,
                prevBoardId: self.boardId,
                prompt: self.prompt,
                title: self.title,
                desc: self.description,
                backgroud: self.background
            )
            
            if let firstResult = ret.0.result.values.first {
                self.generatedStoryTitle = firstResult.data["章节题目"]?.text ?? ""
                self.generatedStoryContent = firstResult.data["章节内容"]?.text ?? ""
                hideLoading()
                print(" value.first : ",ret.0.result.values.first!)
                print("self.generatedStoryTitle ",self.generatedStoryTitle)
                print("self.generatedStoryContent ",self.generatedStoryContent)
                if self.generatedStoryTitle.count == 0 || self.generatedStoryContent.count == 0 {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成故事失败"])
                }else{
                    showNotification(message: "故事生成成功", type: .success)
                }
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成故事失败"])
            }
        } catch {
            hideLoading()
            // 传入重试操作
            showNotification(
                message: "操作失败: \(error.localizedDescription)", 
                type: .error,
                operation: { [self] in 
                    await generateStory()
                }
            )
        }
    }
    
    private func saveStoryBoard() async {
        do {
            showLoading(message: "正在创建故事板...")
            let ret = await self.viewModel.createStoryBoard(
                prevBoardId: self.boardId,
                nextBoardId: 0,
                title: self.generatedStoryTitle,
                content: self.generatedStoryContent,
                isAiGen: true,
                backgroud: self.background,
                params: Common_StoryBoardParams()
            )
            
            if let error = ret.1 {
                throw error
            } else {
                hideLoading()
                showNotification(message: "故事板创建成功", type: .success)
            }
        } catch {
            handleError(error)
        }
    }
    
    private func generateStoryboardPrompt() async {
        do {
            showLoading(message: "正在生成故事提示词...")
            // Add your image generation logic here
            let ret = await self.viewModel.genStoryBoardPrompt(
                storyId: self.storyId, 
                boardId: self.boardId, 
                userId: self.viewModel.userId, 
                renderType: Common_RenderType(rawValue: 1)!)
            if let err = ret{
                throw err
            }else{
                hideLoading()
                showNotification(message: "故事图片提示词生成成功", type: .success)
            }
            print("generateStoryboardPrompt ")
        } catch {
            handleError(error)
        }
    }
    
    private func generateStoryboardImage() async {
        do {
            showLoading(message: "正在生成故事图片...")
            // Add your image generation logic here
            let ret = await self.viewModel.genStoryBoardImages(storyId: self.storyId, boardId: self.boardId, userId: self.viewModel.userId, renderType: Common_RenderType(rawValue: 1)!)
            if let err = ret{
                throw err
            }else{
                hideLoading()
                showNotification(message: "故事图片生成成功", type: .success)
            }
        } catch {
            handleError(error)
        }
    }
    
    private func updateStoryBoardWithScene() async {
        do {
            showLoading(message: "正在更新故事场景...")
            // Add your scene update logic here
            // await viewModel.updateStoryBoardScene(...)
            
            hideLoading()
            showNotification(message: "场景更新成功", type: .success)
        } catch {
            handleError(error)
        }
    }

    // 重试功能
    private func retryLastOperation() {
        if let operation = lastOperation {
            Task {
                await operation()
            }
        }
    }

    // 添加发布相关的方法
    private func publishStoryBoard() async throws {
        // 这里实现发布故事的具体逻辑
        // 例如: 上传图片、更新状态等
        do {
            // 1. 上传生成的图片
            if generatedImage != nil {
                // await uploadImage(image)
            }
            
            // 2. 更新故事板状态为已发布
            let ret: () = await viewModel.publishStoryboard(
                storyId: self.storyId,
                boardId: self.boardId,
                userId: self.viewModel.userId,
                status: 5  // 假设有这样的状态枚举
            )
            
            if ret != nil {
                self.err = ret as? any Error
            }
        } catch {
            throw error
        }
    }

    // 修改加载消息
    private var loadingMessages: [TimelineStep: String] {
        [
            .write: "正在生成故事内容...",
            .complete: "正在创建故事板...",
            .draw: "正在生成场景图...",
            .narrate: "正在发布故事..."
        ]
    }

    // 修改成功消息
    private var successMessages: [TimelineStep: String] {
        [
            .write: "故事生成成功",
            .complete: "故事板创建成功",
            .draw: "场景图片生成成功",
            .narrate: "故事发布成功"
        ]
    }

    // 修改验证逻辑
    private func validateStep(_ step: TimelineStep) -> Bool {
        switch step {
        case .write:
            return !title.isEmpty && !description.isEmpty && !background.isEmpty
        case .complete:
            return isStoryGenerated
        case .draw:
            return isStoryGenerated && !sceneDescription.isEmpty
        case .narrate:
            return isImageGenerated && generatedImage != nil
        }
    }
}
