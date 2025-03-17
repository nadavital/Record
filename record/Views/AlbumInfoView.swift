import SwiftUI
import MusicKit

struct AlbumInfoView: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    @StateObject private var viewModel: AlbumInfoViewModel
    @Environment(\.dismiss) private var dismiss
    
    let album: Album
    let isPresentedAsSheet: Bool
    
    @State private var selectedTrack: Track?
    @State private var shouldRateAfterDismiss = false
    
    init(album: Album, musicAPI: MusicAPIManager, isPresentedAsSheet: Bool = false) {
        self.album = album
        self.isPresentedAsSheet = isPresentedAsSheet
        _viewModel = StateObject(wrappedValue: AlbumInfoViewModel(musicAPI: musicAPI))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Album Header
                VStack(spacing: 12) {
                    RemoteArtworkView(
                        artworkURL: album.artworkURL,
                        placeholderText: album.title,
                        cornerRadius: 8,
                        size: CGSize(width: 200, height: 200)
                    )
                    .shadow(radius: 3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    VStack(spacing: 8) {
                        Text(album.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(album.artist)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("Total Plays: \(viewModel.totalPlayCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Review Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        Text("Review")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: showRatingOverlay) {
                            Text(getAlbumRating()?.review.isEmpty ?? true ? "Add Review" : "Edit")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                    }
                    if let rating = getAlbumRating(), rating.rating > 0 || !rating.review.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if rating.rating > 0 {
                                StarRatingView(
                                    rating: rating.rating,
                                    onTap: nil,
                                    size: 20,
                                    spacing: 4,
                                    fillColor: .yellow
                                )
                            }
                            if !rating.review.isEmpty {
                                Text(rating.review)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        Text("No review yet. Add one to share your thoughts!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Tracks Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tracks")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoadingAlbumDetails {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.albumSongs.isEmpty {
                        Text("No tracks available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        let rankedSongs = viewModel.getRankedSongs(rankingManager: rankingManager)
                        let unrankedSongs = viewModel.getUnrankedSongs(rankingManager: rankingManager)
                        
                        if !rankedSongs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Ranked Songs")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                ForEach(rankedSongs, id: \.id) { track in
                                    if let rankedSong = getRankedSong(for: track) {
                                        AlbumTrackTileView(
                                            track: track,
                                            rankedSong: rankedSong,
                                            onRank: { rankingManager.addNewSong(song: rankedSong) },
                                            onSelect: { selectedTrack = track }
                                        )
                                    }
                                }
                            }
                        }
                        if !unrankedSongs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(rankedSongs.isEmpty ? "Tracks" : "Other Tracks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                ForEach(unrankedSongs, id: \.id) { track in
                                    AlbumTrackTileView(
                                        track: track,
                                        rankedSong: nil,
                                        onRank: { rankingManager.addNewSong(song: convertTrackToSong(track)) },
                                        onSelect: { selectedTrack = track }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                Color.clear.frame(height: 80)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTrack) { track in
            SongInfoView(
                rankedSong: getRankedSong(for: track) ?? convertTrackToSong(track),
                musicAPI: musicAPI,
                rankingManager: rankingManager,
                presentationStyle: .sheetFromAlbum, // Specify it's from album view
                onReRankButtonTapped: {
                    rankingManager.addNewSong(song: getRankedSong(for: track) ?? convertTrackToSong(track))
                    selectedTrack = nil
                }
                // No need for onShowAlbum since we're already in the album view
            )
            .environmentObject(musicAPI)
            .environmentObject(rankingManager)
        }
        .onAppear {
            loadAlbumDetails()
        }
        .onChange(of: shouldRateAfterDismiss) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    rateAlbumDirectly()
                    shouldRateAfterDismiss = false
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func loadAlbumDetails() {
        viewModel.loadAlbumDetails(album: album)
    }
    
    private func getAlbumRating() -> AlbumRating? {
        albumRatingManager.getRating(forAlbumId: album.id.uuidString)
    }
    
    private func showRatingOverlay() {
        if isPresentedAsSheet {
            // First dismiss the sheet, then show the rating overlay
            shouldRateAfterDismiss = true
            dismiss()
        } else {
            // Show the rating overlay directly if not in a sheet
            rateAlbumDirectly()
        }
    }
    
    private func rateAlbumDirectly() {
        // First check if this album has an existing rating
        if let existingRating = albumRatingManager.getRating(forAlbumId: album.id.uuidString) {
            // Create an album with the same ID to ensure we find the match
            let ratingAlbum = Album(
                id: UUID(uuidString: existingRating.albumId) ?? album.id,
                title: album.title,
                artist: album.artist,
                albumArt: album.title,
                artworkURL: album.artworkURL
            )
            albumRatingManager.rateAlbum(ratingAlbum)
        } else {
            // Use album as is for new ratings
            albumRatingManager.rateAlbum(album)
        }
    }
    
    private func sortedRankedSongs() -> [Track] {
        let ranked = viewModel.getRankedSongs(rankingManager: rankingManager)
        return ranked.sorted { track1, track2 in
            let rank1 = rankingManager.rankedSongs.firstIndex(where: { $0.title.lowercased() == track1.title.lowercased() && $0.artist.lowercased() == track1.artistName.lowercased() }) ?? Int.max
            let rank2 = rankingManager.rankedSongs.firstIndex(where: { $0.title.lowercased() == track2.title.lowercased() && $0.artist.lowercased() == track2.artistName.lowercased() }) ?? Int.max
            return rank1 < rank2
        }
    }
    
    private func getRankedSong(for track: Track) -> Song? {
        rankingManager.rankedSongs.first {
            $0.title.lowercased() == track.title.lowercased() &&
            $0.artist.lowercased() == track.artistName.lowercased()
        }
    }
    
    private func convertTrackToSong(_ track: Track) -> Song {
        return Song(
            id: UUID(),
            title: track.title,
            artist: track.artistName,
            albumArt: album.title,
            sentiment: .fine,
            artworkURL: album.artworkURL
        )
    }
}
