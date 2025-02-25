//
//  ProfileAlbumSection.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ProfileAlbumSection: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isEditing: Bool
    @Binding var showAlbumPicker: Bool
    
    var body: some View {
        sectionContent
    }
    
    // Breaking up the view into smaller parts to help the compiler
    private var sectionContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader
            albumScrollView
        }
    }
    
    private var sectionHeader: some View {
        Text("Favorite Albums")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
    }
    
    private var albumScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Album items
                ForEach(profileManager.pinnedAlbums) { album in
                    ProfileAlbumItemView(album: album, isEditing: isEditing)
                }
                
                // Add button (if editing)
                if isEditing {
                    AddAlbumButtonView(action: {
                        showAlbumPicker = true
                    })
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
