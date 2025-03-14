import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var persistenceManager = PersistenceManager.shared
    @State private var showAddAlbumSheet = false
    
    var body: some View {
        NavigationStack {
            RankedAlbumsView()
                .navigationTitle("Album Reviews")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddAlbumSheet = true
                        } label: {
                            Label("Add Album", systemImage: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        if persistenceManager.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .sheet(isPresented: $showAddAlbumSheet) {
                    UnifiedSearchView(searchType: .album)
                }
                .refreshable {
                    if let userId = authManager.userId {
                        await withCheckedContinuation { continuation in
                            persistenceManager.syncWithCloudKit { _ in
                                continuation.resume()
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    ReviewView()
        .environmentObject(AlbumRatingManager())
        .environmentObject(MusicAPIManager())
        .environmentObject(AuthManager.shared)
}