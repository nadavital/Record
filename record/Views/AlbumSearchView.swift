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
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Auth status banner
                    if musicAPI.authorizationStatus != .authorized {
                        VStack {
                            Text("Music API Access Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("This app requires access to the Apple Music catalog to search for albums.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                Task {
                                    await musicAPI.checkMusicAuthorizationStatus()
                                }
                            }) {
                                Text("Request Access")
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(profileManager.accentColor)
                                    )
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // Search interface
                    VStack {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("Search for an album...", text: $searchText)
                                .foregroundColor(.white)
                                .accentColor(.white)
                                .onChange(of: searchText) {
                                    // Debounce search to avoid too many API calls
                                    searchDebounce?.cancel()
                                    searchDebounce = Task {
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                                        if !Task.isCancelled {
                                            await musicAPI.searchAlbums(query: searchText)
                                        }
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchDebounce?.cancel()
                                    musicAPI.searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        // Results
                        ZStack {
                            if musicAPI.isSearching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if let errorMessage = musicAPI.errorMessage {
                                VStack(spacing: 15) {
                                    Text(errorMessage)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    // Add retry button for errors
                                    Button(action: {
                                        Task {
                                            await musicAPI.searchAlbums(query: searchText)
                                        }
                                    }) {
                                        Text("Retry Search")
                                            .foregroundColor(.black)
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(profileManager.accentColor)
                                            )
                                    }
                                }
                            } else if musicAPI.searchResults.isEmpty && !searchText.isEmpty {
                                Text("No results found")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 15) {
                                        ForEach(musicAPI.searchResults) { item in
                                            Button(action: {
                                                let album = musicAPI.convertToAlbum(item)
                                                profileManager.pinnedAlbums.append(album)
                                                presentationMode.wrappedValue.dismiss()
                                            }) {
                                                HStack {
                                                    // Album art from Apple Music
                                                    RemoteArtworkView(
                                                        artworkURL: musicAPI.getArtworkURL(for: item.artworkID),
                                                        placeholderText: item.title,
                                                        size: CGSize(width: 60, height: 60)
                                                    )
                                                    
                                                    VStack(alignment: .leading) {
                                                        Text(item.title)
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                        Text(item.artist)
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "plus.circle")
                                                        .foregroundColor(profileManager.accentColor)
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .fill(Color.white.opacity(0.05))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 15)
                                                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                                        )
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("Add Album")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black.opacity(0.7), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .accentColor(profileManager.accentColor)
        .task {
            // Check authorization status when view appears
            await musicAPI.checkMusicAuthorizationStatus()
        }
    }
}
