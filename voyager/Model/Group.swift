//
//  Group.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import Foundation

// 小组，或者志趣相投的一群人

class BranchGroup: Identifiable{
    var info: Common_GroupInfo
    init( info: Common_GroupInfo) {
        self.info = info
    }
}

class GroupProfile: Identifiable{
    var profile: Common_GroupProfileInfo
    init(profile: Common_GroupProfileInfo) {
        self.profile = profile
    }
}
