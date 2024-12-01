import SwiftUI

struct ProfileStatsView: View {
    let storyCount: Int
    let roleCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "mountain.2")
                    .foregroundColor(.blue)
                Text("\(storyCount) 个故事")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
            HStack {
                Image(systemName: "poweroutlet.type.k")
                    .foregroundColor(.gray)
                Text("\(roleCount) 个故事角色")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }
} 