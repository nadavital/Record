//
//  AlbumSection.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI

struct AlbumSection: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isEditingAlbums: Bool
    @Binding var showAlbumPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite Albums")
                .font(.headline)
                .padding(.horizontal, 4)
            
            // Albums scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Album items
                    ForEach(profileManager.pinnedAlbums) { album in
                        AlbumView(album: album, isEditingAlbums: $isEditingAlbums)
                    }
                    
                    // Add button
                    if isEditingAlbums || profileManager.pinnedAlbums.isEmpty {
                        AddAlbumButton(showAlbumPicker: $showAlbumPicker)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview() {
    @Previewable @State var isEditingAlbums = false
    @Previewable @State var showAlbumPicker = false
    AlbumSection(isEditingAlbums: $isEditingAlbums, showAlbumPicker: $showAlbumPicker)
        .environmentObject(UserProfileManager())
}
