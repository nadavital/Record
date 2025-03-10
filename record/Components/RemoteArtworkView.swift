import SwiftUI

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

struct RemoteArtworkView: View {
    let artworkURL: URL?
    let placeholderText: String
    var cornerRadius: CGFloat = 8
    var size: CGSize = CGSize(width: 50, height: 50)
    
    @State private var imageData: Data? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: max(1, size.width), height: max(1, size.height))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(generateGradient(from: placeholderText))
                        .frame(width: max(1, size.width), height: max(1, size.height))
                    
                    Text(placeholderText.prefix(1).uppercased())
                        .font(.system(size: max(1, size.width * 0.4), weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 2)
        .onChange(of: artworkURL) {
            print("Artwork URL changed to: \(artworkURL?.absoluteString ?? "nil")")
            imageData = nil // Reset to placeholder immediately
            if let url = artworkURL {
                Task {
                    await loadImage(from: url)
                }
            }
        }
        .task(id: artworkURL) {
            // Initial load on view appearance
            if let url = artworkURL {
                await loadImage(from: url)
            }
        }
    }
    
    // Generate a consistent gradient based on input text - optimized for light/dark mode
    private func generateGradient(from text: String) -> LinearGradient {
        let seed = text.isEmpty ? "A" : text
        let hash = abs(seed.hashValue)
        
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash / 360) % 360) / 360.0
        
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
    private func loadImage(from url: URL) async {
        print("Attempting to load image from: \(url)")
        
        // Check the cache first
        if let cachedData = await ImageCache.shared.getImage(for: url) {
            print("Found cached image for: \(url)")
            await MainActor.run {
                self.imageData = cachedData
            }
            return
        }
        
        // Load from network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("Successfully fetched image from: \(url)")
            await ImageCache.shared.setImage(data, for: url)
            await MainActor.run {
                self.imageData = data
            }
        } catch {
            print("Error loading image from \(url): \(error)")
            // Leave imageData as nil to keep placeholder on failure
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RemoteArtworkView(
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            placeholderText: "Album"
        )
        
        RemoteArtworkView(
            artworkURL: nil,
            placeholderText: "Artist",
            size: CGSize(width: 100, height: 100)
        )
    }
    .padding()
}
