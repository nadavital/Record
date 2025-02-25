//
//  ProfileHeaderView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isEditing: Bool
    
    var body: some View {
        headerContent
    }
    
    // Break the view into smaller components
    private var headerContent: some View {
        VStack {
            profileImage
            usernameView
            bioView
            editButton
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
    
    private var profileImage: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            profileManager.accentColor.opacity(0.3),
                            profileManager.accentColor.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    profileManager.accentColor,
                                    profileManager.accentColor.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: profileManager.accentColor.opacity(0.5), radius: 10)
            
            Text(profileManager.username.prefix(1))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var usernameView: some View {
        Text(profileManager.username)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 5)
    }
    
    private var bioView: some View {
        Text(profileManager.bio)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 2)
    }
    
    private var editButton: some View {
        Button(action: {
            isEditing.toggle()
        }) {
            Text(isEditing ? "Done" : "Edit Profile")
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(profileManager.accentColor.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(profileManager.accentColor.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .padding(.top, 10)
    }
}
