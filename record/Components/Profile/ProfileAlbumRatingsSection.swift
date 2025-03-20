//
//  ProfileAlbumRatingsSection.swift
//  record
//
//  Created by Nadav Avital on 3/6/25.
//

import SwiftUI

struct ProfileAlbumRatingsSection: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @State private var showAllRatings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with navigation to full ratings list
            HStack {
                Text("Album Ratings")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: ReviewView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if profileManager.albumRatings.isEmpty {
                Text("Rate albums to display here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // Top rated albums
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(profileManager.getTopRatedAlbums(limit: 10)) { albumRating in
                            RatedAlbumView(albumRating: albumRating)
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
        .onAppear {
            profileManager.loadAlbumRatings()
        }
    }
}

struct RatedAlbumView: View {
    let albumRating: AlbumRating
    @EnvironmentObject var musicAPI: MusicAPIManager
    @State private var navigateToAlbumInfo = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Album artwork
            ZStack {
                NavigationLink(destination: AlbumInfoView(
                    album: Album(
                        id: UUID(uuidString: albumRating.albumId) ?? UUID(),
                        title: albumRating.title,
                        artist: albumRating.artist,
                        albumArt: albumRating.title,
                        artworkURL: albumRating.artworkURL
                    ),
                    musicAPI: musicAPI
                ), isActive: $navigateToAlbumInfo) {
                    EmptyView()
                }
                .opacity(0) // Hide the link
                
                RemoteArtworkView(
                    artworkURL: albumRating.artworkURL,
                    placeholderText: albumRating.title,
                    cornerRadius: 8,
                    size: CGSize(width: 100, height: 100)
                )
                .shadow(radius: 2)
                .onTapGesture {
                    navigateToAlbumInfo = true
                }
            }
            
            // Album info
            VStack(spacing: 4) {
                Text(albumRating.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(width: 100)
                    .multilineTextAlignment(.center)
                
                Text(albumRating.artist)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 100)
                    .multilineTextAlignment(.center)
                
                StarRatingView(
                    rating: albumRating.rating,
                    size: 12,
                    spacing: 2
                )
            }
        }
    }
}


#Preview {
    ProfileAlbumRatingsSection()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicAPIManager())
}
