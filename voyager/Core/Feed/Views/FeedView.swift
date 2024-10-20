//
//  FeedView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

extension Date{
    var timeStamp: String{
        let formatter = DateFormatter()
        formatter.dateFormat = "s"
        return formatter.string(from: self)
    }
}

enum FeedType{
    case All
    case UserSelfAndFriend
    case Groups
    case Story
    case Timeline
}
    
// 获取用户的关注以及用户参与的故事，以及用户关注的小组的故事动态。不可以用户关注用户，只可以关注小组或者故事
struct FeedView: View {
    public var user: User? {
        return viewModel.user
    }
    public var feedType: FeedType
    @StateObject var viewModel : FeedViewModel
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(user: user))
        self.feedType = .UserSelfAndFriend
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                Image("VoyagerLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
                LazyVStack() {
                    ForEach(viewModel.leaves) { item in
                        LeafCell(info: item.realItem)
                            .padding(.bottom, 24)
                        Divider()
                    }
                }
            }
            .padding(.top, 1)
        }
    }
}
