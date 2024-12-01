import SwiftUI

struct ProfileDescriptionView: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if description.isEmpty {
                Text("神秘的人物，没有简介!")
                    .font(.body)
                    .lineLimit(3)
            } else {
                Text(description)
                    .font(.body)
                    .lineLimit(3)
            }
        }
    }
} 