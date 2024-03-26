//
//  User.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import SwiftUI
import SwiftData

typealias User = Common_UserInfo
typealias UserProfile = Common_UserProfileInfo

@available(iOS 17, *)
@Model
class UserModel {
    @Attribute(.unique) var name: String
    var destination: String
    var avatar: String
    var userid: Int64
    var realUser: User
    init(name: String, destination: String, avatar: String, userid: Int64, realUser: User) {
        self.name = name
        self.destination = destination
        self.avatar = avatar
        self.userid = userid
        self.realUser = realUser
    }
}

@available(iOS 17, *)
class UserProfileModel{
    @Attribute(.unique) var name :String
    var realProfile: UserProfile
    init(name: String, realProfile: UserProfile) {
        self.name = name
        self.realProfile = realProfile
    }
}




