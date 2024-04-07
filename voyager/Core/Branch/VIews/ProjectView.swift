//
//  ProjectView.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import SwiftUI

struct ProjectView: View {
    var textValue: String
    var numberValue = 42
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Go to detail A", value: "Show AAAA")
                NavigationLink("Go to B", value: "Show BBB")
                NavigationLink("Go to number 1", value: 1)
            }
            .navigationDestination(for: String.self) {_ in 
                Text(textValue)
            }
            .navigationDestination(for: Int.self) { numberValue in
                Text("Detail with \(numberValue)")
            }
            .navigationTitle("Root view")
        }
    }
}

#Preview {
    ProjectView(textValue: "preview")
}
