//
//  AboutInfoView.swift
//  voyager
//
//  Created by grapestree on 2024/4/6.
//

import SwiftUI

struct AboutInfoView: View {
    let defaultURL = URL(string: "https://www.grapery.xyz")!
    let youtubeURL = URL(string: "https://youtube.com/c/grapestree2020")!
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                List {
                    Section(header: Text("grapery")) {
                        VStack(alignment: .leading) {
                            Image("logo")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            Text("about info")
                                .font(.callout)
                                .bold()
                                .foregroundColor(Color.theme.accent)
                        }
                    }
                }
            }
            
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("about")
                }
            }
        }
    }
}
