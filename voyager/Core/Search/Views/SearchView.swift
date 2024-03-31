//
//
//  SearchView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct SearchView: View {
    
    @State private var searchText = ""
    
    @StateObject var viewModel = SearchViewModel()
    
    var body: some View {
        Text("")
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
