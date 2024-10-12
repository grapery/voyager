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
                                // Label("分叉", systemImage: "signpost.right.and.left")
                                //     .scaledToFit()
                                //     .frame(width: 72, height: 48)
                                //     .foregroundColor(.blue)
                                //     .onTapGesture {
                                //         // 分叉
                                //         self.selectedTab = 1
                                //     }
                                Button(action: {
                                    // 处理点赞逻辑
                                    self.selectedTab = 1
                                }) {
                                    HStack {
                                        Image(systemName: "signpost.right.and.left")
                                        Text("分叉")
                                    }

                                    .scaledToFill()
                                }
                                //Spacer().frame(width: 48, height: 48)
                                // Label("编辑", systemImage: "highlighter")
                                //     .scaledToFit()
                                //     .frame(width: 72, height: 48)
                                //     .foregroundColor(.blue)
                                //     .onTapGesture {
                                //         // 编辑
                                //         self.selectedTab = 1
                                //     }
                                Button(action: {
                                    // 处理评论逻辑
                                    self.selectedTab = 1
                                }) {
                                    HStack {
                                        Image(systemName: "highlighter")
                                        Text("编辑")
                                    }
                                    .scaledToFill()
                                }
                                //Spacer().frame(width: 48, height: 48)
                                // Label("故事板", systemImage: "tree.circle")
                                //     .scaledToFit()
                                //     .frame(width: 72, height: 48)
                                //     .foregroundColor(.blue)
                                //     .onTapGesture {
                                //         // 故事板
                                //         self.selectedTab = 0
                                //     }
                                // }
                                Button(action: {
                                    // 处理转发逻辑
                                    self.selectedTab = 0
                                }) {
                                    HStack {
                                        Image(systemName: "tree.circle")
                                        Text("故事板")
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
                    }
                }
            }
            .padding()
        }
    }
}


