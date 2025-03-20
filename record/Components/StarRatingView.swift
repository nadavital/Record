//
//  StarRatingView.swift
//  record
//
//  Created by Nadav Avital on 3/6/25.
//

import SwiftUI

struct StarRatingView: View {
    let rating: Double
    let maxRating: Int
    let onTap: ((Double) -> Void)?
    let size: CGFloat
    let spacing: CGFloat
    let fillColor: Color
    let emptyColor: Color
    
    init(
        rating: Double,
        maxRating: Int = 5,
        onTap: ((Double) -> Void)? = nil,
        size: CGFloat = 20,
        spacing: CGFloat = 5,
        fillColor: Color = .yellow,
        emptyColor: Color = .gray.opacity(0.3)
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.onTap = onTap
        self.size = size
        self.spacing = spacing
        self.fillColor = fillColor
        self.emptyColor = emptyColor
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                starView(for: index)
                    .onTapGesture {
                        if let onTap = onTap {
                            // Handle half-star taps based on position
                            let halfStarIndex = Double(index) - 0.5
                            if rating == Double(index) {
                                // Tapping on a full star sets it to half
                                onTap(halfStarIndex)
                            } else if rating == halfStarIndex {
                                // Tapping on a half star clears it
                                onTap(Double(index - 1))
                            } else {
                                // Otherwise set to full star
                                onTap(Double(index))
                            }
                        }
                    }
            }
        }
    }
    
    private func starView(for index: Int) -> some View {
        let fillAmount = getFillAmount(for: index)
        
        // Use appropriate system image based on fill amount
        let systemName: String
        
        if fillAmount >= 1.0 {
            systemName = "star.fill"
        } else if fillAmount >= 0.5 {
            systemName = "star.leadinghalf.filled" 
        } else {
            systemName = "star"
        }
        
        return Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundStyle(fillAmount > 0 ? fillColor : emptyColor)
    }
    
    private func getFillAmount(for index: Int) -> Double {
        let fillAmount: Double
        
        if Double(index) <= rating {
            fillAmount = 1.0 // Full star
        } else if Double(index) - 0.5 <= rating {
            fillAmount = 0.5 // Half star
        } else {
            fillAmount = 0 // Empty star
        }
        
        return fillAmount
    }
}

struct StarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StarRatingView(rating: 0)
                .previewDisplayName("0 Stars")
            
            StarRatingView(rating: 2.5)
                .previewDisplayName("2.5 Stars")
            
            StarRatingView(rating: 3.5, size: 30, fillColor: .pink)
                .previewDisplayName("Custom 3.5 Stars")
            
            StarRatingView(rating: 5)
                .previewDisplayName("5 Stars")
        }
        .padding()
    }
}