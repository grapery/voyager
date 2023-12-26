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
    
    @StateObject var viewModel = FeedViewModel(timeStamp: Int64(Date().timeStamp) ?? 0)
    
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
                        LeafCell(leaves: item)
                            .padding(.bottom, 24)
                        Divider()
                    }
                }
            }
            .padding(.top, 1)
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
