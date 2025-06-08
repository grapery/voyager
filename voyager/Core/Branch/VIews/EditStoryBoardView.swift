//
//  EditStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/15.
//

import SwiftUI
import Combine
import Kingfisher
import Foundation
import ActivityIndicatorView

//// 步骤枚举
//private enum TimelineStep: Int, CaseIterable {
//    case write, complete, draw, narrate
//    var title: String {
//        switch self {
//        case .write: return "故事渲染"
//        case .complete: return "场景拆解"
//        case .draw: return "图片渲染"
//        case .narrate: return "发布/保存"
//        }
//    }
//}

// MARK: - Main View
struct EditStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // params
    @State public var userId: Int64
    @State public var storyId: Int64
    @State public var boardId: Int64
    @ObservedObject var viewModel: StoryViewModel
    
    // input
    @State public var title: String = ""
    @State public var content: String = ""
    @State public var background: String = ""
    @State public var roles: [StoryRole]?
    
    // tech detail
    @State public var prompt = ""
    @State public var nevigatePrompt = ""
    
    // generated detail
    @State public var generatedStoryTitle: String = ""
    @State public var generatedStoryContent: String = ""
    @State public var generatedImages: [UIImage] = [UIImage]()
    
    // Add states for tracking completion status
    @State private var isInputCompleted: Bool = false
    @State private var isStoryGenerated: Bool = false
    @State private var isImageGenerated: Bool = false
    @State private var isNarrationCompleted: Bool = false
    
    // Add state for current step
    @State private var currentStep: TimelineStep = .write
    
    // Add states for notifications
    @State private var isLoading: Bool = false
    @State private var loadingMessage: String = ""
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    @State private var notificationType: NotificationType = .success
    
    @State private var isShowingRoleSelection = false
    @Binding var isPresented: Bool
    
    var body: some View {
        EditStoryBoardContentView(
            currentStep: $currentStep,
            title: $title,
            content: $content,
            background: $background,
            roles: $roles,
            generatedStoryTitle: $generatedStoryTitle,
            generatedStoryContent: $generatedStoryContent,
            generatedImages: $generatedImages,
            isStoryGenerated: $isStoryGenerated,
            viewModel: viewModel,
            userId: userId,
            storyId: storyId,
            boardId: boardId,
            isPresented: $isPresented,
            onGenerateStory: generateStory,
            onSaveStoryBoard: saveStoryBoard,
            onGeneratePrompt: generateStoryboardPrompt,
            onApplyAllScenes: ApplyAllsences,
            onGenerateImage: handleGenerateImageAction,
            onGenerateAllImages: GenerateAllSenseImageAction,
            onMoreSenseDetail: moreSenseDetailAction,
            onPublish: publishStoryBoard
        )
        .alert("提示", isPresented: $showingValidationAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
        .overlay(
            Group {
                if isLoading {
                    LoadingView(message: loadingMessage)
                }
            }
        )
        .overlay(
            Group {
                if showNotification {
                    NotificationView(message: notificationMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        )
    }
}

// MARK: - Content View
private struct EditStoryBoardContentView: View {
    @Binding var currentStep: TimelineStep
    @Binding var title: String
    @Binding var content: String
    @Binding var background: String
    @Binding var roles: [StoryRole]?
    @Binding var generatedStoryTitle: String
    @Binding var generatedStoryContent: String
    @Binding var generatedImages: [UIImage]
    @Binding var isStoryGenerated: Bool
    let viewModel: StoryViewModel
    let userId: Int64
    let storyId: Int64
    let boardId: Int64
    @Binding var isPresented: Bool
    
    let onGenerateStory: () async -> Void
    let onSaveStoryBoard: () async -> Void
    let onGeneratePrompt: () async -> Void
    let onApplyAllScenes: () async -> Void
    let onGenerateImage: (Int) async -> Void
    let onGenerateAllImages: () async -> Void
    let onMoreSenseDetail: (Int) async -> Void
    let onPublish: () async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Step Navigation
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
                // Write Step
                EditStoryInputView(
                    title: $title,
                    content: $content,
                    background: $background,
                    roles: $roles,
                    userId: userId,
                    storyId: storyId,
                    viewModel: viewModel,
                    onGenerate: {
                        Task {
                            await onGenerateStory()
                        }
                    },
                    onSave: {
                        Task {
                            await onSaveStoryBoard()
                        }
                    }
                )
                .tag(TimelineStep.write)
                
                // Complete Step
                StoryContentView(
                    generatedStoryTitle: $generatedStoryTitle,
                    generatedStoryContent: $generatedStoryContent,
                    onGenerate: {
                        Task {
                            await onGeneratePrompt()
                        }
                    },
                    onSave: {
                        Task {
                            await onApplyAllScenes()
                        }
                    }
                )
                .tag(TimelineStep.complete)
                
                // Draw Step
                SceneGenerationView(
                    viewModel: viewModel,
                    onGenerateImage: onGenerateImage,
                    onGenerateAllImage: onGenerateAllImages,
                    moreSenseDetail: onMoreSenseDetail
                )
                .tag(TimelineStep.draw)
                
                // Narrate Step
                StoryPublishView(
                    viewModel: viewModel,
                    onSaveOnly: {
                        Task {
                            await onSaveStoryBoard()
                        }
                    },
                    onPublish: {
                        Task {
                            await onPublish()
                        }
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
        if !validateCurrentStep() {
            return
        }
        
        if let currentIndex = TimelineStep.allCases.firstIndex(of: currentStep),
           currentIndex < TimelineStep.allCases.count - 1 {
            withAnimation {
                currentStep = TimelineStep.allCases[currentIndex + 1]
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .write:
            if title.isEmpty {
                return false
            }
            if content.isEmpty {
                return false
            }
            if background.isEmpty {
                return false
            }
        case .complete:
            if generatedStoryContent.isEmpty {
                return false
            }
        case .draw:
            if viewModel.storyScenes.isEmpty {
                return false
            }
        case .narrate:
            if generatedImages.isEmpty {
                return false
            }
        }
        return true
    }
}

// MARK: - Story Generation Methods
extension EditStoryBoardView {
    private func generateStory() async {
        do {
            showLoading(message: "正在生成故事内容...")
            let ret = await viewModel.conintueGenStory(
                storyId: storyId,
                userId: userId,
                prevBoardId: boardId,
                prompt: prompt,
                title: title,
                desc: content,
                backgroud: background,
                roles: roles
            )
            
            let chapterSummary = ret.0!.result.chapterSummary
            if !chapterSummary.title.isEmpty && !chapterSummary.content.isEmpty {
                generatedStoryTitle = chapterSummary.title
                generatedStoryContent = chapterSummary.content
                showNotification(message: "故事生成成功", type: .success)
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成故事失败"])
            }
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func saveStoryBoard() async {
        do {
            showLoading(message: "正在保存故事板...")
            let ret = await viewModel.createStoryBoard(
                prevBoardId: boardId,
                nextBoardId: 0,
                title: generatedStoryTitle,
                content: generatedStoryContent,
                isAiGen: true,
                backgroud: background,
                params: Common_StoryBoardParams(),
                roles: roles!
            )
            
            if let error = ret.1 {
                throw error
            }
            
            showNotification(message: "故事板保存成功", type: .success)
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func generateStoryboardPrompt() async {
        do {
            showLoading(message: "正在生成故事图片提示词...")
            let ret = await viewModel.genStoryBoardPrompt(
                storyId: storyId,
                boardId: boardId,
                userId: userId,
                renderType: Common_RenderType(rawValue: 1)!
            )
            
            if let error = ret {
                throw error
            }
            
            showNotification(message: "故事图片提示词生成成功", type: .success)
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func ApplyAllsences() async {
        do {
            showLoading(message: "正在应用所有场景...")
            for (index, _) in viewModel.storyScenes.enumerated() {
                let (senceId, err) = await viewModel.createStoryboardSence(
                    idx: index,
                    boardId: boardId
                )
                
                if let err = err {
                    throw err
                }
                
                viewModel.storyScenes[index].senceId = senceId
            }
            showNotification(message: "所有场景应用成功", type: .success)
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func handleGenerateImageAction(idx: Int) async {
        showLoading(message: "正在生成场景图片...")
        do {
            let err = await viewModel.genStoryBoardSpecSence(
                storyId: storyId,
                boardId: boardId,
                userId: userId,
                senceId: viewModel.storyScenes[idx].senceId,
                renderType: Common_RenderType(rawValue: 1)!
            )
            
            if let err = err {
                throw err
            }
            
            showNotification(message: "场景图片生成成功", type: .success)
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func GenerateAllSenseImageAction() async {
        showLoading(message: "正在生成所有场景图片...")
        do {
            for (index, scene) in viewModel.storyScenes.enumerated() {
                let err = await viewModel.genStoryBoardSpecSence(
                    storyId: storyId,
                    boardId: boardId,
                    userId: userId,
                    senceId: scene.senceId,
                    renderType: Common_RenderType(rawValue: 1)!
                )
                
                if let err = err {
                    throw err
                }
            }
            
            showNotification(message: "所有场景图片生成成功", type: .success)
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func moreSenseDetailAction(idx: Int) async {
        showLoading(message: "正在增加场景细节...")
        do {
            // TODO: Implement scene detail enhancement
            showNotification(message: "场景细节添加成功", type: .success)
        } catch {
            handleError(error)
        }
        hideLoading()
    }
    
    private func publishStoryBoard() async {
        do {
            showLoading(message: "正在发布故事板...")
            let ret = await viewModel.publishStoryboard(
                storyId: storyId,
                boardId: boardId,
                userId: userId,
                status: 5
            )
            
            if ret != nil {
                throw ret as! Error
            }
            
            showNotification(message: "故事板发布成功", type: .success)
            isPresented = false
        } catch {
            handleError(error)
        }
        hideLoading()
    }
}

// MARK: - Helper Methods
extension EditStoryBoardView {
    private func showLoading(message: String) {
        withAnimation {
            self.loadingMessage = message
            self.isLoading = true
        }
    }
    
    private func hideLoading() {
        withAnimation {
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    private func showNotification(message: String, type: NotificationType) {
        withAnimation {
            self.notificationMessage = message
            self.notificationType = type
            self.showNotification = true
        }
    }
    
    private func handleError(_ error: Error) {
        hideLoading()
        showNotification(
            message: "操作失败: \(error.localizedDescription)",
            type: .error
        )
    }
}

// MARK: - Edit Story Input View
struct EditStoryInputView: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var background: String
    @Binding var roles: [StoryRole]?
    @State private var isShowingRoleSelection = false
    
    let userId: Int64
    let storyId: Int64
    let viewModel: StoryViewModel
    let onGenerate: () async -> Void
    let onSave: () async -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TitleInputView(title: $title)
                ContentInputView(content: $content)
                BackgroundInputView(background: $background)
                RoleSelectionSection(
                    roles: $roles,
                    isShowingRoleSelection: $isShowingRoleSelection,
                    viewModel: viewModel,
                    storyId: storyId,
                    userId: userId
                )
                ActionButtonsView(onGenerate: onGenerate, onSave: onSave)
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Title Input View
private struct TitleInputView: View {
    @Binding var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标题")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.theme.secondaryText)
            TextField("请输入故事板标题", text: $title)
                .font(.system(size: 16))
                .padding()
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(12)
        }
    }
}

// MARK: - Content Input View
private struct ContentInputView: View {
    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.theme.secondaryText)
            TextEditor(text: $content)
                .font(.system(size: 16))
                .frame(height: 120)
                .padding(8)
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(12)
        }
    }
}

// MARK: - Background Input View
private struct BackgroundInputView: View {
    @Binding var background: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("背景设定")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.theme.secondaryText)
            TextEditor(text: $background)
                .font(.system(size: 16))
                .frame(height: 80)
                .padding(8)
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(12)
        }
    }
}

// MARK: - Role Selection Section
private struct RoleSelectionSection: View {
    @Binding var roles: [StoryRole]?
    @Binding var isShowingRoleSelection: Bool
    let viewModel: StoryViewModel
    let storyId: Int64
    let userId: Int64
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("选择角色")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
                Spacer()
            }
            
            if let roles = roles, !roles.isEmpty {
                RoleListView(roles: roles)
            } else {
                Button(action: {
                    isShowingRoleSelection = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color.theme.accent)
                        .frame(width: 50, height: 50)
                        .background(Color.theme.tertiaryBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                }
            }
        }
        .sheet(isPresented: $isShowingRoleSelection) {
            RoleSelectionView(
                viewModel: viewModel,
                selectedRoles: $roles,
                storyId: storyId,
                userId: userId
            )
        }
    }
}

// MARK: - Role List View
private struct RoleListView: View {
    let roles: [StoryRole]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(roles, id: \.role.roleID) { role in
                    VStack {
                        KFImage(URL(string: defaultAvator))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipped()
                            .cornerRadius(16)
                        Text(role.role.characterName)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.theme.tertiaryBackground)
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Action Buttons View
private struct ActionButtonsView: View {
    let onGenerate: () async -> Void
    let onSave: () async -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                Task {
                    await onGenerate()
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
                .background(Color.theme.secondary).colorInvert()
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            Spacer()
        }
    }
}

// 步骤2：场景拆解
private struct EditScenesStepView: View {
    @Binding var scenes: [StoryBoardSence]
    @State private var selectedSceneIndex: Int = 0
    @State private var isEditingScene = false
    @State private var editingScene: StoryBoardSence?
    
    var body: some View {
        VStack(spacing: 0) {
            if scenes.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 场景选择器
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                                    Button(action: {
                                        selectedSceneIndex = index
                                    }) {
                                        Text("场景 \(index + 1)")
                                            .font(.system(size: 14, weight: selectedSceneIndex == index ? .medium : .regular))
                                            .foregroundColor(selectedSceneIndex == index ? Color.theme.accent : Color.theme.secondaryText)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedSceneIndex == index ? Color.theme.accent.opacity(0.1) : Color.clear)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // 场景内容
                        if let scene = scenes[safe: selectedSceneIndex] {
                            SceneCardView(scene: scene, index: selectedSceneIndex, totalScenes: scenes.count)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingScene) {
            if let scene = editingScene {
                SceneEditView(scene: scene) { updatedScene in
                    if let index = scenes.firstIndex(where: { $0.senceId == updatedScene.senceId }) {
                        scenes[index] = updatedScene
                    }
                }
            }
        }
    }
}

// MARK: - Scene Card View
private struct SceneCardView: View {
    let scene: StoryBoardSence
    let index: Int
    let totalScenes: Int
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // 场景指示器
            HStack(spacing: 8) {
                ForEach(0..<totalScenes, id: \.self) { sceneIndex in
                    Circle()
                        .fill(sceneIndex == index ? Color.theme.accent : Color.theme.tertiaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
            
            // 场景标题栏
            HStack {
                Text("故事场景 \(index + 1)")
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
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
        }
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func contentSection(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.theme.secondaryText)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    private func characterSection(_ title: String, characters: [Common_Character]) -> some View {
        VStack{
            ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    // 增加新的角色
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .foregroundColor(Color.theme.accent)
                                            .frame(width: 50, height: 50)
                                            .background(Color.theme.tertiaryBackground)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
        }
    }
}

// MARK: - Ref Image Section
private struct RefImageSection: View {
    let title: String
    let sceneIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.theme.secondaryText)
            
            // 这里可以添加图片展示逻辑
            Text("暂无参考图片")
                .font(.system(size: 14))
                .foregroundColor(Color.theme.tertiaryText)
        }
        .padding()
    }
}

// MARK: - Scene Edit View
private struct SceneEditView: View {
    let scene: StoryBoardSence
    let onSave: (StoryBoardSence) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editedContent: String
    @State private var editedCharacters: [Common_Character]
    @State private var editedImagePrompt: String
    
    init(scene: StoryBoardSence, onSave: @escaping (StoryBoardSence) -> Void) {
        self.scene = scene
        self.onSave = onSave
        _editedContent = State(initialValue: scene.content)
        _editedCharacters = State(initialValue: scene.characters)
        _editedImagePrompt = State(initialValue: scene.imagePrompt)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("场景内容")) {
                    TextEditor(text: $editedContent)
                        .frame(height: 100)
                }
                
                Section(header: Text("参与人物")) {
                    ForEach(editedCharacters.indices, id: \.self) { index in
                        TextField("人物名称", text: $editedCharacters[index].name)
                    }
                    .onDelete { indexSet in
                        editedCharacters.remove(atOffsets: indexSet)
                    }
                    
//                    Button(action: {
//                        editedCharacters.append("")
//                    }) {
//                        Label("添加人物", systemImage: "plus")
//                    }
                }
                
                Section(header: Text("图片提示词")) {
                    TextEditor(text: $editedImagePrompt)
                        .frame(height: 100)
                }
            }
            .navigationTitle("编辑场景")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Empty State View
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

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Edit Scene Images Step View
private struct EditSceneImagesStepView: View {
    @Binding var scenes: [StoryBoardSence]
    @Binding var generatedImages: [String]
    @State private var selectedSceneIndex: Int = 0
    @State private var isGenerating = false
    @State private var generationProgress = 0.0
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if scenes.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 场景选择器
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                                    Button(action: {
                                        selectedSceneIndex = index
                                    }) {
                                        Text("场景 \(index + 1)")
                                            .font(.system(size: 14, weight: selectedSceneIndex == index ? .medium : .regular))
                                            .foregroundColor(selectedSceneIndex == index ? Color.theme.accent : Color.theme.secondaryText)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedSceneIndex == index ? Color.theme.accent.opacity(0.1) : Color.clear)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // 场景图片
                        if let scene = scenes[safe: selectedSceneIndex] {
                            SceneImagesView(
                                scene: scene,
                                generatedImages: generatedImages,
                                isGenerating: $isGenerating,
                                generationProgress: $generationProgress,
                                onGenerate: {
                                    Task {
                                        await generateImages(for: scene)
                                    }
                                },
                                sceneIndex: selectedSceneIndex
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("错误"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    private func generateImages(for scene: StoryBoardSence) async {
        isGenerating = true
        generationProgress = 0.0
        
        do {
            // 这里添加图片生成逻辑
            // 模拟生成进度
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                generationProgress = Double(i) / 10.0
            }
            
            // 生成完成后更新图片列表
            // 这里需要根据实际API调用结果更新
            generatedImages = ["image_url_1", "image_url_2", "image_url_3"]
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isGenerating = false
    }
}

// MARK: - Scene Images View
private struct SceneImagesView: View {
    let scene: StoryBoardSence
    let generatedImages: [String]
    @Binding var isGenerating: Bool
    @Binding var generationProgress: Double
    let onGenerate: () -> Void
    let sceneIndex: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // 场景标题
            HStack {
                Text("场景 \(sceneIndex)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.theme.primary.opacity(0.1))
            .cornerRadius(8)
            
            // 图片提示词
            VStack(alignment: .leading, spacing: 8) {
                Text("图片提示词")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
                
                Text(scene.imagePrompt)
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
            
            // 生成的图片
            if !generatedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(generatedImages, id: \.self) { imageUrl in
                            KFImage(URL(string: imageUrl))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 200)
                                .clipped()
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 生成按钮
            Button(action: onGenerate) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("生成中...")
                    } else {
                        Text("生成图片")
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isGenerating ? Color.theme.tertiaryText : Color.theme.accent)
                .cornerRadius(12)
            }
            .disabled(isGenerating)
            
            if isGenerating {
                ProgressView(value: generationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
    }
}

// MARK: - Edit Publish Step View
private struct EditPublishStepView: View {
    let onSave: () async -> Void
    let onPublish: () async -> Void
    @State private var isSaving = false
    @State private var isPublishing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 发布选项
            VStack(alignment: .leading, spacing: 16) {
                Text("发布选项")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
                
                // 保存按钮
                Button(action: {
                    Task {
                        isSaving = true
                        await onSave()
                        isSaving = false
                        showAlert = true
                        alertMessage = "保存成功"
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("保存中...")
                        } else {
                            Image(systemName: "square.and.arrow.down")
                            Text("仅保存")
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSaving ? Color.theme.tertiaryText : Color.theme.accent)
                    .cornerRadius(12)
                }
                .disabled(isSaving || isPublishing)
                
                // 发布按钮
                Button(action: {
                    Task {
                        isPublishing = true
                        await onPublish()
                        isPublishing = false
                        showAlert = true
                        alertMessage = "发布成功"
                    }
                }) {
                    HStack {
                        if isPublishing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("发布中...")
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("发布故事")
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPublishing ? Color.theme.tertiaryText : Color.theme.primary)
                    .cornerRadius(12)
                }
                .disabled(isSaving || isPublishing)
            }
            .padding()
            .background(Color.theme.secondaryBackground)
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("提示"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
}

// 自定义导航栏
private struct CustomNavigationBar: View {
    let title: String
    let presentationMode: Binding<PresentationMode>
    
    var body: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(width: 28, height: 28)
                    .background(Color.theme.tertiaryBackground)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
            
            // 保持对称性的占位视图
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// 编辑故事板步骤视图
struct EditBoardStepView: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("编辑故事板")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.theme.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("标题")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
                
                TextField("请输入故事板标题", text: $title)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color.theme.tertiaryBackground)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("内容")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
                
                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .frame(height: 200)
                    .padding(8)
                    .background(Color.theme.tertiaryBackground)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
    }
}

// 创建场景步骤视图
struct CreateScenesStepView: View {
    @Binding var scenes: [StoryboardScene]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("创建场景")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.theme.primaryText)
            
            ForEach(scenes.indices, id: \.self) { index in
                SceneItemView(scene: $scenes[index])
            }
            
            Button(action: {
                scenes.append(StoryboardScene())
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加场景")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.theme.accent)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
    }
}

// 发布步骤视图
struct PublishStepView: View {
    @Binding var generatedImages: [String]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("生成场景图片")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.theme.primaryText)
            
            if !generatedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(generatedImages, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 160, height: 160)
                                    .background(Color.theme.tertiaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Button(action: {
                // 实现生成图片的逻辑
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("生成图片")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.theme.accent)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
    }
}

// 为了编译通过，添加一个简单的 Scene 结构体
struct StoryboardScene: Identifiable {
    var id = UUID()
    var title: String = ""
    var description: String = ""
}

// 场景项视图
struct SceneItemView: View {
    @Binding var scene: StoryboardScene
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("场景标题", text: $scene.title)
                .font(.system(size: 16))
                .padding()
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(12)
            
            TextEditor(text: $scene.description)
                .font(.system(size: 16))
                .frame(height: 100)
                .padding(8)
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.border, lineWidth: 1)
        )
    }
}

struct StoryboardLoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            // 加载指示器容器
            VStack(spacing: 20) {
                // 自定义加载动画
                ZStack {
                    // 外圈
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    // 动画圈
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: rotation))
                        .onAppear {
                            withAnimation(
                                Animation
                                    .linear(duration: 1)
                                    .repeatForever(autoreverses: false)
                            ) {
                                rotation = 360
                            }
                        }
                }
                
                // 加载状态文本
                VStack(spacing: 8) {
                    Text("处理中...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("请稍候")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}

struct StoryboardStepIndicatorView: View {
    let steps: [String]
    let currentStep: Int
    
    private let lineHeight: CGFloat = 2
    private let circleSize: CGFloat = 24
    
    var body: some View {
        VStack(spacing: 6) {
            // Progress bar with circles
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    if index > 0 {
                        // Connecting line
                        Rectangle()
                            .fill(index <= currentStep ? Color.theme.accent : Color.theme.tertiaryText.opacity(0.3))
                            .frame(height: lineHeight)
                    }
                    
                    // Step circle
                    Circle()
                        .fill(index <= currentStep ? Color.theme.accent : Color.theme.tertiaryText.opacity(0.3))
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Group {
                                if index <= currentStep {
                                    Image(systemName: index == currentStep ? "\(index + 1).circle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.theme.buttonText)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.theme.buttonText)
                                }
                            }
                        )
                }
            }
            .padding(.horizontal, 24)
            
            // Step labels
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    if index > 0 {
                        Spacer()
                    }
                    Text(steps[index])
                        .font(.system(size: 12))
                        .foregroundColor(index <= currentStep ? Color.theme.primaryText : Color.theme.tertiaryText)
                    if index < steps.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.theme.tertiaryBackground)
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ActivityIndicatorView(isVisible: .constant(true), type: .growingCircle)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                
                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(Color.theme.primary.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Notification View
private struct NotificationView: View {
    let message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.theme.primary)
                .cornerRadius(8)
                .shadow(radius: 4)
            
            Spacer()
        }
        .padding(.top, 16)
    }
}
