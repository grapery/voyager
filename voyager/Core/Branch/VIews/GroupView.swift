//
//  GroupView.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import SwiftUI
import Kingfisher

struct GroupView: View {
    public var user: User?
    @StateObject var viewModel : GroupViewModel
    init(user: User,name: String) {
        self._viewModel = StateObject(wrappedValue: GroupViewModel(name: name, user: user))
        self.user = user
    }
    var body: some View {
        Text("Group view")
        KFImage(URL(string: self.user!.avatar))
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
            .frame(width: 48, height: 48)
    }
}


struct GroupCellView: View{
    public var info: BranchGroup
    var body: some View{
        KFImage(URL(string: self.info.info.avatar))
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
            .frame(width: 48, height: 48)
    }
}
