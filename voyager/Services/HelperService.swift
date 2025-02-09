//
//  HelperService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {
    func getSoftwareVersion() async -> String{
        return "1.0.0"
    }

    func getSoftwareUpdateInfo() async -> String{
        return "1.0.0"
    }
}
