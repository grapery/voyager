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

extension User{
    init(userID: Int64, name: String,avatar : String){
        self.userID = userID
        self.name = name
        self.avatar = avatar
    }
}

typealias UserProfile = Common_UserProfileInfo


class UserActivity: Identifiable{
    var id: String
    var activity: Common_ActiveInfo
    var activitytype: Common_ActiveType
    init(id: String, activity: Common_ActiveInfo) {
        self.id = UUID().uuidString
        self.activity = activity
        self.activitytype = activity.activeType
    }
}
