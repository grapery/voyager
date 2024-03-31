//
//  FeedCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class FeedCellViewModel: ObservableObject {
    var user: User?
    var item: StoryItem?
    init(user: User? = nil, item: StoryItem? = nil) {
        self.user = user
        self.item = item
    }
    
    func like() async{
        //await APIClient.shared.
        print("like buttom is pressed")
    }
    
    func unlike() async{
        //await APIClient.shared.
        print("unlike buttom is pressed")
    }
}
