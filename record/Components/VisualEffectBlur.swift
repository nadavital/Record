//
//  VisualEffectBlur.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

// Enhanced helper for glass blur effect with vibrancy and adaptive styling
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var vibrancyStyle: UIVibrancyEffectStyle? = nil
    var blurIntensity: CGFloat? = nil
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Add vibrancy effect if specified
        if let vibrancyStyle = vibrancyStyle {
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyStyle)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            blurView.contentView.addSubview(vibrancyView)
            
            // Make vibrancy view fill the blur view
            vibrancyView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                vibrancyView.heightAnchor.constraint(equalTo: blurView.heightAnchor),
                vibrancyView.widthAnchor.constraint(equalTo: blurView.widthAnchor),
                vibrancyView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
                vibrancyView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor)
            ])
        }
        
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// Glassmorphic card style for SwiftUI
struct GlassmorphicCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Light blur effect
                    VisualEffectBlur(
                        blurStyle: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterial
                    )
                    
                    // Semi-transparent overlay
                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.6 : 0.8),
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.15), radius: 10, y: 5)
    }
}

// Extension to make the glassmorphic card style easily applicable
extension View {
    func glassmorphic(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassmorphicCard(cornerRadius: cornerRadius))
    }
}
