import SwiftUI

struct EmptySongsView: View {
    let searchText: String
    var onAddSong: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label(
                searchText.isEmpty ? "No Songs" : "No Results",
                systemImage: searchText.isEmpty ? "music.note.list" : "magnifyingglass"
            )
        } description: {
            Text(searchText.isEmpty ? "Add songs to see them here" : "Try a different search")
        } actions: {
            Button {
                onAddSong()
            } label: {
                Text("Add Song")
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .padding(.top, 60)
    }
}

#Preview("Not Searching") {
    EmptySongsView(searchText: "", onAddSong: {})
}

#Preview("Searching") {
    EmptySongsView(searchText: "Search", onAddSong: {})
}
