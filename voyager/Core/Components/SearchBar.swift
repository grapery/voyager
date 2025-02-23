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
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $searchText)
                .font(.system(size: 15))
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}