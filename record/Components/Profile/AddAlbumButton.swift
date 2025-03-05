//
//  AddAlbumButton.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI

struct AddAlbumButton: View {
    @Binding var showAlbumPicker: Bool
    var body: some View {
        Button {
            showAlbumPicker = true
        } label: {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                
                Text("Add Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var showAlbumPicker = false
    AddAlbumButton(showAlbumPicker: $showAlbumPicker)
}
