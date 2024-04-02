//
//
//  SearchView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search...", text: $text)
                .padding(8)
                .padding(.horizontal, 24)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    }
                )
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 4)
    }
}

struct SearchView: View {
    @State public var searchText = ""
    public var user: User?
    @StateObject var viewModel = SearchViewModel(query: "", useAI: false, useLocation: false, offset: 0, limit: 10)
    
    var body: some View {
        VStack {
            SearchBar(text: $viewModel.query)
                .padding()
            ScrollView {
                LazyVStack {
//                    ForEach(viewModel.groups) { groupInfo in
//                        NavigationLink {
//                            GroupView(user: user!,name: groupInfo.name)
//                        } label: {
//                            //UserRowView(user: user)
//                        }
//                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
