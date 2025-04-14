import SwiftUI
import Kingfisher

struct StoryCardView: View {
    let story: Story
    let userId: Int64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 故事封面图
            KFImage(URL(string: defaultAvator))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .clipped()
                .cornerRadius(8)
            
            // 故事标题
            Text(story.storyInfo.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.top, 8)
            
            // 作者信息
            HStack {
                // 作者头像
                KFImage(URL(string: defaultAvator))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                
                // 作者名称
                Text("创作者")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 互动数据
                HStack(spacing: 12) {
                    StoryCardStatLabel(icon: "heart", count: 2)
                    StoryCardStatLabel(icon: "bubble.left", count: 10)
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// 统计标签组件
struct StoryCardStatLabel: View {
    let icon: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// 空状态视图
struct StoryCardEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("暂无故事信息")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// 故事网格视图
struct StoryGridView: View {
    let stories: [Story]
    let userId: Int64
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(stories) { story in
                NavigationLink(destination: StoryView(story: story, userId: Int64(userId))) {
                    StoryCardView(story: story, userId: userId)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
    }
}
