//
//  StoryboardViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI
import Combine

class StoryBoardSence{
    var senceIndex: Int
    var content: String
    var characters: String
    var imagePrompt: String
    var senceId: Int64
    var imageUrl: String
    
    init(index: Int, content: String, characters: String, imagePrompt: String) {
        self.senceIndex = index
        self.content = content
        self.characters = characters
        self.imagePrompt = imagePrompt
        self.senceId = 0
        self.imageUrl = ""
    }
    
    // 从API响应数据创建场景
    static func fromResponse(_ data: Common_RenderStoryStructure, index: Int) -> StoryBoardSence? {
        let content = data.data["情节内容"]!.text
        let characters = data.data["参与人物"]!.text
        let imagePrompt = data.data["图片提示词"]!.text
        
        return StoryBoardSence(
            index: index,
            content: content,
            characters: characters,
            imagePrompt: imagePrompt
        )
    }
}


