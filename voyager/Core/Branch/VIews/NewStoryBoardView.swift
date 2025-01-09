//
//  NewStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI

struct NewStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    
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
    
    @State public var isForkingStory = false
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                StepNavigationView(
                    currentStep: TimelineStep.allCases.firstIndex(of: currentStep) ?? 0,
                    totalSteps: TimelineStep.allCases.count,
                    titles: TimelineStep.allCases.map { $0.title }
                )
                .padding(.vertical, 2)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content area
                TabView(selection: $currentStep) {
                    StoryInputView(
                        title: $title,
                        description: $description,
                        background: $background,
                        roles: $roles,
                        generatedStoryTitle: $generatedStoryTitle,
                        generatedStoryContent: $generatedStoryContent,
                        isGenerated:$isStoryGenerated,
                        onGenerate: {
                            // 处理生成逻辑
                            Task{
                                print("StoryInputView onGenerate")
                                await generateStory()
                            }
                        },
                        onSave: {
                            // 处理保存逻辑
                            Task{
                                print("StoryInputView onSave")
                                await saveStoryBoard()
                            }
                        }
                    )
                    .tag(TimelineStep.write)
                    
                    StoryContentView(
                        generatedStoryTitle: $generatedStoryTitle,
                        generatedStoryContent: $generatedStoryContent,
                        onGenerate: {
                            // 处理生成逻辑
                            Task{
                                print("StoryContentView generateStoryboardPrompt")
                                await generateStoryboardPrompt()
                            }
                        },
                        onSave: {
                            // 处理保存逻辑
                            Task{
                                print("StoryContentView apply all sences")
                                await ApplyAllsences()
                            }
                        }
                    )
                    .tag(TimelineStep.complete)
                    
                    SceneGenerationView(
                        viewModel: $viewModel,
                        onGenerateImage: handleGenerateImageAction,
                        onGenerateAllImage: GenerateAllSenseImageAction
                    )
                    .tag(TimelineStep.draw)
                    
                    StoryPublishView(
                        generatedImage: $generatedImage,
                        sceneDescription: $sceneDescription,
                        sceneCharacters: $sceneCharacters,
                        onSaveOnly:{
                            // 仅保存
                        },
                        onPublish: {
                            // 发布
                        }
                    )
                    .tag(TimelineStep.narrate)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                Divider()
                
                // Bottom navigation buttons
                HStack(spacing: 4) {
                    // Back button
                    Button(action: handlePreviousStep) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(.circle)
                    }
                    .opacity(canGoBack ? 1 : 0.5)
                    .disabled(!canGoBack)
                    
                    // Next button
                    Button(action: handleNextStep) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.blue)
                        .clipShape(.circle)
                    }
                    .opacity(canGoForward ? 1 : 0.5)
                    .disabled(!canGoForward)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
            }
        }
        .navigationViewStyle(.stack)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    private var canGoBack: Bool {
        currentStep != TimelineStep.allCases.first
    }
    
    private var canGoForward: Bool {
        currentStep != TimelineStep.allCases.last
    }
    
    private func handlePreviousStep() {
        if let currentIndex = TimelineStep.allCases.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation {
                currentStep = TimelineStep.allCases[currentIndex - 1]
            }
        }
    }

    private func handleNextStep() {
        // 验证当前步骤
        if !validateCurrentStep() {
            return
        }
        
        // 获取当前步骤索引
        if let currentIndex = TimelineStep.allCases.firstIndex(of: currentStep),
           currentIndex < TimelineStep.allCases.count - 1 {
            
            // 处理特殊步骤的逻辑
            switch currentStep {
            case .write:
                // 如果是写作步骤，可能需要保存或处理输入内容
            case .complete:
                // 如果是完成步骤，可能需要生成或处理内容
            case .draw:
                // 如果是绘画步骤，可能需要处理场景生成
            default:
                break
            }
            
            // 切换到下一步
            withAnimation {
                currentStep = TimelineStep.allCases[currentIndex + 1]
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .write:
            // 验证写作步骤的输入
            if title.isEmpty {
                showValidationAlert("请输入标题")
                return false
            }
            if description.isEmpty {
                showValidationAlert("请输入描述")
                return false
            }
            if background.isEmpty {
                showValidationAlert("请输入背景设定")
                return false
            }
            
        case .complete:
            // 验证完成步骤
            if generatedStoryContent.isEmpty {
                showValidationAlert("请等待故事生成完成")
                return false
            }
            
        case .draw:
            // 验证绘画步骤
            if viewModel.storyScenes.isEmpty {
                showValidationAlert("请先生成场景")
                return false
            }
            
        case .narrate:
            // 验证发布步骤
            if generatedImage == nil {
                showValidationAlert("请先生成图片")
                return false
            }
        }
        
        return true
    }
    
    private func showValidationAlert(_ message: String) {
        validationMessage = message
        showingValidationAlert = true
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
    
    private var SenceGenEmptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("暂无场景数据")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Text("点击下方按钮生成故事场景")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ActionButton(
                title: "生成场景",
                icon: "wand.and.stars",
                color: .blue
            ) {
                Task {
                    await generateStoryboardPrompt()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // 1. 修改 SceneCardView 的样式
    private struct SceneCardView: View {
        let scene: StoryBoardSence
        let index: Int
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // 场景标题栏
                HStack {
                    Text("场景 \(scene.senceIndex)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // 内容区域
                VStack(alignment: .leading, spacing: 16) {
                    contentSection("场景故事", content: scene.content)
                    contentSection("参与人物", content: scene.characters)
                    contentSection("图片提示词", content: scene.imagePrompt)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        
        private func contentSection(_ title: String, content: String) ->some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }

    // 2. 修改控制按钮样式
    private func SenceGenControlView(idx: Int, senceId:Int64) -> some View {
        HStack(spacing: 12) {
            // 应用按钮
            ActionButton(
                title: "应用",
                icon: "checkmark.circle.fill",
                color: .blue
            ) {
                Task {
                    await handleApplyAction(idx: idx)
                }
            }
            
            // 生成图片按钮
            ActionButton(
                title: "生成图片",
                icon: "photo.fill",
                color: .green
            ) {
                Task {
                    await handleGenerateImageAction(idx: idx)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }


    // 3. 修改 SenceGenListView
    private var SenceGenListView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                ForEach(Array(viewModel.storyScenes.enumerated()), id: \.element.senceIndex) { index, scene in
                    SceneCardView(scene: scene,index:index)
                    SenceGenControlView(idx: index, senceId: scene.senceId)
                }
            }
            .padding(.horizontal)
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
    
    private func generateStory() async {
        do {
            print("正在生成故事内容...")
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
                //hideLoading()
                if self.generatedStoryTitle.count == 0 || self.generatedStoryContent.count == 0 {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成故事失败"])
                }else{
                    showNotification(message: "故事生成成功", type: .success)
                    print("故事生成成功")
                }
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成故事失败"])
            }
        } catch {
//            hideLoading()
//            // 传入重试操作
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
                showNotification(message: "故事板创建成功", type: .success)
            }
        } catch {
            handleError(error)
        }
    }
    
    private func generateStoryboardPrompt() async {
        do {
            let ret = await self.viewModel.genStoryBoardPrompt(
                storyId: self.storyId, 
                boardId: self.boardId, 
                userId: self.viewModel.userId, 
                renderType: Common_RenderType(rawValue: 1)!)
            if let err = ret{
                throw err
            }else{
                showNotification(message: "故事图片提示词生成成功", type: .success)
            }
            print("generateStoryboardPrompt ")
        } catch {
            handleError(error)
        }
    }
    
    private func generateStoryboardImage() async {
        do {
            // Add your image generation logic here
            let ret = await self.viewModel.genStoryBoardImages(storyId: self.storyId, boardId: self.boardId, userId: self.viewModel.userId, renderType: Common_RenderType(rawValue: 1)!)
            if let err = ret{
                throw err
            }else{
                showNotification(message: "故事图片生成成功", type: .success)
            }
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
            //  更新故事板状态为已发布
            let ret: () = await viewModel.publishStoryboard(
                storyId: self.storyId,
                boardId: self.boardId,
                userId: self.viewModel.userId,
                status: 5  // 假设有这样的状态枚举
            )
            
            if ret != nil {
                self.err = ret as? any Error
            }
            DispatchQueue.main.async {
                isPresented = false
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

// 添加操作处理方法
extension NewStoryBoardView {
    private func handleApplyAction(idx: Int) async {
        do {
            let (senceId, err) = await viewModel.createStoryboardSence(
                idx: idx,
                boardId: boardId
            )
            hideLoading()
            
            if let err = err {
                throw err
            }
            viewModel.storyScenes[idx].senceId = senceId
        } catch {
            handleError(error)
        }
    }
    
    private func ApplyAllsences() async {
        do {
            // 使用普通的 for 循环
            for (index, _) in viewModel.storyScenes.enumerated() {
                let (senceId, err) = await viewModel.createStoryboardSence(
                    idx: index,
                    boardId: boardId
                )
                
                if let err = err {
                    throw err
                }
                
                // 更新场景ID
                viewModel.storyScenes[index].senceId = senceId
            } 
            hideLoading()
            showNotification(message: "所有场景应用成功", type: .success)
            
        } catch {
            hideLoading()
            handleError(error)
        }
    }
    
    private func handleGenerateImageAction(idx: Int) async {
        showLoading(message: "正在生成场景图片...")
        do {
            let err = await viewModel.genStoryBoardSpecSence(
                storyId: storyId,
                boardId: boardId,
                userId: viewModel.userId,
                senceId: viewModel.storyScenes[idx].senceId,
                renderType: Common_RenderType(rawValue: 1)!
            )
            
            hideLoading()
            
            if let err = err {
                throw err
            }
            
            showNotification(message: "场景图片生成成功", type: .success)
        } catch {
            handleError(error)
        }
    }
    
    private func GenerateAllSenseImageAction() async {
        showLoading(message: "正在生成场景图片...")
        do {
            for (index, scene) in viewModel.storyScenes.enumerated() {
                let err = await viewModel.genStoryBoardSpecSence(
                    storyId: storyId,
                    boardId: boardId,
                    userId: viewModel.userId,
                    senceId: viewModel.storyScenes[index].senceId,
                    renderType: Common_RenderType(rawValue: 1)!
                )
                if let err = err {
                    throw err
                }
            }
            
            hideLoading()
            showNotification(message: "场景图片生成成功", type: .success)
        } catch {
            handleError(error)
        }
    }
}

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<totalSteps, id: \.self) { index in
                HStack(spacing: 4) {
                    // Step circle
                    Circle()
                        .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(index + 1)")
                                .foregroundColor(index == currentStep ? .white : .gray)
                                .font(.system(size: 14, weight: .medium))
                        )
                    
                    // Connecting line
                    if index < totalSteps - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}


struct StoryPublishView: View {
    @Binding var generatedImage: UIImage?
    @Binding var sceneDescription: String
    @Binding var sceneCharacters: String
    let onSaveOnly: () async -> Void
    let onPublish: () async -> Void
    
    @State private var isSaving = false
    @State private var isPublishing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                if let image = generatedImage {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("生成的场景")
                            .font(.headline)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        
                        InfoSection(title: "场景描述", content: sceneDescription)
                        InfoSection(title: "参与人物", content: sceneCharacters)
                        
                        // 添加操作按钮
                        HStack(spacing: 16) {
                            ActionButton(
                                title: "保存",
                                icon: "square.and.arrow.down",
                                color: .blue,
                                action: {
                                    Task {
                                        await handleSave()
                                    }
                                }
                            )
                            
                            ActionButton(
                                title: "发布",
                                icon: "paperplane.fill",
                                color: .green,
                                action: {
                                    Task {
                                        await handlePublish()
                                    }
                                }
                            )
                        }
                        .padding(.top, 16)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("等待生成场景图片")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .padding()
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleSave() async {
        isSaving = true
        do {
            await onSaveOnly()
            alertMessage = "保存成功"
            showAlert = true
        } catch {
            alertMessage = "保存失败：\(error.localizedDescription)"
            showAlert = true
        }
        isSaving = false
    }
    
    private func handlePublish() async {
        isPublishing = true
        do {
            // 如果未保存，先保存
            await onSaveOnly()
            // 然后发布
            await onPublish()
            alertMessage = "发布成功"
            showAlert = true
        } catch {
            alertMessage = "发布失败：\(error.localizedDescription)"
            showAlert = true
        }
        isPublishing = false
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}


struct SceneGenerationView: View {
    @Binding var viewModel: StoryViewModel
    let onGenerateImage: (Int) async -> Void
    let onGenerateAllImage: () async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部生成按钮
            ActionButton(
                title: "生成所有场景图片",
                icon: "photo.fill",
                color: .green
            ) {
                Task {
                    await onGenerateAllImage()
                }
            }
            .padding(.horizontal)
            
            // 场景列表
            if viewModel.storyScenes.isEmpty {
                EmptyStateView()
            } else {
                
                SceneListView(
                    scenes: viewModel.storyScenes,
                    onGenerateImage: onGenerateImage
                )
            }
        }
    }
}

// 拆分出空状态视图
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("暂无场景数据")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 拆分出场景列表视图
private struct SceneListView: View {
    let scenes: [StoryBoardSence]
    let onGenerateImage: (Int) async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 修改 ForEach 的实现，使用索引作为唯一标识
                ForEach(0..<scenes.count, id: \.self) { index in
                    NewSceneItemView(
                        scene: scenes[index],
                        index: index,
                        onGenerateImage: onGenerateImage
                    )
                }
            }
            .padding()
        }
    }
}

// 拆分出单个场景项视图
private struct NewSceneItemView: View {
    let scene: StoryBoardSence
    let index: Int
    let onGenerateImage: (Int) async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            SceneCard(scene: scene)
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "生成图片",
                    icon: "photo.fill",
                    color: .green
                ) {
                    Task {
                        await onGenerateImage(index)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

struct SceneCard: View {
    let scene: StoryBoardSence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Scene header
            HStack {
                Text("场景 \(scene.senceIndex)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Content sections
            VStack(alignment: .leading, spacing: 16) {
                contentSection("场景故事", content: scene.content)
                contentSection("参与人物", content: scene.characters)
                contentSection("图片提示词", content: scene.imagePrompt)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func contentSection(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct StoryContentView: View {
    @Binding var generatedStoryTitle: String
    @Binding var generatedStoryContent: String
    
    // 添加回调函数
    var onGenerate: () -> Void = {}
    var onSave: () -> Void = {}
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !generatedStoryTitle.isEmpty || !generatedStoryContent.isEmpty {
                    Text("生成的故事内容")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("标题")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(generatedStoryTitle)
                                .font(.title2)
                                .padding(.vertical, 4)
                        }
                        
                        Divider()
                        
                        // Content section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("内容")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(generatedStoryContent)
                                .font(.body)
                        }
                        
                        // 添加按钮组
                        HStack(spacing: 16) {
                            Button(action: onGenerate) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("生成场景")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: onSave) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("保存")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("等待生成故事内容")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .padding()
        }
    }
}

struct StoryInputView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var background: String
    @Binding var roles: [StoryRole]
    
    // 添加生成内容的状态
    @Binding var generatedStoryTitle: String
    @Binding var generatedStoryContent: String
    @Binding var isGenerated: Bool
    
    // 添加回调函数
    var onGenerate: () async -> Void// 返回生成的标题和内容
    var onSave: () async -> Void // 保存编辑后的标题和内容
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputSection
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.keyboard)
    }
    
    // 输入部分视图
    private var inputSection: some View {
        VStack(spacing: 24) {
            InputField(
                title: "标题",
                placeholder: "请输入标题",
                text: $title
            )
            
            InputField(
                title: "描述",
                placeholder: "请输入描述",
                text: $description,
                isMultiline: true
            )
            
            InputField(
                title: "背景设定",
                placeholder: "请输入背景设定",
                text: $background,
                isMultiline: true
            )
            
            roleSection
            // 生成按钮
            HStack{
                Spacer()
                Button(action: {
                    Task {
                        await onGenerate()
                        isGenerated = true
                    }
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("生成故事")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
                Button(action: {
                    Task {
                        await onSave()
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            }
            
        }
    }
    
    
    // 角色设定部分
    private var roleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("角色设定")
                .font(.headline)
                .foregroundColor(.primary)
            
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
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

struct StepNavigationView: View {
    let currentStep: Int
    let totalSteps: Int
    let titles: [String]
    
    // 定义颜色常量
    private let activeColor = Color.blue
    private let inactiveColor = Color.gray.opacity(0.15)
    private let backgroundColor = Color(.systemGray6) // 浅灰色背景
    
    var body: some View {
        VStack(spacing: 8) {
            // Steps with connecting lines
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    HStack(spacing: 0) {
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(getStepColor(for: index))
                                .frame(width: 24, height: 24)
                            
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(index <= currentStep ? .white : .gray)
                        }
                        
                        // Connecting line
                        if index < totalSteps - 1 {
                            Rectangle()
                                .fill(index < currentStep ? getStepColor(for: index) : inactiveColor)
                                .frame(height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Step titles
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Text(titles[index])
                        .font(.system(size: 11))
                        .foregroundColor(getTextColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(backgroundColor)
    }
    
    // 获取步骤颜色
    private func getStepColor(for index: Int) -> Color {
        switch index {
            case _ where index < currentStep:
                return .green // 已完成的步骤显示为绿色
            case currentStep:
                return activeColor // 当前步骤显示为蓝色
            default:
                return inactiveColor // 未完成的步骤显示为灰色
        }
    }
    
    // 获取文字颜色
    private func getTextColor(for index: Int) -> Color {
        switch index {
            case _ where index < currentStep:
                return .green // 已完成的步骤文字显示为绿色
            case currentStep:
                return activeColor // 当前步骤文字显示为蓝色
            default:
                return .gray // 未完成的步骤文字显示为灰色
        }
    }
}

// 3. 添加通用按钮组件
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(20)
        }
    }
}

