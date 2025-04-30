//
//  voyagerApp.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

@main
struct voyagerApp: App {
    init() {
        // 设置应用进入后台时清理缓存
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            KingfisherManager.shared.cache.clearMemoryCache()
            KingfisherManager.shared.cache.clearDiskCache()
        }
    }
    var body: some Scene {
        WindowGroup {
            GraperyApp()
        }
    }
}
