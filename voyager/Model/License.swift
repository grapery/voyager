//
//  License.swift
//  voyager
//
//  Created by grapestree on 2024/3/25.
//

import Foundation
import SwiftData


// story的权限
typealias License = Int64


@available(iOS 17, *)
class LicenseDataModel{
    @Attribute(.unique) var id: String
    var name: String
    var content: String
    init(id: String, name: String, content: String) {
        self.id = id
        self.name = name
        self.content = content
    }
}
