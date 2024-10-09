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
                            Text("\(key)")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text("章节题目: \(chapter.data["章节题目"]?.text ?? "无标题")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            Text("章节内容: \(chapter.data["章节内容"]?.text ?? "无内容")")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.top, 2)
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

struct StoryChapter: Codable {
    let title: String
    let content: String
}

struct StoryDetail: Codable {
    let content: String
    let characters: String
    let imagePrompt: String
}

struct GeneratedStory: Codable {
    let chapterSummary: StoryChapter
    let chapterDetails: [String: StoryDetail]
    
    enum CodingKeys: String, CodingKey {
        case chapterSummary = "章节情节简述"
        case chapterDetails = "章节详细情节"
    }
}

