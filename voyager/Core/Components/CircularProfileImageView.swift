//
//  CircularProfileImageView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

enum ProfileImageSize {
    case InProfile
    case InProfile2
    case InChat
    case InStory
    case InGroup
    case InSearch
    case InContent
    
    var dimension: CGFloat {
        switch self {
        case .InProfile:
            return 50
        case .InProfile2:
            return 100
        case .InChat:
            return 60
        case .InStory:
            return 25
        case .InGroup:
            return 30
        case .InSearch:
            return 50
        case .InContent:
            return 120
        }
    }
}

struct CircularProfileImageView: View {
    
    let avatarUrl: String
    let size: ProfileImageSize
    
    var body: some View {
        if !avatarUrl.isEmpty {
            KFImage(URL(string: self.avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
                .foregroundColor(Color(.systemGray5))
        }
    }
}

struct RectProfileImageView: View {
    
    let avatarUrl: String
    let size: ProfileImageSize
    
    var body: some View {
        if !avatarUrl.isEmpty {
            KFImage(URL(string: self.avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Rectangle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Rectangle())
                .foregroundColor(Color(.systemGray5))
        }
    }
}

struct RoundedShape: Shape {
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: 80, height: 80))
        return Path(path.cgPath)
    }
    
}

struct AvatarPreviewView: View {
    let imageURL: String
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color(.systemBackground).edgesIgnoringSafeArea(.all)
                    
                    KFImage(URL(string: imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                            .font(.system(size: 17, weight: .medium))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: URL(string: imageURL)!) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primary)
                            .font(.system(size: 17, weight: .medium))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
        }
        // 移除 .preferredColorScheme(.dark)
    }
}

