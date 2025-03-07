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
                
                NavigationLink(destination: AllAlbumRatingsView()) {
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

struct AllAlbumRatingsView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @State private var sortOption: SortOption = .rating
    
    enum SortOption {
        case rating
        case recent
        case title
    }
    
    var sortedRatings: [AlbumRating] {
        switch sortOption {
        case .rating:
            return profileManager.albumRatings
                .filter { $0.rating > 0 }
                .sorted(by: { $0.rating > $1.rating })
        case .recent:
            return profileManager.albumRatings
                .sorted(by: { $0.dateAdded > $1.dateAdded })
        case .title:
            return profileManager.albumRatings
                .sorted(by: { $0.title < $1.title })
        }
    }
    
    var body: some View {
        List {
            // Sort options
            Picker("Sort by", selection: $sortOption) {
                Text("Highest Rated").tag(SortOption.rating)
                Text("Most Recent").tag(SortOption.recent)
                Text("Title").tag(SortOption.title)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 8)
            
            ForEach(sortedRatings) { rating in
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
                            size: CGSize(width: 50, height: 50)
                        )
                        
                        // Album info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rating.title)
                                .font(.body)
                            
                            Text(rating.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Star rating
                        VStack(alignment: .trailing) {
                            StarRatingView(
                                rating: rating.rating,
                                size: 14,
                                spacing: 2
                            )
                            
                            Text(String(format: "%.1f", rating.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Album Ratings")
        .listStyle(InsetGroupedListStyle())
    }
}

#Preview {
    ProfileAlbumRatingsSection()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicAPIManager())
}
