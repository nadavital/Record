//
//  TopArtistsListView.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct TopArtistsListView: View {
    let artists: [(artist: String, count: Int)]
    
    var body: some View {
        List {
            ForEach(Array(artists.enumerated()), id: \.element.artist) { index, item in
                HStack(spacing: 12) {
                    Text("#\(index + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                        .font(.subheadline)
                    Text(item.artist)
                        .font(.body)
                    Spacer()
                    Text("\(item.count) plays")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // Padding at the bottom for now playing bar
            Color.clear
                .frame(height: 80)
                .listRowInsets(EdgeInsets())
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Top Artists")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let artists = [("Ariana Grande", 700), ("Katy Perry", 143)]
    TopArtistsListView(artists: artists)
}
