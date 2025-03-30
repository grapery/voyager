import SwiftUI

// 通用顶部导航栏
struct CommonNavigationBar: View {
    let title: String
    var onAddTapped: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Spacer()
            if let onAddTapped = onAddTapped {
                Button(action: onAddTapped) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// 通用搜索栏
struct CommonSearchBar: View {
    @Binding var searchText: String
    var placeholder: String = "搜索"
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.theme.tertiaryText)
            TextField(placeholder, text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.inputText)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.theme.tertiaryText)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.theme.tertiaryBackground)
        .clipShape(Capsule())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
}