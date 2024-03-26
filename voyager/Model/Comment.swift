//
//  Comment.swift
//  voyager
//
//  Created by grapestree on 2024/3/25.
//

import Foundation

class Comment: Identifiable,Codable{
    var id: String
    var realComment: Comment
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.realComment = try container.decode(Comment.self, forKey: .realComment)
    }
}
