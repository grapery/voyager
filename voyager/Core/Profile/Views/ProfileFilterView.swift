import SwiftUI

struct ProfileFilterView: View {
    @Binding var selectedFilter: UserProfileFilterViewModel
    
    var body: some View {
        HStack {
            ForEach(UserProfileFilterViewModel.allCases, id: \.rawValue) { item in
                VStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(selectedFilter == item ? .semibold : .regular)
                        .foregroundColor(selectedFilter == item ? .primary : .secondary)
                    
                    Capsule()
                        .foregroundColor(selectedFilter == item ? .primary : .secondary)
                        .frame(height: 3)
                }
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        selectedFilter = item
                    }
                }
            }
        }
        .overlay(Divider().offset(x: 0, y: 17))
    }
} 