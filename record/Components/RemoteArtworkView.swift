//
//  RemoteArtworkView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

// Add this at the top of the file, before RemoteArtworkView
actor ImageCache {
    static let shared = ImageCache()
    private var cache: [URL: Data] = [:]
    
    func setImage(_ data: Data, for url: URL) {
        cache[url] = data
    }
    
    func getImage(for url: URL) -> Data? {
        return cache[url]
    }
}

// Conditional view modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct RemoteArtworkView: View {
    let artworkURL: URL?
    let placeholderText: String
    var cornerRadius: CGFloat = 8
    var size: CGSize = CGSize(width: 50, height: 50)
    var glassmorphic: Bool = true
    
    @State private var imageData: Data? = nil
    @State private var isLoading = true
    @State private var loadingFailed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: max(1, size.width), height: max(1, size.height))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .if(glassmorphic) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                    }
            } else {
                // Placeholder with gradient background
                ZStack {
                    // Base shape with gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(generateGradient(from: placeholderText))
                        .frame(width: max(1, size.width), height: max(1, size.height))
                    
                    // Glassmorphic overlay for light/dark adaptive style
                    if glassmorphic {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25))
                            .frame(width: max(1, size.width), height: max(1, size.height))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .strokeBorder(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                            .blur(radius: 0.5)
                    }
                    
                    // Initial letter
                    Text(placeholderText.prefix(1).uppercased())
                        .font(.system(size: max(1, size.width * 0.4), weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Loading indicator
                    if isLoading && !loadingFailed {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 2)
        .task {
            await loadImage()
        }
    }
    
    // Generate a consistent gradient based on input text - optimized for light/dark mode
    private func generateGradient(from text: String) -> LinearGradient {
        let seed = text.isEmpty ? "A" : text
        let hash = abs(seed.hashValue)
        
        // Generate two colors based on the hash
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash / 360) % 360) / 360.0
        
        // Adjust brightness based on color scheme
        let brightness1 = colorScheme == .dark ? 0.7 : 0.85
        let brightness2 = colorScheme == .dark ? 0.5 : 0.7
        
        let color1 = Color(hue: hue1, saturation: 0.6, brightness: brightness1)
        let color2 = Color(hue: hue2, saturation: 0.7, brightness: brightness2)
        
        return LinearGradient(
            gradient: Gradient(colors: [color1, color2]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Load the image from URL or cache
    private func loadImage() async {
        guard let url = artworkURL else {
            isLoading = false
            return
        }
        
        // First check the cache
        if let cachedData = await ImageCache.shared.getImage(for: url) {
            DispatchQueue.main.async {
                self.imageData = cachedData
                self.isLoading = false
            }
            return
        }
        
        // If not in cache, load from network
        isLoading = true
        loadingFailed = false
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Store in cache
            await ImageCache.shared.setImage(data, for: url)
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

// Circle variant for album artwork
struct CircleRemoteArtworkView: View {
    let artworkURL: URL?
    let placeholderText: String
    var size: CGFloat = 100
    var glassmorphic: Bool = true
    
    var body: some View {
        RemoteArtworkView(
            artworkURL: artworkURL,
            placeholderText: placeholderText,
            cornerRadius: max(1, size/2),
            size: CGSize(width: max(1, size), height: max(1, size)),
            glassmorphic: glassmorphic
        )
        .clipShape(Circle())
    }
}