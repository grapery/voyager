//
//  Timeline.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class TimeBranch: Identifiable{
    @Published var id: Int64
    @Published var rootId: Int64
    @Published var forkId: Int64
    @Published var timeStamp: Int64
    @Published var projectId: Int64
    init(id: Int64, rootId: Int64, forkId: Int64, timeStamp: Int64, projectId: Int64) {
        self.id = id
        self.rootId = rootId
        self.forkId = forkId
        self.timeStamp = timeStamp
        self.projectId = projectId
    }
}
