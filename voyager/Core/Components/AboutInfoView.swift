//
//  AboutInfoView.swift
//  voyager
//
//  Created by grapestree on 2024/4/6.
//

import SwiftUI
import ScalingHeaderScrollView

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 添加你的按钮点击事件
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}


struct TestContentView: View {

    var body: some View {
       ScalingHeaderScrollView {
            ZStack {
                Rectangle()
                    .fill(.gray.opacity(0.15))
                Image("header")
            }
        } content: {
            Text("↓ Pull to refresh ↓")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
