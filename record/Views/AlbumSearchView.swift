//
//  AlbumSearchView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI
import MusicKit

struct AlbumSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profileManager: UserProfileManager
    @StateObject private var musicAPI = MusicAPIManager()
    @State private var searchText = ""
    @State private var searchDebounce: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Simple background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Auth status banner using component
                    if musicAPI.authorizationStatus != .authorized {
                        MusicAuthBannerView(
                            authorizationStatus: musicAPI.authorizationStatus,
                            requestAuthAction: {
                                Task {
                                    await musicAPI.checkMusicAuthorizationStatus()
                                }
                            }
                        )
                    }
                    
                    // Search interface - simplified
                    VStack(spacing: 12) {
                        // Search bar with updated component styling
                        SearchBarView(
                            searchText: $searchText,
                            placeholder: "Search for an album...",
                            onTextChange: {
                                // Debounce search to avoid too many API calls
                                searchDebounce?.cancel()
                                searchDebounce = Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                                    if !Task.isCancelled {
                                        await musicAPI.searchAlbums(query: searchText)
                                    }
                                }
                            },
                            onClearText: {
                                searchDebounce?.cancel()
                                musicAPI.searchResults = []
                            }
                        )
                        .padding(.vertical, 4)
                        
                        // Results with simplified styling
                        ZStack {
                            if musicAPI.isSearching {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if let errorMessage = musicAPI.errorMessage {
                                VStack(spacing: 15) {
                                    Text(errorMessage)
                                        .foregroundColor(Color(.secondaryLabel))
                                        .multilineTextAlignment(.center)
                                    
                                    // Retry button styled like SongComparisonView
                                    Button(action: {
                                        Task {
                                            await musicAPI.searchAlbums(query: searchText)
                                        }
                                    }) {
                                        Text("Retry")
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.accentColor)
                                            )
                                    }
                                }
                            } else if musicAPI.searchResults.isEmpty && !searchText.isEmpty {
                                Text("No results found")
                                    .foregroundColor(Color(.secondaryLabel))
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(musicAPI.searchResults) { item in
                                            MusicItemTileView(
                                                title: item.title,
                                                artist: item.artist,
                                                albumName: nil,
                                                artworkID: item.artworkID,
                                                onSelect: {
                                                    let album = musicAPI.convertToAlbum(item)
                                                    profileManager.pinnedAlbums.append(album)
                                                    presentationMode.wrappedValue.dismiss()
                                                },
                                                musicAPI: musicAPI
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("Add Album")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }
            }
        }
        .task {
            // Check authorization status when view appears
            await musicAPI.checkMusicAuthorizationStatus()
        }
    }
}

#Preview("Album Search View") {
    let profileManager = UserProfileManager()
    
    return NavigationStack {
        AlbumSearchView()
            .environmentObject(profileManager)
    }
}
