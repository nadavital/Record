import SwiftUI
import MusicKit

struct AlbumInfoView: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @StateObject private var viewModel: AlbumInfoViewModel
    @StateObject private var albumRatingManager = AlbumRatingManager()
    
    let album: Album
    
    @State private var isEditingReview = false
    @State private var reviewText = ""
    @State private var reviewRating: Double = 0
    @State private var selectedTrack: Track?
    
    init(album: Album, musicAPI: MusicAPIManager) {
        self.album = album
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
                        Button(action: prepareToEditReview) {
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
                        let rankedSongs = sortedRankedSongs()
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
        .sheet(isPresented: $isEditingReview) {
            reviewEditorSheet
        }
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
            loadCurrentRating()
        }
    }
    
    // MARK: - Review Editor
    private var reviewEditorSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                StarRatingView(
                    rating: reviewRating,
                    onTap: { reviewRating = $0 },
                    size: 30,
                    spacing: 8,
                    fillColor: .yellow
                )
                TextEditor(text: $reviewText)
                    .frame(height: 200)
                    .padding(4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
            .padding()
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Album Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditingReview = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReview()
                        isEditingReview = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func loadAlbumDetails() {
        viewModel.loadAlbumDetails(album: album)
    }
    
    private func loadCurrentRating() {
        if let rating = getAlbumRating() {
            reviewRating = rating.rating
            reviewText = rating.review
        }
    }
    
    private func getAlbumRating() -> AlbumRating? {
        albumRatingManager.getRating(forAlbumId: album.id.uuidString)
    }
    
    private func prepareToEditReview() {
        loadCurrentRating()
        isEditingReview = true
    }
    
    private func saveReview() {
        let rating = AlbumRating(
            albumId: album.id.uuidString,
            title: album.title,
            artist: album.artist,
            rating: reviewRating,
            review: reviewText,
            artworkURL: album.artworkURL
        )
        albumRatingManager.saveRating(rating)
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
