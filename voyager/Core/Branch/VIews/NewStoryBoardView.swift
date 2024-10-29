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
    @State public var roles: String = ""
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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(isForkingStory ? "故事分支" : "新的故事板")
                        .font(.largeTitle)
                        .padding()
                    
                    // Content sections
                    contentSections
                }
                .padding(.bottom, 100) // Add padding for bottom timeline
            }
            
            // Bottom timeline buttons
            timelineButtons
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .edgesIgnoringSafeArea(.bottom)
                )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $images)
        }
    }
    
    
    // MARK: - Helper Functions
    private func generateStory() async {
        let ret = await self.viewModel.conintueGenStory(
            storyId: self.viewModel.storyId,
            userId: self.viewModel.userId,
            prevBoardId: self.boardId,
            prompt: self.prompt,
            title: self.title,
            desc: self.description,
            backgroud: self.background
        )
        print("value count: ",ret.0.result.values.count as Any)
        print("value: ",ret.0.result.values)
        if let firstResult = ret.0.result.values.first,
           let chapterTitle = firstResult.data["章节题目"]?.text {
            print("firstResult： ",firstResult)
            self.generatedStoryTitle = chapterTitle
            print("chapterTitle： ",chapterTitle)
        }
        
        if let firstResult = ret.0.result.values.first,
           let chapterContent = firstResult.data["章节内容"]?.text {
            print("firstResult： ",firstResult)
            self.generatedStoryContent = chapterContent
            print("chapterContent： ",chapterContent)
        }
    
    }
    
    private func saveStoryBoard() async {
        let ret = await self.viewModel.createStoryBoard(
            prevBoardId: self.boardId,
            nextBoardId: 0,
            title: self.generatedStoryTitle,
            content: self.generatedStoryContent,
            isAiGen: true,
            backgroud: self.background,
            params: Common_StoryBoardParams()
        )
        print("gen content: \(ret)")
        if let error = ret.1 {
            print("Error: ", error.localizedDescription)
        } else {
            print("Story board created: ", ret.0?.boardInfo.title ?? "")
        }
    }
    
    // MARK: - View Components
    private var contentSections: some View {
        VStack(alignment: .leading, spacing: 25) {
            storyBasicInfoSection

            imagesSection
            charactersSection
            if !generatedStoryTitle.isEmpty || !generatedStoryContent.isEmpty{
                generatedContentSection
            }
        }
        .padding(.horizontal)
    }
    
    private var timelineButtons: some View {
        VStack {
            Divider()
            HStack(spacing: 20) {
                ForEach([
                    ("续写", "pencil.circle"),
                    ("完成", "checkmark.circle"),
                    ("绘画", "paintbrush.fill")
                ], id: \.0) { (title, icon) in
                    TimelineButton(
                        title: title,
                        icon: icon,
                        action: {
                            switch title {
                            case "续写":
                                Task { await generateStory() }
                            case "完成":
                                Task { await saveStoryBoard() }
                            case "绘画":
                                // Handle drawing action
                                break
                            default:
                                break
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
        }
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
    let action: () -> Void
    
    var body: some View {
        VStack{
            Button(action: action) {
                VStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.2))
                .cornerRadius(16)
            }.clipShape(.circle)
            Text(title)
                .font(.caption)
        }
    }
}
