//
//  ProfileHeader.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI
    
struct ProfileHeader: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var tempBio: String = ""
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 110, height: 110)
                
                Text(profileManager.username.prefix(1).uppercased())
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Username
            Text(profileManager.username)
                .font(.title2)
                .fontWeight(.bold)
            
            // Bio
            if isEditing {
                TextEditor(text: Binding(
                    get: { tempBio },
                    set: { newValue in
                        tempBio = newValue
                        profileManager.bio = newValue
                    }
                ))
                .font(.subheadline)
                .frame(height: 80)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                .onAppear {
                    tempBio = profileManager.bio
                }
            } else {
                Text(profileManager.bio.isEmpty ? "Tap edit to add bio" : profileManager.bio)
                    .font(.subheadline)
                    .foregroundColor(profileManager.bio.isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Edit Profile Button
            Button {
                withAnimation {
                    isEditing.toggle()
                }
            } label: {
                Text(isEditing ? "Done" : "Edit Profile")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(isEditing ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isEditing ? Color.accentColor : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isEditing ? Color.clear : Color(.systemGray4), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    ProfileHeader(isEditing: .constant(false))
        .environmentObject(UserProfileManager())
}
