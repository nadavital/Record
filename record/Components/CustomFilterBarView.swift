import SwiftUI

struct CustomFilterBarView: View {
    @Binding var selectedSegment: Int
    let segmentTitles: [String]
    
    @Namespace private var namespace
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<segmentTitles.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if index > 0 {
                                Image(systemName: sentimentIcon(for: index))
                                    .font(.subheadline)
                            }
                            Text(segmentTitles[index])
                                .fontWeight(selectedSegment == index ? .semibold : .regular)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selectedSegment == index {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(filterColor(for: index))
                                    .matchedGeometryEffect(id: "selectedFilter", in: namespace)
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    
    // Get color for filter background based on sentiment
    private func filterColor(for index: Int) -> Color {
        switch index {
        case 1: return .pink.opacity(0.2)       // Love
        case 2: return .blue.opacity(0.2)       // Fine
        case 3: return .orange.opacity(0.2)     // Dislike
        default: return Color.gray.opacity(0.15) // All
        }
    }
    
    // Get icon for sentiment in segment control
    private func sentimentIcon(for index: Int) -> String {
        switch index {
        case 1: return "heart.fill"       // Love
        case 2: return "hand.thumbsup"    // Fine
        case 3: return "hand.thumbsdown"  // Dislike
        default: return "music.note.list" // All
        }
    }
}

#Preview {
    CustomFilterBarView(
        selectedSegment: .constant(0),
        segmentTitles: ["All", "Loved", "Fine", "Disliked"]
    )
}
