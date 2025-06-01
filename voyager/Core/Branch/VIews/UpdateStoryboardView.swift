//
//  EditStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/15.
//

import SwiftUI
import ActivityIndicatorView

struct EditStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    public var storyId: Int64
    public var boardId: Int64
    public var userId: Int64
    @StateObject var viewModel: UnpublishedStoryViewModel
    @State private var storyboardActive: StoryBoardActive?
    
    // 步骤状态控制
    @State private var currentStep = 0
    @State private var isLoading = false
    @State private var slideDirection: Int = 1 // 1 for forward, -1 for backward
    
    // 编辑故事板数据
    @State private var boardTitle: String = ""
    @State private var boardContent: String = ""
    @State private var scenes: [StoryboardScene] = []
    @State private var generatedImages: [String] = []
    
    var steps = ["编辑故事板", "创建场景", "编辑场景图片", "发布"]
    
    init(storyId: Int64, boardId: Int64, userId: Int64,viewModel: UnpublishedStoryViewModel) {
        self.storyId = storyId
        self.boardId = boardId
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack{
            if isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack {
                            ActivityIndicatorView(isVisible: $viewModel.isLoading, type: .arcs())
                                .frame(width: 64, height: 64)
                                .foregroundColor(.red)
                        }
                                .frame(height: 50)
                        Text("加载中......")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            }else{
                VStack(spacing: 0) {
                    // 自定义导航栏
                    CustomNavigationBar(title: "编辑故事板", presentationMode: presentationMode)
                        .background(Color.theme.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                    
                    // 进度指示器
                    StoryboardStepIndicatorView(steps: steps, currentStep: currentStep)
                        .padding(.vertical, 12)
                        .background(Color.theme.secondaryBackground)
                    
                    // 主要内容区域
                    ScrollView {
                        VStack(spacing: 20) {
                            switch currentStep {
                            case 0:
                                EditBoardStepView(
                                    title: $boardTitle,
                                    content: $boardContent,
                                    isLoading: $isLoading
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: slideDirection == 1 ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .move(edge: slideDirection == 1 ? .leading : .trailing)
                                            .combined(with: .opacity)
                                    )
                                )
                            case 1:
                                CreateScenesStepView(
                                    scenes: $scenes,
                                    isLoading: $isLoading
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: slideDirection == 1 ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .move(edge: slideDirection == 1 ? .leading : .trailing)
                                            .combined(with: .opacity)
                                    )
                                )
                            case 2:
                                PublishStepView(
                                    generatedImages: $generatedImages,
                                    isLoading: $isLoading
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: slideDirection == 1 ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .move(edge: slideDirection == 1 ? .leading : .trailing)
                                            .combined(with: .opacity)
                                    )
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                    .background(Color.theme.background)
                    
                    // 底部导航按钮
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(action: {
                                slideDirection = -1
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("上一步")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.theme.tertiaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.theme.tertiaryBackground)
                                .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        if currentStep < steps.count - 1 {
                            Button(action: {
                                slideDirection = 1
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text("下一步")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.theme.accent)
                                .clipShape(Capsule())
                            }
                        } else {
                            Button(action: handleFinish) {
                                HStack(spacing: 8) {
                                    Text("完成")
                                    Image(systemName: "checkmark")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.theme.accent)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(Color.theme.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
                }
                .background(Color.theme.background)
                .ignoresSafeArea(.all, edges: .bottom)
            }
            
        }
        .onAppear {
            // 初始化数据
            isLoading = true
            
            Task {
                let (board,err) = await self.viewModel.getStoryboardDetails(storyboardId: self.boardId)
                if let error = err {
                    print("Error fetching storyboard: \(error.localizedDescription)")
                }
                self.storyboardActive = board
                print("Storyboard fetched: \(String(describing: board))")
                
                if let board = storyboardActive {
                    currentStep = Int(board.boardActive.storyboard.stage.rawValue)
                    boardTitle = board.boardActive.storyboard.title
                    boardContent = board.boardActive.storyboard.content
                    print("Fetching storyboard details for boardId: \(self.boardId) currentSteop: \(self.currentStep)")
                }
                if board?.boardActive.storyboard.sences.list.isEmpty == false {
                    // 初始化场景数据
                    scenes = board?.boardActive.storyboard.sences.list.map { scene in
                        StoryboardScene(title: (board?.boardActive.storyboard.title)!, description: scene.content)
                    } ?? []
                    
                }
                isLoading = false
            }
        }
    }
    
    private func handleFinish() {
        // 实现完成逻辑
        isLoading = true
        // TODO: 调用相关 API 保存更新
        // 完成后关闭视图
        presentationMode.wrappedValue.dismiss()
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
