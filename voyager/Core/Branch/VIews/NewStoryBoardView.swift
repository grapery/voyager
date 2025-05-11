//
//  NewStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI
import Kingfisher

struct NewStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    
    // params
    @State public var userId: Int64
    @State public var storyId: Int64
    @State public var boardId: Int64
    @State public var prevBoardId: Int64
    @ObservedObject var viewModel: StoryViewModel
    
    // input
    @State public var title: String = ""
    @State public var description: String = ""
    @State public var background: String = ""
    @State public var roles: [StoryRole]?
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

    @Binding var isPresented: Bool

    var body: some View {
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
                    Group{
                        StoryInputView(
                            title: $title,
                            description: $description,
                            background: $background,
                            roles: $roles,
                            generatedStoryTitle: $generatedStoryTitle,
                            generatedStoryContent: $generatedStoryContent,
                            isGenerated:$isStoryGenerated,
                            userId: userId,
                            storyId: storyId,
                            viewModel: viewModel,
                            onGenerate: {
                                // 处理生成逻辑
                                Task{
                                    await generateStory()
                                }
                            },
                            onSave: {
                                // 处理保存逻辑
                                Task{
                                    await saveStoryBoard()
                                }
                            }
                        )
                    }
                    .tag(TimelineStep.write)
                    
                    Group{
                        StoryContentView(
                            generatedStoryTitle: $generatedStoryTitle,
                            generatedStoryContent: $generatedStoryContent,
                            onGenerate: {
                                // 处理生成逻辑
                                Task{
                                    await generateStoryboardPrompt()
                                }
                            },
                            onSave: {
                                // 处理保存逻辑
                                Task{
                                    await ApplyAllsences()
                                }
                            }
                        )
                    }
                    .tag(TimelineStep.complete)
                    
                    Group{
                        SceneGenerationView(
                            viewModel: viewModel,
                            onGenerateImage: handleGenerateImageAction,
                            onGenerateAllImage: GenerateAllSenseImageAction,
                            moreSenseDetail: moreSenseDetailAction
                        )
                    }
                    .tag(TimelineStep.draw)
                    
                    Group{
                        StoryPublishView(
                            viewModel: viewModel,
                            onSaveOnly:{
                            // 仅保存
                            },
                            onPublish: {
                                // 发布
                            }
                        )
                    }
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
            case .write: break
                // 如果是写作步骤，可能需要保存或处理输入内容
            case .complete: break
                // 如果是完成步骤，可能需要生成或处理内容
            case .draw: break
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
                Color.black.opacity(0.2).ignoresSafeArea()
                CustomAlertView(
                    type: notificationType == .success ? .success : (notificationType == .error ? .error : .info),
                    title: notificationType == .success ? "成功" : (notificationType == .error ? "失败" : "提示"),
                    message: notificationMessage,
                    onClose: { hideNotification() },
                    onInfo: { /* 可弹出说明 */ }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        @State private var selectedTab = 0
        let totalScenes: Int
        let viewModel: StoryViewModel
        
        var body: some View {
            VStack(spacing: 12) {
                // 场景指示器
                HStack(spacing: 8) {
                    ForEach(0..<totalScenes, id: \.self) { sceneIndex in
                        Circle()
                            .fill(sceneIndex == selectedTab ? Color.theme.accent : Color.theme.tertiaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 8)
                
                // 场景标题栏
                HStack {
                    Text("故事场景 \(scene.senceIndex)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.theme.primary.opacity(0.1))
                .cornerRadius(8)
                
                // 内容区域 - 使用 TabView 实现横向滚动
                TabView(selection: $selectedTab) {
                    // 场景故事
                    contentSection("场景故事", content: scene.content)
                        .tag(0)
                    
                    // 参与人物
                    characterSection("参与人物", characters: scene.characters)
                        .tag(1)
                    // 场景参考图
                    RefImageSection(title: "场景参考图", sceneIndex: index)
                        .tag(2)
                    // 图片提示词
                    contentSection("图片提示词", content: scene.imagePrompt)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 150)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        
        private func contentSection(_ title: String, content: String) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
                
                ScrollView {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(Color.theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.theme.background)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
        }
        
        private func characterSection(_ title: String, characters: [Common_Character]) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(characters, id: \.id) { character in
                            CharacterButton(character: character)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        // 场景参考图片
        private func RefImageSection(title: String, sceneIndex: Int) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                
                SceneReferenceImageView(
                    title: title,
                    referenceImage: Binding(
                        get: { viewModel.storyScenes[sceneIndex].referencaImage },
                        set: { newImage in
                            if let image = newImage {
                                viewModel.updateSceneReferenceImage(sceneIndex: sceneIndex, image: image)
                            }
                        }
                    )
                )
                
            }
            .padding(.horizontal, 4)
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
                    await handleGenerateImageAction(idx: Int(senceId))
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
                    SceneCardView(
                        scene: scene,
                        index: index,
                        totalScenes: viewModel.storyScenes.count,
                        viewModel: viewModel
                    )
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
                backgroud: self.background,
                roles: self.roles
            )
            
            let chapterSummary = ret.0!.result.chapterSummary
            if !chapterSummary.title.isEmpty && !chapterSummary.content.isEmpty {
                self.generatedStoryTitle = chapterSummary.title
                self.generatedStoryContent = chapterSummary.content
                showNotification(message: "故事生成成功", type: .success)
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成故事失败"])
            }
        } catch {
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
            print("createStoryBoard resp:",ret.0?.id as Any)
            self.boardId = (ret.0?.id)!
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
            .write: "正在生成故事板内容...",
            .complete: "正在创建故事板...",
            .draw: "正在生成场景图...",
            .narrate: "正在发布故事板..."
        ]
    }

    // 修改成功消息
    private var successMessages: [TimelineStep: String] {
        [
            .write: "故事板生成成功",
            .complete: "故事板创建成功",
            .draw: "场景图片生成成功",
            .narrate: "故事板发布成功"
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
                senceId: Int64(idx),
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
                print("scene id gen success: ",scene.senceId,scene.imageUrl)
            }
            
            hideLoading()
            showNotification(message: "场景图片生成成功", type: .success)
        } catch {
            handleError(error)
        }
    }
    
    private func moreSenseDetailAction(idx: Int) async {
        showLoading(message: "正在增加场景细节...")
        do {
            
            hideLoading()
            showNotification(message: "场景细节添加成功", type: .success)
        } catch {
            handleError(error)
        }
    }
}



struct StoryPublishView: View {
    @ObservedObject var viewModel: StoryViewModel
    let onSaveOnly: () async -> Void
    let onPublish: () async -> Void
    
    @State private var isSaving = false
    @State private var isPublishing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedSceneIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Tab栏
                if !viewModel.storyScenes.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(0..<viewModel.storyScenes.count, id: \.self) { idx in
                            Button(action: { selectedSceneIndex = idx }) {
                                VStack(spacing: 4) {
                                    Text("场景\(idx + 1)")
                                        .font(.system(size: 16, weight: selectedSceneIndex == idx ? .semibold : .regular))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                    Rectangle()
                                        .fill(selectedSceneIndex == idx ? Color.blue : Color.clear)
                                        .frame(height: 2)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.top, 8)
                    .background(Color(.systemBackground))
                }

                // 操作按钮
                HStack(spacing: 16) {
                    ActionButton(
                        title: "保存草稿",
                        icon: "square.and.arrow.down",
                        color: .blue
                    ) {
                        Task { await handleSave() }
                    }
                    ActionButton(
                        title: "发布故事",
                        icon: "paperplane.fill",
                        color: .green
                    ) {
                        Task { await handlePublish() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

                // 当前选中场景卡片
                if !viewModel.storyScenes.isEmpty, viewModel.storyScenes.indices.contains(selectedSceneIndex) {
                    ScenePreviewCard(scene: viewModel.storyScenes[selectedSceneIndex])
                } else {
                    EmptyStateView()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
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
            await onSaveOnly()
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

// 场景预览卡片（去除"场景 x"标题，字体黑色）
private struct ScenePreviewCard: View {
    let scene: StoryBoardSence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 场景图片
            if let url = URL(string: scene.imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView()
                        .frame(height: 200)
                }
            }
            
            // 场景信息
            VStack(alignment: .leading, spacing: 12) {
                InfoSection(title: "场景描述", content: scene.content)
                InfoSection(title: "参与人物", content: "", characters: scene.characters)
                if !scene.imagePrompt.isEmpty {
                    InfoSection(title: "图片提示词", content: scene.imagePrompt)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// InfoSection 字体黑色
private struct InfoSection: View {
    let title: String
    let content: String
    let characters: [Common_Character]?
    
    init(title: String, content: String, characters: [Common_Character]? = nil) {
        self.title = title
        self.content = content
        self.characters = characters
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black)
            if let characters = characters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(characters, id: \.id) { character in
                            CharacterButton(character: character)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                Text(content)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

// 添加角色按钮组件
private struct CharacterButton: View {
    let character: Common_Character
    
    var body: some View {
        Button(action: {
            // 点击角色按钮的操作（如果需要的话）
        }) {
            HStack(spacing: 4) {
                // 角色头像（如果有的话）
//                if let avatarUrl = character.avatarUrl {
//                    KFImage(URL(string: avatarUrl))
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 20, height: 20)
//                        .clipShape(Circle())
//                }
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.buttonText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.theme.accent)
            .cornerRadius(16)
        }
    }
}


struct SceneGenerationView: View {
    @ObservedObject var viewModel: StoryViewModel
    let onGenerateImage: (Int) async -> Void
    let onGenerateAllImage: () async -> Void
    let moreSenseDetail: (Int) async -> Void

    @State private var selectedSceneIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab栏
            if !viewModel.storyScenes.isEmpty {
                HStack(spacing: 0) {
                    ForEach(0..<viewModel.storyScenes.count, id: \.self) { idx in
                        Button(action: { selectedSceneIndex = idx }) {
                            VStack(spacing: 4) {
                                Text("场景\(idx + 1)")
                                    .font(.system(size: 16, weight: selectedSceneIndex == idx ? .semibold : .regular))
                                    .foregroundColor(selectedSceneIndex == idx ? Color.theme.primaryText : Color.theme.tertiaryText)
                                    .frame(maxWidth: .infinity)
                                Rectangle()
                                    .fill(selectedSceneIndex == idx ? Color.blue : Color.clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 8)
                .background(Color(.systemBackground))
            }

            // Tab与内容区间距
            Spacer().frame(height: 5)
            if !viewModel.storyScenes.isEmpty{
                if viewModel.storyScenes.indices.contains(selectedSceneIndex) {
                    let scene = $viewModel.storyScenes[selectedSceneIndex]
                    VStack(alignment: .leading, spacing: 16) {
                        // 场景故事
                        VStack(alignment: .leading, spacing: 4) {
                            Text("场景故事")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextEditor(text: scene.content)
                                .font(.body)
                                .frame(minHeight: 80, maxHeight: 180)
                                .multilineTextAlignment(.leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.theme.border, lineWidth: 1)
                                )
                        }

                        // 参与人物
                        VStack(alignment: .leading, spacing: 4) {
                            Text("参与人物（用逗号分隔）")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // 图片提示词
                        VStack(alignment: .leading, spacing: 4) {
                            Text("图片提示词")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextEditor(text: scene.imagePrompt)
                                .font(.body)
                                .frame(minHeight: 40, maxHeight: 120)
                                .multilineTextAlignment(.leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.theme.border, lineWidth: 1)
                                )
                        }

                        Divider().padding(.vertical, 8)
                        // 按钮组居中
                        HStack(spacing: 16) {
                            ActionButton(
                                title: "场景渲染",
                                icon: "hand.draw",
                                color: .green
                            ) {
                                Task { await moreSenseDetail(selectedSceneIndex) }
                            }
                            ActionButton(
                                title: "生成图片",
                                icon: "photo.fill",
                                color: .blue
                            ) {
                                Task { await onGenerateImage(selectedSceneIndex) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }

                Spacer().frame(height: 8)

                // 生成所有场景图片按钮
                HStack {
                    Spacer()
                    ActionButton(
                        title: "生成所有场景图片",
                        icon: "photo.fill",
                        color: .green
                    ) {
                        Task { await onGenerateAllImage() }
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            }else{
                EmptyStateView()
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

struct StoryContentView: View {
    @Binding var generatedStoryTitle: String
    @Binding var generatedStoryContent: String
    
    // 添加回调函数
    var onGenerate: () -> Void = {}
    var onSave: () -> Void = {}
    
    @State private var textEditorHeight: CGFloat = 120
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !generatedStoryTitle.isEmpty || !generatedStoryContent.isEmpty {
                    Text("生成的故事内容")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Title section (可编辑)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("标题")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("请输入标题", text: $generatedStoryTitle)
                                .font(.title3)
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        
                        Divider()
                        
                        // Content section (可编辑, 高度自适应)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("内容")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ZStack(alignment: .topLeading) {
                                // 隐藏的 Text 用于测量高度
                                Text(generatedStoryContent.isEmpty ? "请输入内容..." : generatedStoryContent)
                                    .font(.body)
                                    .foregroundColor(.clear)
                                    .padding(8)
                                    .background(GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                textEditorHeight = max(120, geo.size.height + 24)
                                            }
                                            .onChange(of: generatedStoryContent) { _ in
                                                textEditorHeight = max(120, geo.size.height + 24)
                                            }
                                    })
                                TextEditor(text: $generatedStoryContent)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(height: textEditorHeight)
                                    .multilineTextAlignment(.leading)
                                    .background(Color.clear)
                                    .cornerRadius(6)
                                    .padding(.vertical, 0)
                            }
                        }
                        
                        Divider() // 按钮区域和内容区域分割线
                        
                        // 按钮组
                        HStack(spacing: 12) {
                            Button(action: onGenerate) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("生成场景")
                                }
                                .font(.callout)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            
                            Button(action: onSave) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("保存")
                                }
                                .font(.callout)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 0)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
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
    @Binding var roles: [StoryRole]?
    @State private var isShowingRoleSelection = false
    
    // 添加生成内容的状态
    @Binding var generatedStoryTitle: String
    @Binding var generatedStoryContent: String
    @Binding var isGenerated: Bool
    let userId: Int64
    let storyId: Int64
    @ObservedObject var viewModel: StoryViewModel
    
    // 添加回调函数
    var onGenerate: () async -> Void
    var onSave: () async -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputSection
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $isShowingRoleSelection) {
            RoleSelectionView(
                viewModel: viewModel,
                selectedRoles: $roles,
                storyId: storyId,
                userId: userId
            )
        }
    }
    
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
    
    private var roleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("角色设定")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: {
                isShowingRoleSelection = true
            }) {
                VStack {
                    if roles!.isEmpty {
                        Image(systemName: "plus")
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                        Text("添加角色")
                            .font(.caption)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(roles!, id: \.role.roleID) { role in
                                    VStack {
                                        KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                                            .cacheMemoryOnly()
                                            .fade(duration: 0.25)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                        Text(role.role.characterName)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
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
                                .frame(width: 32, height: 32)
                            
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(index <= currentStep ? Color.theme.buttonText : Color.theme.tertiaryText)
                        }
                        
                        // Connecting line
                        if index < totalSteps - 1 {
                            Rectangle()
                                .fill(index < currentStep ? getStepColor(for: index) : Color.theme.tertiaryText.opacity(0.15))
                                .frame(height: 2)
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
    }
    
    // 获取步骤颜色
    private func getStepColor(for index: Int) -> Color {
        switch index {
            case _ where index < currentStep:
                return Color.theme.success // 已完成的步骤显示为绿色
            case currentStep:
                return Color.theme.accent // 当前步骤显示为蓝色
            default:
                return Color.theme.tertiaryText.opacity(0.15) // 未完成的步骤显示为灰色
        }
    }
    
    // 获取文字颜色
    private func getTextColor(for index: Int) -> Color {
        switch index {
            case _ where index < currentStep:
                return Color.theme.success // 已完成的步骤文字显示为绿色
            case currentStep:
                return Color.theme.accent // 当前步骤文字显示为蓝色
            default:
                return Color.theme.tertiaryText // 未完成的步骤文字显示为灰色
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
            .foregroundColor(Color.theme.buttonText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(20)
        }
    }
}

// Loading View Component
private struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(2.0)
                .padding()
            Text("加载中...")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            Spacer()
        }
    }
}

// Error View Component
private struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundColor(.red)
                .padding()
            Spacer()
        }
    }
}

// Role List View Component
private struct RoleListView: View {
    let roles: [StoryRole]
    @Binding var selectedRoles: [StoryRole]?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(roles, id: \ .role.roleID) { role in
                    RoleSelectionRow(
                        role: role,
                        isSelected: selectedRoles?.contains { $0.role.roleID == role.role.roleID } ?? false,
                        onSelect: {
                            if selectedRoles == nil {
                                selectedRoles = []
                            }
                            if let index = selectedRoles?.firstIndex(where: { $0.role.roleID == role.role.roleID }) {
                                selectedRoles?.remove(at: index)
                            } else {
                                selectedRoles?.append(role)
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .background(Color.theme.background)
    }
}

struct RoleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StoryViewModel
    @Binding var selectedRoles: [StoryRole]?
    let storyId: Int64
    let userId: Int64
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    LoadingView()
                } else if let error = errorMessage {
                    ErrorView(message: error)
                } else {
                    RoleListView(roles: viewModel.storyRoles ?? [], selectedRoles: $selectedRoles)
                }
            }
            .navigationTitle("选择角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadStoryRoles()
        }
    }
    
    private func loadStoryRoles() async {
        isLoading = true
        errorMessage = nil
        
        let err = await viewModel.getStoryRoles(storyId: storyId, userId: userId)
        if let error = err {
            print("load story role error:", error as Any)
            errorMessage = error.localizedDescription
        }
        print("load story role success: ",self.selectedRoles?.count as Any)
        
        isLoading = false
    }
}

struct RoleSelectionRow: View {
    let role: StoryRole
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.role.characterName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .padding(.top, 8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }
}

// 1. 通用自定义弹窗视图
struct CustomAlertView: View {
    enum AlertType { case success, error, info }
    let type: AlertType
    let title: String
    let message: String
    let onClose: () -> Void
    let onInfo: (() -> Void)?
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.85, green: 0.95, blue: 0.85)) // 柔和灰绿色
                .frame(width: 320, height: 200) // 16:10 比例
                .shadow(radius: 10)
            VStack(spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                    Spacer()
                    if let onInfo = onInfo {
                        Button(action: onInfo) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(8)
                        }
                    }
                }
                .frame(height: 32)
                .padding(.horizontal, 4)
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(iconColor)
                        .padding(.bottom, 2)
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.bottom, 2)
                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Text("知道了")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(red: 0.4, green: 0.7, blue: 0.4))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                }
            }
            .frame(width: 320, height: 200)
        }
    }
    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        case .info: return "info.circle.fill"
        }
    }
    private var iconColor: Color {
        switch type {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

struct SceneReferenceImageView: View {
    let title: String
    @Binding var referenceImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.theme.secondaryText)
            
            if let image = referenceImage {
                // 显示已选择的图片
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                    
                    Button(action: { showImagePicker = true }) {
                        Text("编辑")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    .padding(8)
                }
            } else {
                // 显示添加按钮
                Button(action: { showImagePicker = true }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.theme.background)
                            .frame(height: 200)
                            .cornerRadius(8)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(Color.theme.secondaryText)
                            
                            Image(systemName: "mountain.2")
                                .font(.system(size: 32))
                                .foregroundColor(Color.theme.secondaryText)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .sheet(isPresented: $showImagePicker) {
            SingleImagePicker(image: $referenceImage)
        }
    }
}

// 在StoryViewModel中添加更新场景参考图片的方法
extension StoryViewModel {
    func updateSceneReferenceImage(sceneIndex: Int, image: UIImage) {
        guard sceneIndex < storyScenes.count else { return }
        storyScenes[sceneIndex].referencaImage = image
    }
}

