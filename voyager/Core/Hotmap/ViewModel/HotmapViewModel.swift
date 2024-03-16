//
//  HotmapViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/12/27.
//

import Foundation

class HotmapViewModel: ObservableObject {
    var starttime: Int64
    var endtime: Int64
    var currentOperator: User
    var area: String
    
    init(starttime: Int64, endtime: Int64, currentOperator: User, area: String) {
        self.starttime = starttime
        self.endtime = endtime
        self.currentOperator = currentOperator
        self.area = area
    }
}
