import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var persistenceManager = PersistenceManager.shared
    @State private var showAddAlbumSheet = false
    @State private var sortOption = RankedAlbumsView.SortOption.rating
    
    var body: some View {
        NavigationStack {
            RankedAlbumsView(sortOption: $sortOption)
                .navigationTitle("Album Reviews")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Menu {
                                Picker(selection: $sortOption, label: Text("Sort by")) {
                                    ForEach([RankedAlbumsView.SortOption.rating, .recent, .title], id: \.self) { option in
                                        Label {
                                            Text(option.label)
                                        } icon: {
                                            if sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                        .tag(option)
                                    }
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                            }
                            
                            Button {
                                showAddAlbumSheet = true
                            } label: {
                                Label("Add Album", systemImage: "plus")
                            }
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
