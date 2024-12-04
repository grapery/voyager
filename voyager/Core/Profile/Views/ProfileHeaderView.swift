import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 4) {
            CircularProfileImageView(avatarUrl: user.avatar.isEmpty ? defaultAvator : user.avatar, size: .InProfile)
            VStack(alignment: .leading) {
                Text(user.name)
                    .foregroundColor(.primary)
                    .font(.title)
                    .bold()
            }
        }
    }
} 
