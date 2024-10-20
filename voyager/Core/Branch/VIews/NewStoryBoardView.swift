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
    
    let isForkingStory: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(isForkingStory ? "故事分支" : "新的故事板")
                    .font(.largeTitle)
                    .padding()
                
                VStack(alignment: .leading){
                    Spacer()
                    Text("故事标题")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    TextField("故事标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    Spacer()
                    Text("故事描述")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    TextField("故事描述", text: $description)
                        .frame(height: 100)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    Spacer()
                    Text("故事背景")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    TextField("故事背景", text: $background)
                        .frame(height: 100)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    Spacer()
                    Text("参与人物")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    TextField("参与人物", text: $roles)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.green.opacity(0.2))
                    Spacer()
                }
                
//                VStack{
//                    Spacer()
//                    Button(action: {
//                        showImagePicker = true
//                    }) {
//                        VStack {
//                            Image(systemName: "plus")
//                                .font(.system(size: 50))
//                                .foregroundColor(.white)
//                            Text("参考图片")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                        }
//                        .frame(width: 120, height: 120)
//                        .background(Color.green.opacity(0.2))
//                        .cornerRadius(16)
//                        Spacer()
//                    }
//                }
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(8)
                
                if let images = images, !images.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(images.prefix(4), id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)
                                .clipped()
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxHeight: 220)
                }
                
                Divider()
                Text("续写的故事章节")
                ZStack{
                    VStack(alignment: .leading){
                        Text("标题")
                            .font(.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text(generatedStoryTitle)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Spacer()
                        Text("内容")
                            .font(.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text(generatedStoryContent)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                Spacer()
                if let generatedImage = generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                Divider()
                HStack {
                    Spacer()
                    Button(action: {
                        if self.title == "" {
                            
                        }
                        if self.description == "" {
                            
                        }
                        Task{
                            let ret = await self.viewModel.conintueGenStory(storyId: self.viewModel.storyId, userId: self.viewModel.userId, prevBoardId: self.boardId, prompt: self.prompt, title: self.title, desc: self.description, backgroud: self.background)
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
                    }) {
                        Text("续写")
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(16)
                    }
                    Spacer()
                    Button(action: {
                        Task{
                            let ret = await self.viewModel.createStoryBoard(prevBoardId: self.boardId, nextBoardId: 0, title: self.generatedStoryTitle, content: self.generatedStoryContent, isAiGen: true, backgroud: self.background, params: Common_StoryBoardParams())
                            if ret.1 != nil {
                                print("Err: ",ret.1?.localizedDescription as Any)
                                Alert(
                                    title: Text("完成故事板创建失败"),
                                    message: Text("完成故事板创建失败: \(String(describing: ret.1?.localizedDescription))"),
                                    primaryButton: .destructive(Text("Delete")) {
                                        presentationMode.wrappedValue.dismiss()
                                    },
                                    secondaryButton: .cancel()
                                )
                            }else{
                                print("value: ",ret.0?.id as Any)
                                print("story board: ",ret.0?.boardInfo.title as Any)
                            }
                        }
                    }) {
                        Text("完成")
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(16)
                    }
                    Spacer()
                    Button(action: {
                    }) {
                        Text("绘画")
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(16)
                    }
                    Spacer()
                    
                }
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $images)
        }
    }
}
