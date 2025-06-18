import SwiftUI
import Kingfisher

// MARK: - Custom Segmented Control
struct CustomSegmentedControl: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<titles.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedIndex = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(titles[index])
                                .font(.system(size: 15))
                                .foregroundColor(selectedIndex == index ? Color.theme.accent : Color.theme.tertiaryText)
                            
                            Rectangle()
                                .fill(selectedIndex == index ? Color.theme.accent : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            Divider()
                .background(Color.theme.divider)
        }
        .background(Color.theme.background)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let count: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
            
            Text("\(count)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let image: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: image)
                .font(.system(size: 48))
                .foregroundColor(Color.theme.secondaryText)
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.secondaryText)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.secondaryText.opacity(0.8))
            Spacer()
        }
    }
} 