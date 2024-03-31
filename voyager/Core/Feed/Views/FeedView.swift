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

struct FeedView: View {
    public var user: User? {
        return viewModel.user
    }
    @StateObject var viewModel : FeedViewModel
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(timeStamp: 0, user: user))
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
                        LeafCell(leaves: item.items[0])
                            .padding(.bottom, 24)
                        Divider()
                    }
                }
            }
            .padding(.top, 1)
        }
    }
}
