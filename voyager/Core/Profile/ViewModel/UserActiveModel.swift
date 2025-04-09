//
//  UserActiveModel.swift
//  voyager
//
//  Created by grapestree on 2025/4/8.
//

import PhotosUI
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI



class UserActivityViewModel: ObservableObject {
    @Published var actives: [UserActivity]?
    var userId: Int64
    var lasttime: Int64
    var page = 0
    var pageSize = 10
    init(actives: [UserActivity]? = nil, userId: Int64, lasttime: Int64, page: Int = 0, pageSize: Int = 10) {
        self.actives = actives
        self.userId = userId
        self.lasttime = lasttime
        self.page = page
        self.pageSize = pageSize
    }
    
    func loadMoreActivities(userId: Int64, lasttime: Int64) async -> Error?{
        return nil
    }
    
    func fetchUserActivities(userId: Int64, lasttime: Int64) async -> Error?{
        return nil
    }
    
}
