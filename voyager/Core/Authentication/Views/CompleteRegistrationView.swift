//
//  CompleteRegistrationView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct CompleteRegistrationView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    var onComplete: () -> Void
    
    var body: some View {
        VStack {
            Image("VoyagerLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 50)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("欢迎使用 voyager, \(viewModel.username)")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
                .multilineTextAlignment(.center)
            
            Text("点击以下按钮完成注册")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button {
                Task {
                    await viewModel.createUser()
                    onComplete()
                }
            } label: {
                Text("注册完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(width: 330, height: 50)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.purple, .pink, .red, .yellow]), startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "arrowshape.left")
                    .imageScale(.large)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
    }
}

struct CompleteRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack{
            CompleteRegistrationView(onComplete: {})
        }
    }
}
