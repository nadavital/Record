//
//  RemoteArtworkView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct RemoteArtworkView: View {
    let artworkURL: URL?
    let placeholderText: String
    var cornerRadius: CGFloat = 8
    var size: CGSize = CGSize(width: 50, height: 50)
    
    @State private var imageData: Data? = nil
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Text(placeholderText.prefix(1))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = artworkURL, imageData == nil else { return }
        
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                DispatchQueue.main.async {
                    self.imageData = data
                    self.isLoading = false
                }
            } catch {
                print("Error loading image: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

// Circle variant for album artwork
struct CircleRemoteArtworkView: View {
    let artworkURL: URL?
    let placeholderText: String
    var size: CGFloat = 100
    
    var body: some View {
        RemoteArtworkView(
            artworkURL: artworkURL,
            placeholderText: placeholderText,
            cornerRadius: size/2,
            size: CGSize(width: size, height: size)
        )
        .clipShape(Circle())
    }
}
