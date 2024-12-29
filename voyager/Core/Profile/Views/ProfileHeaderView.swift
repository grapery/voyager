import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头像和用户名
            HStack(spacing: 12) {
                CircularProfileImageView(avatarUrl: user.avatar, size: .InProfile)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("欢迎大家来一起创作好玩的故事吧！")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
}
