//
//  ThemeSelectorView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ThemeSelectorView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    
    private let colorOptions = [
        Color(red: 0.94, green: 0.3, blue: 0.9),   // Neon Pink
        Color(red: 0.3, green: 0.85, blue: 0.9),   // Cyan
        Color(red: 0.9, green: 0.4, blue: 0.4),    // Coral
        Color(red: 0.5, green: 0.9, blue: 0.3),    // Lime
        Color(red: 0.9, green: 0.7, blue: 0.2)     // Gold
    ]
    
    var body: some View {
        selectorContent
    }
    
    // Break up the view into smaller parts
    private var selectorContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleView
            colorOptionsView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    private var titleView: some View {
        Text("Profile Theme")
            .font(.headline)
            .foregroundColor(.white)
    }
    
    private var colorOptionsView: some View {
        HStack(spacing: 15) {
            ForEach(colorOptions, id: \.self) { color in
                colorButton(for: color)
            }
        }
    }
    
    private func colorButton(for color: Color) -> some View {
        Button(action: {
            profileManager.accentColor = color
        }) {
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: 35, height: 35)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: profileManager.accentColor == color ? 2 : 0)
                )
                .shadow(color: color.opacity(0.7), radius: 5)
        }
    }
}
