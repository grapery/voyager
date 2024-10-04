//
//  CircularProfileImageView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

enum ProfileImageSize {
    case profile
    case leaf
    case InChat
    case inProject
    case inGroup
    case search
    
    var dimension: CGFloat {
        switch self {
        case .profile:
            return 80
        case .leaf:
            return 60
        case .InChat:
            return 20
        case .inProject:
            return 25
        case .inGroup:
            return 30
        case .search:
            return 50
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

struct RoundedShape: Shape {
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: 80, height: 80))
        return Path(path.cgPath)
    }
    
}
