//
//  ProfileSongsSection.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ProfileSongsSection: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isEditing: Bool
    @Binding var showSongPicker: Bool
    
    var body: some View {
        sectionContent
    }
    
    // Breaking up the view into smaller parts
    private var sectionContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader
            songsList
            addButton
        }
    }
    
    private var sectionHeader: some View {
        Text("Top Songs")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 10)
    }
    
    private var songsList: some View {
        ForEach(profileManager.pinnedSongs) { song in
            ProfileSongItemView(
                song: song,
                isEditing: isEditing,
                onRemove: {
                    if let index = profileManager.pinnedSongs.firstIndex(where: { $0.id == song.id }) {
                        profileManager.pinnedSongs.remove(at: index)
                    }
                }
            )
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        if isEditing {
            Button(action: {
                showSongPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Song")
                }
                .font(.subheadline)
                .foregroundColor(profileManager.accentColor)
                .padding(.vertical, 10)
            }
        }
    }
}
