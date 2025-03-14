import SwiftUI

struct RankedAlbumsView: View {
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @State private var searchText = ""
    @State private var sortOption: SortOption = .rating
    
    enum SortOption {
        case rating, recent, title
    }
    
    var filteredAlbums: [AlbumRating] {
        let sorted = switch sortOption {
        case .rating:
            albumRatingManager.albumRatings
                .filter { $0.rating > 0 }
                .sorted(by: { $0.rating > $1.rating })
        case .recent:
            albumRatingManager.albumRatings
                .sorted(by: { $0.dateAdded > $1.dateAdded })
        case .title:
            albumRatingManager.albumRatings
                .sorted(by: { $0.title < $1.title })
        }
        
        if searchText.isEmpty {
            return sorted
        }
        
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                TextField("Search albums or artists", text: $searchText)
                    .padding(.vertical, 8)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Sort options
            Picker("Sort by", selection: $sortOption) {
                Text("Highest Rated").tag(SortOption.rating)
                Text("Most Recent").tag(SortOption.recent)
                Text("Title").tag(SortOption.title)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if albumRatingManager.albumRatings.isEmpty {
                CustomEmptyStateView {
                    Text("No album ratings yet")
                    Text("Rate some albums to see them here")
                }
            } else {
                List {
                    ForEach(filteredAlbums) { rating in
                        NavigationLink(destination: AlbumInfoView(
                            album: Album(
                                id: UUID(uuidString: rating.albumId) ?? UUID(),
                                title: rating.title,
                                artist: rating.artist,
                                albumArt: rating.title,
                                artworkURL: rating.artworkURL
                            ),
                            musicAPI: musicAPI
                        )) {
                            HStack(spacing: 12) {
                                // Album artwork
                                RemoteArtworkView(
                                    artworkURL: rating.artworkURL,
                                    placeholderText: rating.title,
                                    cornerRadius: 6,
                                    size: CGSize(width: 50, height: 50)
                                )
                                .shadow(radius: 2)
                                
                                // Album info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rating.title)
                                        .font(.body)
                                        .lineLimit(1)
                                    
                                    Text(rating.artist)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                // Rating
                                HStack(spacing: 4) {
                                    StarRatingView(
                                        rating: rating.rating,
                                        size: 14,
                                        spacing: 2
                                    )
                                    Text(String(format: "%.1f", rating.rating))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct CustomEmptyStateView<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                content()
            }
            .font(.headline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}