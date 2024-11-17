//
//  EditStoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/10/15.
//

import SwiftUI

struct EditStoryBoardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var storyId: Int64
    @Binding var boardId: Int64
    @StateObject var viewModel: StoryViewModel
    
    // 步骤状态控制
    @State private var currentStep = 0
    @State private var isLoading = false
    
    // 编辑故事板数据
    @State private var boardTitle: String = ""
    @State private var boardContent: String = ""
    @State private var scenes: [StoryboardScene] = []
    @State private var generatedImages: [String] = []
    
    var steps = ["编辑故事板", "创建场景", "发布"]
    
    var body: some View {
        NavigationView {
            VStack {
                // 进度指示器
                StoryboardStepIndicatorView(steps: steps, currentStep: currentStep)
                    .padding()
                
                // 主要内容区域
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0:
                            // 编辑故事板
                            EditBoardStepView(
                                title: $boardTitle,
                                content: $boardContent,
                                isLoading: $isLoading
                            )
                        case 1:
                            // 创建场景
                            CreateScenesStepView(
                                scenes: $scenes,
                                isLoading: $isLoading
                            )
                        case 2:
                            // 发布
                            PublishStepView(
                                generatedImages: $generatedImages,
                                isLoading: $isLoading
                            )
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // 底部导航按钮
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Finish") {
                            // 处理完成逻辑
                            handleFinish()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            })
            .navigationBarTitle("Edit StoryBoard", displayMode: .inline)
            .overlay(
                StoryboardLoadingView()
                    .opacity(isLoading ? 1 : 0)
            )
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

// 编辑故事板步骤视图
struct EditBoardStepView: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Your Storyboard")
                .font(.headline)
            
            TextField("Board Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextEditor(text: $content)
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
        }
    }
}

// 创建场景步骤视图
struct CreateScenesStepView: View {
    @Binding var scenes: [StoryboardScene]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Scenes")
                .font(.headline)
            
            // 场景列表
            ForEach(scenes.indices, id: \.self) { index in
                SceneItemView(scene: $scenes[index])
            }
            
            // 添加场景按钮
            Button(action: {
                scenes.append(StoryboardScene()) // 添加新场景
            }) {
                Label("Add Scene", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
        }
    }
}

// 发布步骤视图
struct PublishStepView: View {
    @Binding var generatedImages: [String]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review and Publish")
                .font(.headline)
            
            // 展示生成的图片
            if !generatedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(generatedImages, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
            }
            
            // 生成图片按钮
            Button("生成图片") {
                // 实现生成图片的逻辑
            }
            .buttonStyle(.bordered)
        }
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
        VStack(alignment: .leading) {
            TextField("Scene Title", text: $scene.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextEditor(text: $scene.description)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
    
    private let lineHeight: CGFloat = 4
    private let circleSize: CGFloat = 32
    private let activeColor = Color.blue
    private let inactiveColor = Color.gray.opacity(0.3)
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar with circles
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    // Step circle
                    Circle()
                        .fill(index <= currentStep ? activeColor : inactiveColor)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Group {
                                if index <= currentStep {
                                    Image(systemName: index == currentStep ? "\(index + 1).circle.fill" : "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .foregroundColor(.white)
                                }
                            }
                        )
                    
                    // Connecting line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? activeColor : inactiveColor)
                            .frame(height: lineHeight)
                    }
                }
            }
            
            // Step labels
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Text(steps[index])
                        .font(.caption)
                        .foregroundColor(index == currentStep ? activeColor : .gray)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal)
    }
}
