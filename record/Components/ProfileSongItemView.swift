//
//  ProfileSongItemView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//


//
//  ProfileSongItemView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ProfileSongItemView: View {
    let song: Song
    let isEditing: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            // Album art
            if let artworkURL = song.artworkURL {
                RemoteArtworkView(
                    artworkURL: artworkURL,
                    placeholderText: song.title,
                    cornerRadius: 6,
                    size: CGSize(width: 50, height: 50)
                )
            } else {
                // Fallback for songs without artwork URL
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(song.albumArt.prefix(1))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 5)
    }
}