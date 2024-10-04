//
//  FeedCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class FeedCellViewModel: ObservableObject {
    @Published var user: User?
    @Published var items: StoryItem?
    init(user: User? = nil, items: StoryItem? = nil) {
        self.user = user
        self.items = items
    }
    
    func like() async{
        //await APIClient.shared.
        print("like buttom is pressed")
    }
    
    func unlike() async{
        //await APIClient.shared.
        print("unlike buttom is pressed")
    }
    
    func fetchItemComments() async -> [Comment] {
        return [Comment]()
    }
    
    func addCommentForItem(comment:Comment) async -> Void{
        return
    }
    
    func share() async{
        //await APIClient.shared.
        print("share buttom is pressed")
    }
}
