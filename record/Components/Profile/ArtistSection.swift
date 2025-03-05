//
//  ArtistSection.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI

struct ArtistSection: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isEditingArtists: Bool
    @Binding var showArtistPicker: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with edit button
            HStack {
                Text("Favorite Artists")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    isEditingArtists.toggle()
                } label: {
                    Text(isEditingArtists ? "Done" : "Edit")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if profileManager.pinnedArtists.isEmpty {
                Text("Add favorite artists to display here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                
                if !isEditingArtists {
                    Button {
                        isEditingArtists = true
                    } label: {
                        Text("Add Artists")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                // Artist scroll view with horizontal items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(profileManager.pinnedArtists) { artist in
                            ArtistView(artist: artist, isEditingArtists: $isEditingArtists)
                        }
                        
                        // Add button
                        if isEditingArtists {
                            AddArtistButton(showArtistPicker: $showArtistPicker)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    @Previewable @State var isEditingArtists = false
    @Previewable @State var showArtistPicker = false
    ArtistSection(isEditingArtists: $isEditingArtists,
                  showArtistPicker: $showArtistPicker)
    .environmentObject(UserProfileManager())
}
