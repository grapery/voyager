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
    case InChat
    case InStory
    case InGroup
    case InSearch
    case InContent
    
    var dimension: CGFloat {
        switch self {
        case .InProfile:
            return 80
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
