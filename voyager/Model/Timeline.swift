//
//  Timeline.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class TimeLineBranch: Identifiable{
    @Published var id: String
    @Published var rootId: Int64
    @Published var forkId: Int64
    @Published var timeStamp: Int64
    @Published var projectId: Int64
    @Published var creatorId: Int64
    init(info: Common_TimeLine) {
        self.id = UUID().uuidString
        self.rootId = info.rootID
        self.forkId = info.rootID
        self.timeStamp = info.ctime
        self.projectId = info.projectID
        self.creatorId = info.creatorID
    }
}
