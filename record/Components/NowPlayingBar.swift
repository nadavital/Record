import SwiftUI
import MediaPlayer

struct NoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct NowPlayingBar: View {
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @EnvironmentObject private var playerManager: MusicPlayerManager
    @State private var currentlyDisplayedSong: Song? = nil
    
    var isLoading: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            } else if let currentSong = playerManager.currentSong {
                RemoteArtworkView(
                    artworkURL: currentSong.artworkURL,
                    placeholderText: currentSong.albumArt,
                    cornerRadius: 8,
                    size: CGSize(width: 40, height: 40)
                )
                .frame(width: 40, height: 40)
            } else {
                Color.clear.frame(width: 0, height: 0)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isLoading ? "Loading..." : (playerManager.currentSong?.title ?? ""))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .redacted(reason: isLoading ? .placeholder : [])
                
                Text(isLoading ? "Please wait" : (playerManager.currentSong?.artist ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .redacted(reason: isLoading ? .placeholder : [])
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                Button(action: playerManager.skipToPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .opacity(isLoading ? 0.5 : 1)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(isLoading)
                
                Button(action: playerManager.togglePlayPause) {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .opacity(isLoading ? 0.5 : 1)
                        .animation(nil, value: playerManager.isPlaying)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(isLoading)
                
                Button(action: playerManager.skipToNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .opacity(isLoading ? 0.5 : 1)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 12, y: 4)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .onChange(of: rankingManager.isRanking) {
            if !rankingManager.isRanking, currentlyDisplayedSong != nil {
                currentlyDisplayedSong = nil
            }
        }
    }
}
