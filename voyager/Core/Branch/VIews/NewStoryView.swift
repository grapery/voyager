//
//  NewStoryView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI
import PhotosUI
import ActivityIndicatorView

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
    @State private var negativePrompt: String = ""
    @State private var background: String = ""
    
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
            VStack(spacing: 0) {
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
                            
                            if isAIGen {
                                customTextField(title: "故事描述", text: $storyDescription)
                                customTextField(title: "负面提示", text: $negativePrompt)
                                customTextField(title: "背景", text: $background)
                            }
                        }
                        Spacer(minLength: 20)
                    }
                }
                Divider()
                HStack{
                    Button(action: createStory) {
                        Text("创建")
                            .font(.headline)
                            .foregroundColor(Color.theme.buttonText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.theme.primary)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 12)
                    .background(Color.theme.background)
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("取消")
                            .font(.headline)
                            .foregroundColor(Color.theme.buttonText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.theme.primary)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 12)
                    .background(Color.theme.background)
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
