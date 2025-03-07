//
//  AlbumInfoView.swift
//  record
//
//  Created by Claude on 3/6/25.
//

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
    @State private var currentRating: Double = 0
    @State private var showAddSongToast = false
    @State private var toastMessage = ""
    @State private var selectedTrack: Track? // Keep as Track
    @State private var selectedSong: MusicKit.Song? // New state for the fetched Song
    
    init(album: Album, musicAPI: MusicAPIManager) {
        self.album = album
        _viewModel = StateObject(wrappedValue: AlbumInfoViewModel(musicAPI: musicAPI))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AlbumHeaderView(
                    album: album,
                    rating: $currentRating,
                    onRatingChanged: updateRating
                )
                
                reviewSection
                
                Divider()
                
                tracksSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditingReview) {
            reviewEditorSheet
        }
        .sheet(item: $selectedSong) { song in
            SongRankingSheet(song: song, onDismiss: {
                selectedSong = nil
                selectedTrack = nil // Clear both
            })
            .environmentObject(musicAPI)
            .environmentObject(rankingManager)
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showAddSongToast)
        )
        .onAppear {
            loadAlbumDetails()
            loadCurrentRating()
        }
        .alert(item: Binding<String?>(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        )) { errorMessage in
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: selectedTrack) { newTrack in
            if let track = newTrack {
                fetchSongForTrack(track)
            }
        }
    }
    
    // MARK: - Review Section
    
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Review")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    prepareToEditReview()
                } label: {
                    if let albumRating = getAlbumRating(), !albumRating.review.isEmpty {
                        Text("Edit")
                    } else {
                        Text("Add Review")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if let albumRating = getAlbumRating(), !albumRating.review.isEmpty {
                Text(albumRating.review)
                    .font(.body)
                    .padding(.vertical, 8)
            } else {
                Text("No review yet. Tap 'Add Review' to write one.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var reviewEditorSheet: some View {
        NavigationView {
            VStack {
                TextEditor(text: $reviewText)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Album Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditingReview = false
                    }
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
    
    // MARK: - Tracks Section
    
    private var tracksSection: some View {
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
                        .padding()
                } else {
                    let rankedSongs = viewModel.getRankedSongs(rankingManager: rankingManager)
                    let unrankedSongs = viewModel.getUnrankedSongs(rankingManager: rankingManager)
                    
                    if !rankedSongs.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Ranked Songs")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(rankedSongs, id: \.id) { song in
                                AlbumTrackRow(
                                    song: song,
                                    isRanked: true,
                                    rankInfo: getRankInfo(for: song),
                                    onTap: {
                                        selectedTrack = song
                                    }
                                )
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    if !unrankedSongs.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rankedSongs.isEmpty ? "Tracks" : "Other Tracks")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(unrankedSongs, id: \.id) { song in
                                AlbumTrackRow(
                                    song: song,
                                    isRanked: false,
                                    onTap: {
                                        selectedTrack = song
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    
    // MARK: - Helper Methods
    
    private func fetchSongForTrack(_ track: Track) {
            Task {
                do {
                    var request = MusicCatalogSearchRequest(term: "\(track.title) \(track.artistName)", types: [MusicKit.Song.self])
                    request.limit = 1
                    let response = try await request.response()
                    
                    if let song = response.songs.first {
                        await MainActor.run {
                            self.selectedSong = song
                        }
                    } else {
                        await MainActor.run {
                            self.toastMessage = "Song not found in catalog"
                            self.showAddSongToast = true
                            self.selectedTrack = nil // Reset to avoid re-trigger
                        }
                    }
                } catch {
                    print("Error fetching song: \(error.localizedDescription)")
                    await MainActor.run {
                        self.toastMessage = "Failed to load song"
                        self.showAddSongToast = true
                        self.selectedTrack = nil
                    }
                }
            }
        }
    
    private func loadAlbumDetails() {
        viewModel.loadAlbumDetails(album: album)
    }
    
    private func loadCurrentRating() {
        if let rating = getAlbumRating() {
            self.currentRating = rating.rating
            self.reviewText = rating.review
        }
    }
    
    private func getAlbumRating() -> AlbumRating? {
        return albumRatingManager.getRating(forAlbumId: album.id.uuidString)
    }
    
    private func updateRating(_ newRating: Double) {
        self.currentRating = newRating
        
        // Create or update album rating
        let rating = getAlbumRating() ?? AlbumRating(
            albumId: album.id.uuidString,
            title: album.title,
            artist: album.artist,
            artworkURL: album.artworkURL
        )
        
        var updatedRating = rating
        updatedRating.rating = newRating
        
        // Save the rating
        albumRatingManager.saveRating(updatedRating)
    }
    
    private func prepareToEditReview() {
        if let rating = getAlbumRating() {
            reviewText = rating.review
        } else {
            reviewText = ""
        }
        isEditingReview = true
    }
    
    private func saveReview() {
        // Create or update album rating
        let rating = getAlbumRating() ?? AlbumRating(
            albumId: album.id.uuidString,
            title: album.title,
            artist: album.artist,
            rating: currentRating,
            artworkURL: album.artworkURL
        )
        
        var updatedRating = rating
        updatedRating.review = reviewText
        
        // Save the rating
        albumRatingManager.saveRating(updatedRating)
    }
    
    private func getRankInfo(for song: Track) -> (rank: Int, score: Double, sentiment: SongSentiment)? {
            let rankedSong = rankingManager.rankedSongs.first { rankedSong in
                rankedSong.title.lowercased() == song.title.lowercased() &&
                rankedSong.artist.lowercased() == song.artistName.lowercased()
            }
            
            if let rankedSong = rankedSong,
               let index = rankingManager.rankedSongs.firstIndex(of: rankedSong) {
                return (index + 1, rankedSong.score, rankedSong.sentiment)
            }
            
            return nil
    }
}

// MARK: - Album Header View

struct AlbumHeaderView: View {
    let album: Album
    @Binding var rating: Double
    let onRatingChanged: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Album artwork
            RemoteArtworkView(
                artworkURL: album.artworkURL,
                placeholderText: album.title,
                cornerRadius: 8,
                size: CGSize(width: 200, height: 200)
            )
            .shadow(radius: 3)
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Album info
            VStack(spacing: 8) {
                Text(album.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(album.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Star rating
            VStack(spacing: 8) {
                StarRatingView(
                    rating: rating,
                    onTap: onRatingChanged,
                    size: 30,
                    spacing: 8,
                    fillColor: .yellow
                )
                
                Text(rating > 0 ? String(format: "%.1f", rating) : "Not Rated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Album Track Row

struct AlbumTrackRow: View {
    let song: Track // Changed from MusicKit.Song to Track
    let isRanked: Bool
    var rankInfo: (rank: Int, score: Double, sentiment: SongSentiment)? = nil
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(song.trackNumber ?? 0)") // Still works as Track has trackNumber
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(song.artistName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isRanked, let info = rankInfo {
                    HStack(spacing: 8) {
                        sentimentIcon(for: info.sentiment)
                            .foregroundColor(info.sentiment.color)
                        
                        Text("#\(info.rank)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        
                        Text(String(format: "%.1f", info.score))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Rank")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sentimentIcon(for sentiment: SongSentiment) -> Image {
        switch sentiment {
        case .love:
            return Image(systemName: "heart.fill")
        case .fine:
            return Image(systemName: "hand.thumbsup.fill")
        case .dislike:
            return Image(systemName: "hand.thumbsdown.fill")
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                Text(message)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 5)
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

// MARK: - Song Header View

struct SongHeaderView: View {
    let song: MusicKit.Song
    
    var body: some View {
        VStack(spacing: 16) {
            if let artwork = song.artwork {
                AsyncImage(url: artwork.url(width: 200, height: 200)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                        .overlay(
                            Text(song.title.prefix(1).uppercased())
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                .shadow(radius: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .overlay(
                        Text(song.title.prefix(1).uppercased())
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            
            Text(song.title)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(song.artistName)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if song.albumTitle != nil && song.albumTitle != song.title {
                Text(song.albumTitle ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Song Ranking Sheet

struct SongRankingSheet: View {
    let song: MusicKit.Song
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    
    @State private var isAlreadyRanked = false
    @State private var currentRank = 0
    @State private var currentScore = 0.0
    @State private var currentSentiment: SongSentiment = .fine
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Song details with artwork
                SongHeaderView(song: song)
                
                // Current ranking details if ranked
                if isAlreadyRanked {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Currently Ranked:")
                                .font(.headline)
                            Spacer()
                            Text("#\(currentRank)")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                        
                        HStack {
                            Text("Sentiment:")
                                .font(.subheadline)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: currentSentiment.icon)
                                    .foregroundColor(currentSentiment.color)
                                Text(currentSentiment.rawValue)
                            }
                        }
                        
                        HStack {
                            Text("Score:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(currentScore, specifier: "%.1f")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Button(action: {
                            showConfirmation = true
                        }) {
                            Text("Re-rank Song")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                } else {
                    // Add song to rankings
                    VStack(alignment: .center, spacing: 20) {
                        Text("Add this song to your rankings?")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            rankSong()
                        }) {
                            Text("Rank This Song")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Song Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .alert("Re-rank Song", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Re-rank") {
                    rankSong()
                }
            } message: {
                Text("Do you want to re-rank this song? This will start the ranking process again.")
            }
            .onAppear {
                checkIfSongIsRanked()
            }
        }
    }
    
    // Helper function to check if song is already ranked
    private func checkIfSongIsRanked() {
        let rankedSong = rankingManager.rankedSongs.first { rankedSong in
            rankedSong.title.lowercased() == song.title.lowercased() &&
            rankedSong.artist.lowercased() == song.artistName.lowercased()
        }
        
        if let rankedSong = rankedSong,
           let index = rankingManager.rankedSongs.firstIndex(of: rankedSong) {
            isAlreadyRanked = true
            currentRank = index + 1
            currentScore = rankedSong.score
            currentSentiment = rankedSong.sentiment
        } else {
            isAlreadyRanked = false
        }
    }
    
    // Add the song to rankings
    private func rankSong() {
        let newSong = Song(
            title: song.title,
            artist: song.artistName,
            albumArt: song.albumTitle ?? "",
            sentiment: .fine,
            artworkURL: song.artwork?.url(width: 300, height: 300)
        )
        
        rankingManager.addNewSong(song: newSong)
        dismiss()
        onDismiss()
    }
}

// MARK: - String as Identifiable for Alert

extension String: Identifiable {
    public var id: String { self }
}
