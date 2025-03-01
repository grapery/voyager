//
//  MediaPlay.swift
//  voyager
//
//  Created by grapestree on 2024/12/26.
//

import SwiftUI
import Kingfisher
import Combine
import AVKit


enum MediaType {
    case image
    case video
}

// 媒体项目视图
struct MediaItemView: View {
    let item: MediaItem
    @State private var isPresented = false
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Group {
                switch item.type {
                case .image:
                    RectProfileImageView(avatarUrl: item.url.description, size: .InContent)
                case .video:
                    ZStack {
                        if let thumbnail = item.thumbnail {
                            KFImage(thumbnail)
                                .resizable()
                                .scaledToFill()
                        }
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .sheet(isPresented: $isPresented) {
            MediaDetailView(item: item)
        }
    }
}

// 媒体详情视图
struct MediaDetailView: View {
    let item: MediaItem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Group {
                switch item.type {
                case .image:
                    KFImage(item.url)
                        .resizable()
                        .scaledToFit()
                case .video:
                    VideoPlayer(url: item.url)
                }
            }
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 视频播放器视图
struct VideoPlayer: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
