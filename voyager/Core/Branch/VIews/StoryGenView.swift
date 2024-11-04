//
//  StoryGenView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//


import SwiftUI
import Kingfisher
import Combine

struct StoryGenView: View {
    @Binding var generatedStory: Common_RenderStoryDetail?
    @Binding var isGenerating: Bool
    @Binding var errorMessage: String?
    @Binding var viewModel: StoryViewModel
    @Binding var selectedTab: Int64

    var body: some View {
        VStack {
            if isGenerating {
                Spacer()
                ProgressView("生成中...")
                Spacer()
            } else if let story = generatedStory {
                storyContentView(story: story)
            } else if let error = errorMessage {
                Spacer()
                Text("错误: \(error)")
                    .foregroundColor(.red)
                Spacer()
            }
        }.onAppear(){
            Task{ @MainActor in
                let result = await self.viewModel.getGenStory(storyId: self.viewModel.storyId, userId: self.viewModel.userId)
                    print("StoryGenView help getGenerateStory ")
                    if let error = result.1 {
                        self.errorMessage = error.localizedDescription
                        self.generatedStory = nil
                        isGenerating = false
                    } else {
                        self.generatedStory = result.0
                        self.errorMessage = nil
                    }
            }
        }
    }
    
    private func storyContentView(story: Common_RenderStoryDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 故事信息
                VStack(alignment: .leading) {
                    Text("故事名称: \(story.result["story"]!.data["故事名称"]?.text ?? "名称未指定")")
                        .font(.headline)
                    Text("故事简介: \(story.result["story"]!.data["故事简介"]?.text ?? "简介不详")")
                        .font(.body)
                    Spacer()
                    HStack {
                        Button(action: {
                            Task{@MainActor in
                                await self.viewModel.applyStorySummry(storyId: (self.viewModel.story?.storyInfo.id)!, theme: story.result["story"]!.data["故事名称"]!.text, summry: story.result["story"]!.data["故事简介"]!.text, userId: self.viewModel.userId)
                            }
                        }) {
                            HStack {
                                Image(systemName: "signpost.right.and.left")
                                Text("使用简介")
                            }
                            .scaledToFill()
                        }
                        Button(action: {
                            // 编辑故事简介
                        }) {
                            HStack {
                                Image(systemName: "highlighter")
                                Text("编辑")
                            }
                            .scaledToFill()
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // 章节详细情节
                ForEach(Array(story.result.keys.sorted().filter { $0 != "story" }), id: \.self) { key in
                    if let chapter = story.result[key] {
                        VStack(alignment: .leading) {
                            Text("\(key): \(chapter.data["章节题目"]?.text ?? "无标题")")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text("内容: \(chapter.data["章节内容"]?.text ?? "无内容")")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.top, 2)
                            Spacer()
                            
                            HStack {
                                Spacer()
                                // 使用按钮
                                Button {
                                    Task {
                                        await viewModel.applyStoryBoard(
                                            storyId: (viewModel.story?.storyInfo.id)!,
                                            title: chapter.data["章节题目"]?.text ?? "",
                                            content: chapter.data["章节内容"]?.text ?? "",
                                            userId: viewModel.userId
                                        )
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "signpost.right.and.left")
                                        Text("使用")
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                // 分叉按钮
                                Button {
                                    // 在这里添加分叉逻辑
                                    print("分叉按钮被点击")
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.triangle.branch")
                                        Text("分叉")
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                // 编辑按钮
                                Button {
                                    // 在这里添加编辑逻辑
                                    print("编辑按钮被点击")
                                } label: {
                                    HStack {
                                        Image(systemName: "highlighter")
                                        Text("编辑")
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                            }
                            .foregroundColor(.secondary)
                            .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
}


