//
//  Group.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import Foundation

// 小组，或者志趣相投的一群人

class BranchGroup: Identifiable, Hashable, Equatable {
    var info: Common_GroupInfo
    
    init(info: Common_GroupInfo) {
        self.info = info
    }
    
    // Hashable 协议要求
    func hash(into hasher: inout Hasher) {
        hasher.combine(info.groupID)  // 假设 Common_GroupInfo 有 id 属性
    }
    
    // Equatable 协议要求
    static func == (lhs: BranchGroup, rhs: BranchGroup) -> Bool {
        return lhs.info.groupID == rhs.info.groupID  // 假设 Common_GroupInfo 有 id 属性
    }
}

class GroupProfile: Identifiable, Hashable, Equatable {
    var profile: Common_GroupProfileInfo
    
    init(profile: Common_GroupProfileInfo) {
        self.profile = profile
    }
    
    // Hashable 协议要求
    func hash(into hasher: inout Hasher) {
        hasher.combine(profile.groupID)  // 假设 Common_GroupProfileInfo 有 id 属性
    }
    
    // Equatable 协议要求
    static func == (lhs: GroupProfile, rhs: GroupProfile) -> Bool {
        return lhs.profile.groupID == rhs.profile.groupID  // 假设 Common_GroupProfileInfo 有 id 属性
    }
}
