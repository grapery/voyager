//
//  ActivityViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/4/8.
//

import Foundation

class ActivityViewModel: ObservableObject {
    @Published var activityType: Int32
    init(activityType: Int32) {
        self.activityType = activityType
    }
}
