//
//  AddSongView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct AddSongView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var rankingManager: MusicRankingManager
    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    
    var body: some View {
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
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search for a song...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .onChange(of: searchText) { _ in
                            searchSongs()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
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
                .padding()
                
                // Results
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(searchResults) { song in
                            Button(action: {
                                rankingManager.addNewSong(song: song)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    // Album art placeholder
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Text(song.albumArt.prefix(1))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text(song.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(song.artist)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(Color(red: 0.94, green: 0.3, blue: 0.9))
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
                
                // Cancel button
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white.opacity(0.6))
                .padding()
            }
        }
        .onAppear {
            // Populate with mock search results
            searchResults = [
                Song(title: "Save Your Tears", artist: "The Weeknd", albumArt: "save_your_tears"),
                Song(title: "Physical", artist: "Dua Lipa", albumArt: "physical"),
                Song(title: "Watermelon Sugar", artist: "Harry Styles", albumArt: "watermelon_sugar"),
                Song(title: "Blinding Lights", artist: "The Weeknd", albumArt: "blinding_lights"),
                Song(title: "Driver's License", artist: "Olivia Rodrigo", albumArt: "drivers_license"),
                Song(title: "Montero", artist: "Lil Nas X", albumArt: "montero")
            ]
        }
    }
    
    private func searchSongs() {
        if searchText.isEmpty {
            // Show all results when search is empty
            searchResults = [
                Song(title: "Save Your Tears", artist: "The Weeknd", albumArt: "save_your_tears"),
                Song(title: "Physical", artist: "Dua Lipa", albumArt: "physical"),
                Song(title: "Watermelon Sugar", artist: "Harry Styles", albumArt: "watermelon_sugar"),
                Song(title: "Blinding Lights", artist: "The Weeknd", albumArt: "blinding_lights"),
                Song(title: "Driver's License", artist: "Olivia Rodrigo", albumArt: "drivers_license"),
                Song(title: "Montero", artist: "Lil Nas X", albumArt: "montero")
            ]
        } else {
            // Filter results based on search text
            searchResults = [
                Song(title: "Save Your Tears", artist: "The Weeknd", albumArt: "save_your_tears"),
                Song(title: "Physical", artist: "Dua Lipa", albumArt: "physical"),
                Song(title: "Watermelon Sugar", artist: "Harry Styles", albumArt: "watermelon_sugar"),
                Song(title: "Blinding Lights", artist: "The Weeknd", albumArt: "blinding_lights"),
                Song(title: "Driver's License", artist: "Olivia Rodrigo", albumArt: "drivers_license"),
                Song(title: "Montero", artist: "Lil Nas X", albumArt: "montero")
            ].filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
