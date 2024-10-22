//
//  SearchBarView.swift
//  voyager
//
//  Created by grapestree on 2024/10/22.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onCommit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索...", text: $text, onCommit: onCommit)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
