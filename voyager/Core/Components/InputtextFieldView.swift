//
//  InputtextFieldView.swift
//  voyager
//
//  Created by grapestree on 2024/4/6.
//

import SwiftUI

struct InputtextFieldView: View {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundColor(Color.theme.inputText)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.theme.inputBackground)
                    .shadow(color: Color.theme.accent.opacity(0.15), radius: 10, x: 0, y: 0)
            )
    }
}

#Preview {
    InputtextFieldView(text: .constant("Button"), placeholder: "Button placeholder", keyboardType: .default)
}

struct InputPasswordView: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .foregroundColor(Color.theme.inputText)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.theme.inputBackground)
                    .shadow(color: Color.theme.accent.opacity(0.15), radius: 10, x: 0, y: 0)
            )
    }
}

#Preview {
    InputPasswordView(text: .constant(""), placeholder: "Password")
}


struct InteractionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text("\(count)")
                    .font(.system(size: 14))
            }
            .foregroundColor(isActive ? color : Color.theme.tertiaryText)
        }
    }
}
