import SwiftUI

struct RateAlbumOverlayView: View {
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var rating: Double = 0.0
    @State private var review: String = ""
    @State private var isSubmitting = false
    @FocusState private var isReviewFocused: Bool
    
    // Check if this album is already rated - by title and artist
    private var existingRating: AlbumRating? {
        guard let album = albumRatingManager.currentAlbum else { return nil }
        
        // First try looking up by ID
        if let rating = albumRatingManager.getRating(forAlbumId: album.id.uuidString) {
            return rating
        }
        
        // Then try matching by title and artist (needed for search results)
        return albumRatingManager.albumRatings.first { rating in
            rating.title.lowercased() == album.title.lowercased() &&
            rating.artist.lowercased() == album.artist.lowercased()
        }
    }
    
    var body: some View {
        // Cover the entire screen with a semi-transparent background
        ZStack {
            // Dimmed background
            Color(.systemBackground)
                .opacity(0.95)
                .ignoresSafeArea()
            
            // Main card content
            VStack(spacing: 20) {
                // X button in top corner
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            albumRatingManager.cancelRating()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .padding(5)
                    }
                }
                .padding(.bottom, -20)
                .padding(.top, -10)
                
                // Header
                Text("Rate this album")
                    .font(.headline)
                
                // Album info with artwork
                VStack(spacing: 12) {
                    if let album = albumRatingManager.currentAlbum {
                        RemoteArtworkView(
                            artworkURL: album.artworkURL,
                            placeholderText: album.title,
                            cornerRadius: 8,
                            size: CGSize(width: 90, height: 90)
                        )
                        .shadow(radius: 3)
                        
                        Text(album.title)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.label))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        Text(album.artist)
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                
                // Star rating
                StarRatingView(
                    rating: rating,
                    onTap: { newRating in
                        withAnimation(.spring()) {
                            rating = newRating
                            // Dismiss keyboard when tapping stars
                            isReviewFocused = false
                        }
                    },
                    size: 30,
                    spacing: 8,
                    fillColor: .yellow
                )
                .padding(.vertical, 5)
                
                // Review text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $review)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isReviewFocused)
                }
                .padding(.horizontal)
                
                // Save button
                Button(action: saveRating) {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save Rating")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(rating > 0 ? Color.accentColor : Color.gray)
                )
                .padding(.horizontal)
                .disabled(rating == 0 || isSubmitting)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 15)
            .frame(maxWidth: 350)
            .padding(.horizontal, 20)
        }
        // Dismiss keyboard when tapping outside text field
        .contentShape(Rectangle())
        .onTapGesture {
            isReviewFocused = false
        }
        // Add keyboard toolbar
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isReviewFocused = false
                }
            }
        }
        .onAppear {
            // If album is already rated, load existing rating
            if let existing = existingRating {
                rating = existing.rating
                review = existing.review
            }
        }
    }
    
    private func saveRating() {
        guard rating > 0, let album = albumRatingManager.currentAlbum else { return }
        
        // Dismiss keyboard first
        isReviewFocused = false
        
        isSubmitting = true
        
        // Get existing rating if available (by title and artist too)
        let existing = existingRating
        
        // Create or update rating
        let albumRating = AlbumRating(
            id: existing?.id ?? UUID(),
            albumId: album.id.uuidString,
            title: album.title,
            artist: album.artist,
            rating: rating,
            review: review,
            dateAdded: existing?.dateAdded ?? Date(),
            artworkURL: album.artworkURL
        )
        
        // If there was an existing rating with a different ID, delete it first to prevent duplicates
        if let existing = existing, existing.albumId != album.id.uuidString {
            albumRatingManager.deleteRating(existing)
        }
        
        // Save to persistent storage
        albumRatingManager.saveRating(albumRating)
        
        // Dismiss with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            withAnimation {
                albumRatingManager.cancelRating()
            }
        }
    }
}

#Preview {
    let album = Album(
        title: "Sweetener",
        artist: "Ariana Grande",
        albumArt: "Sweetener"
    )
    
    let manager = AlbumRatingManager()
    manager.currentAlbum = album
    manager.showRatingView = true
    
    return RateAlbumOverlayView()
        .environmentObject(manager)
}
