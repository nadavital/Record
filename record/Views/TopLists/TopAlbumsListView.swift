//
//  TopAlbumsListView.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct TopAlbumsListView: View {
    let albums: [(album: String, artist: String, count: Int)]
    
    var body: some View {
        List {
            ForEach(Array(albums.enumerated()), id: \.element.album) { index, item in
                HStack(spacing: 12) {
                    Text("#\(index + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.album)
                            .font(.body)
                        Text(item.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(item.count) plays")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Top Albums")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let albums = [("Sweetener", "Ariana Grande", 999), ("1432", "Katy Perry",143)]
    TopAlbumsListView(albums: albums)
}
