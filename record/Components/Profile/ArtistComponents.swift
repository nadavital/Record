//
//  ArtistComponents.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI

struct ArtistView: View {
    var artist: Artist
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isEditingArtists: Bool
    var body: some View {
        ArtistTileView(
            artist: artist,
            size: 85,
            showDeleteButton: isEditingArtists,
            onDelete: { artist in
                profileManager.removePinnedArtist(artist)
            }
        )
    }
}
    
    
struct AddArtistButton: View {
    @Binding var showArtistPicker: Bool
    var body: some View {
        Button {
            showArtistPicker = true
        } label: {
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .frame(width: 85, height: 85)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                
                Text("Add Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var isEditingArtists: Bool = false
    @Previewable @State var showArtistPicker: Bool = false
    let artist: Artist = Artist(name: "Queen")
    HStack(spacing: 20) {
        ArtistView(artist: artist, isEditingArtists: $isEditingArtists)
        AddArtistButton(showArtistPicker: $showArtistPicker)
    }
    .environmentObject(UserProfileManager())
}
