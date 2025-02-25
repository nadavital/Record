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
    @State private var loadingFailed = false
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: max(1, size.width), height: max(1, size.height))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                // Placeholder with gradient background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(generateGradient(from: placeholderText))
                    .frame(width: max(1, size.width), height: max(1, size.height))
                    .overlay(
                        Text(placeholderText.prefix(1).uppercased())
                            .font(.system(size: max(1, size.width * 0.4), weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Group {
                            if isLoading && !loadingFailed {
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
    
    // Generate a consistent gradient based on input text
    private func generateGradient(from text: String) -> LinearGradient {
        let seed = text.isEmpty ? "A" : text
        let hash = abs(seed.hashValue)
        
        // Generate two colors based on the hash
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash / 360) % 360) / 360.0
        
        let color1 = Color(hue: hue1, saturation: 0.6, brightness: 0.7)
        let color2 = Color(hue: hue2, saturation: 0.7, brightness: 0.5)
        
        return LinearGradient(
            gradient: Gradient(colors: [color1, color2]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func loadImage() {
        guard let url = artworkURL, imageData == nil else {
            isLoading = false
            return
        }
        
        isLoading = true
        loadingFailed = false
        
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
                    self.loadingFailed = true
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
            cornerRadius: max(1, size/2),
            size: CGSize(width: max(1, size), height: max(1, size))
        )
        .clipShape(Circle())
    }
}
