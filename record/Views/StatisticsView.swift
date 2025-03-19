import SwiftUI
import MediaPlayer

struct StatisticsView: View {
    @EnvironmentObject private var mediaPlayerManager: MediaPlayerManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    StatsTopSongsSection().padding(.horizontal)
                    StatsTopArtistsSection().padding(.horizontal)
                    StatsTopAlbumsSection().padding(.horizontal)
                    // Padding at the bottom for now playing bar
                    Color.clear
                        .frame(height: 80)
                        .listRowInsets(EdgeInsets())
                }
                .padding(.vertical, 16)
            }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("Music Insights")
                .navigationBarTitleDisplayMode(.large)
                .refreshable { await refreshData() }
        }
    }
    
    // Refresh data function
    private func refreshData() async {
        isRefreshing = true
        mediaPlayerManager.fetchTopSongs()
        mediaPlayerManager.fetchTopAlbums()
        mediaPlayerManager.fetchTopArtists()
        isRefreshing = false
    }
}

#Preview("Statistics View") {
    StatisticsView()
        .environmentObject(MediaPlayerManager())
}
