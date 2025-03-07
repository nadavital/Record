import SwiftUI
import MusicKit

struct StatisticsView: View {
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if isRefreshing {
                                ProgressView().controlSize(.small)
                            }
                            Button {
                                Task { await refreshData() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(isRefreshing)
                        }
                    }
                }
                .refreshable { await refreshData() }
        }
    }
    
    // Refresh data function
    private func refreshData() async {
        isRefreshing = true
        await musicAPI.checkMusicAuthorizationStatus()
        await musicAPI.fetchListeningHistory()
        isRefreshing = false
    }
}

#Preview("Statistics View") {
    StatisticsView()
        .environmentObject(MusicAPIManager())
        .environmentObject(MusicRankingManager())
}
