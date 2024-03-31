//
//  GroupView.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import SwiftUI

struct GroupView: View {
    public var user: User?
    @StateObject var viewModel : GroupViewModel
    init(user: User,name: String) {
        self._viewModel = StateObject(wrappedValue: GroupViewModel(name: name, user: user))
        self.user = user
    }
    var body: some View {
        Text("Group view")
    }
}
