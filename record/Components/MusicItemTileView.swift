//
//  MusicItemTileView.swift - Updated
//  record
//

import SwiftUI
import MusicKit

struct MusicItemTileView: View {
    var title: String
    var artist: String
    var albumName: String?
    var artworkID: String
    var onSelect: () -> Void
    @ObservedObject var musicAPI: MusicAPIManager
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    
    // Add properties for tracking if a song is already ranked
    var isAlreadyRanked: Bool = false
    var currentRank: Int = 0
    var currentScore: Double = 0.0
    
    // For albums - to show if already reviewed
    var searchType: SearchType = .song
    
    var body: some View {
        Button(action: {
            onSelect()
        }) {
            HStack(spacing: 12) {
                // Album art from Apple Music
                RemoteArtworkView(
                    artworkURL: musicAPI.getArtworkURL(for: artworkID),
                    placeholderText: title,
                    size: CGSize(width: 60, height: 60)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(artist)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    if let albumName = albumName, albumName != title {
                        Text(albumName)
                            .font(.system(size: 12))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                
                Spacer()
                
                // Show ranking information, album rating, or add button
                if searchType == .album {
                    if let albumRating = getAlbumRating() {
                        HStack(spacing: 8) {
                            // Compact star rating display
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", albumRating.rating))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(.secondaryLabel))
                            
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.accentColor)
                        }
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.accentColor)
                    }
                } else if isAlreadyRanked {
                    HStack(spacing: 8) {
                        // Ranking info
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("#\(currentRank)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.accentColor)
                            
                            Text(String(format: "%.1f", currentScore))
                                .font(.system(size: 14))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        // Re-rank button that matches the plus button style
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.accentColor)
                    }
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.accentColor)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Check if album is already rated
    private func getAlbumRating() -> AlbumRating? {
        // Only relevant for album search type
        guard searchType == .album else { return nil }
        
        // For albums, we need to check all album ratings to find a match based on title and artist
        return albumRatingManager.albumRatings.first { rating in
            rating.title.lowercased() == title.lowercased() &&
            rating.artist.lowercased() == artist.lowercased()
        }
    }
}

#Preview("Song Search Item") {
    let mockMusicAPI = MusicAPIManager()
    
    VStack(spacing: 20) {
        MusicItemTileView(
            title: "Song Title",
            artist: "Artist Name",
            albumName: "Album Name",
            artworkID: "1234",
            onSelect: {},
            musicAPI: mockMusicAPI
        )
        
        MusicItemTileView(
            title: "Ranked Song",
            artist: "Ranked Artist",
            albumName: "Ranked Album",
            artworkID: "5678",
            onSelect: {},
            musicAPI: mockMusicAPI,
            isAlreadyRanked: true,
            currentRank: 3,
            currentScore: 8.5
        )
    }
    .padding()
    .environmentObject(AlbumRatingManager())
}

#Preview("Album Search Item") {
    let mockMusicAPI = MusicAPIManager()
    let albumRatingManager = AlbumRatingManager()
    
    // Create a mock rating
    let rating = AlbumRating(
        albumId: "1234",
        title: "Rated Album",
        artist: "Rated Artist",
        rating: 4.5
    )
    albumRatingManager.saveRating(rating)
    
    return VStack(spacing: 20) {
        MusicItemTileView(
            title: "Unrated Album",
            artist: "Artist Name",
            artworkID: "9876",
            onSelect: {},
            musicAPI: mockMusicAPI,
            searchType: .album
        )
        
        MusicItemTileView(
            title: "Rated Album",
            artist: "Rated Artist",
            artworkID: "1234",
            onSelect: {},
            musicAPI: mockMusicAPI,
            searchType: .album
        )
    }
    .padding()
    .environmentObject(albumRatingManager)
}
