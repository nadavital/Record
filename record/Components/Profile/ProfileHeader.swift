//
//  ProfileHeader.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI
    
struct ProfileHeader: View {
    @EnvironmentObject var profileManager: UserProfileManager
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
            Text(profileManager.bio.isEmpty ? "Add bio in settings" : profileManager.bio)
                .font(.subheadline)
                .foregroundColor(profileManager.bio.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
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
    ProfileHeader()
        .environmentObject(UserProfileManager())
}
