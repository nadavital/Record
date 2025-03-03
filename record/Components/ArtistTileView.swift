//
//  ArtistTileView.swift
//  record
//
//  Created by GitHub Copilot on 3/20/25.
//

import SwiftUI

struct ArtistTileView: View {
    let artist: Artist
    var size: CGFloat = 85
    var showDeleteButton: Bool = false
    var accentColor: Color
    var onDelete: ((Artist) -> Void)?
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            // Artist image - use the artwork if available or a placeholder
            ZStack(alignment: .topTrailing) {
                if let imageURL = artist.artworkURL {
                    RemoteArtworkView(
                        artworkURL: imageURL,
                        placeholderText: artist.name,
                        cornerRadius: size / 2, // Make it circular
                        size: CGSize(width: size, height: size)
                    )
                    .clipShape(Circle())
                    .shadow(radius: 2)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.7),
                                    accentColor.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            Text(artist.name.prefix(1).uppercased())
                                .font(.system(size: size * 0.38, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(radius: 2)
                }
                
                // Delete button when editing
                if showDeleteButton, let onDelete = onDelete {
                    Button {
                        withAnimation {
                            onDelete(artist)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 16)
                            )
                    }
                    .offset(x: 6, y: -6)
                }
            }
            
            // Artist name
            Text(artist.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: size)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ArtistTileView(
        artist: Artist(name: "Artist Name", artworkURL: nil),
        accentColor: .pink,
        onDelete: { _ in }
    )
}