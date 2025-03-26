//
//  NewStoryView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI
import PhotosUI

struct NewStoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: StoryViewModel
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var title: String = ""
    @State private var shortDesc: String = ""
    @State private var origin: String = ""
    @State private var isAIGen: Bool = false
    @State private var storyDescription: String = ""
    @State private var refImages: [UIImage]?
    @State private var negativePrompt: String = ""
    @State private var background: String = ""
    
    @State private var showImagePicker: Bool = false
    @State var groupId: Int64
    
    init(groupId: Int64, userId: Int64) {
        let story = Story(
            Id: 0,
            storyInfo: Common_Story()
        )
        self._viewModel = StateObject(wrappedValue: StoryViewModel(story: story, userId: userId))
        self.groupId = groupId
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("创建新故事")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.primaryText)
                        .padding(.top, 50)
                    
                    VStack(spacing: 15) {
                        customTextField(title: "标题", text: $title)
                        customTextField(title: "简短描述", text: $shortDesc)
                        customTextEditor(title: "故事内容", text: $origin)
                        
                        Toggle("使用AI生成", isOn: $isAIGen)
                            .padding(.horizontal, 30)
                            .tint(Color.theme.accent)
                        
                        customTextField(title: "故事描述", text: $storyDescription)
                        customTextField(title: "负面提示", text: $negativePrompt)
                        customTextField(title: "背景", text: $background)
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Text(refImages?.isEmpty ?? true ? "添加参考图片" : "更改参考图片")
                                .font(.headline)
                                .foregroundColor(Color.theme.buttonText)
                                .frame(width: 330, height: 50)
                                .background(Color.theme.accent)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 30)
                        
                        if let images = refImages, !images.isEmpty {
                            imageGrid(images: images)
                        }
                    }
                    
                    Button(action: createStory) {
                        Text("创建故事")
                            .font(.headline)
                            .foregroundColor(Color.theme.buttonText)
                            .frame(width: 330, height: 50)
                            .background(Color.theme.primary)
                            .cornerRadius(14)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("错误"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $refImages)
        }
        .navigationBarItems(leading: cancelButton)
    }
    
    private var cancelButton: some View {
        Button("取消") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(Color.theme.accent)
    }
    
    private func customTextField(title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .autocapitalization(.none)
            .font(.subheadline)
            .foregroundColor(Color.theme.inputText)
            .padding(14)
            .background(Color.theme.inputBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .padding(.horizontal, 30)
    }
    
    private func customTextEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.theme.secondaryText)
                .padding(.leading, 30)
            
            TextEditor(text: text)
                .font(.subheadline)
                .foregroundColor(Color.theme.inputText)
                .padding(10)
                .frame(height: 100)
                .background(Color.theme.inputBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.border, lineWidth: 0.5)
                )
                .padding(.horizontal, 30)
        }
    }
    
    private func imageGrid(images: [UIImage]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(images.prefix(4).enumerated().map({$0}), id: \.element) { index, image in
                if index == 3 && images.count > 4 {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(10)
                        Color.theme.primaryText.opacity(0.6)
                        Text("+\(images.count - 3)")
                            .foregroundColor(Color.theme.buttonText)
                            .font(.title2)
                    }
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.theme.border, lineWidth: 0.5)
                        )
                }
            }
        }
        .frame(height: 220)
        .padding(.horizontal, 30)
    }
    
    private func createStory() {
        self.viewModel.story?.storyInfo.title = self.title
        self.viewModel.story?.storyInfo.desc = self.shortDesc
        self.viewModel.story?.storyInfo.origin = self.origin
        self.viewModel.story?.storyInfo.params.storyDescription = self.storyDescription
        self.viewModel.story?.storyInfo.params.negativePrompt = self.negativePrompt
        self.viewModel.story?.storyInfo.isAiGen = self.isAIGen
        self.viewModel.story?.storyInfo.params.background = self.background
        self.viewModel.story?.storyInfo.groupID = self.groupId
        self.viewModel.story?.storyInfo.creatorID = self.viewModel.userId
        
        Task {@MainActor in
            do {
                await self.viewModel.CreateStory(groupId: self.groupId)
                
                if self.viewModel.isCreateOk {
                    presentationMode.wrappedValue.dismiss()
                    print("create new story success \(self.viewModel.story?.storyInfo.title ?? self.title)")
                } else if let error = self.viewModel.err {
                    showAlert(message: error.localizedDescription)
                }
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
