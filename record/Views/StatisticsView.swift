import SwiftUI
import MusicKit

struct StatisticsView: View {
    @StateObject private var musicAPI = MusicAPIManager()
    @Environment(\.colorScheme) private var colorScheme
    
    // Filter state
    @State private var selectedTimeRange = 0
    private let timeRanges = ["Last Week", "Last Month", "All Time"]
    
    // Derived statistics
    private var recentSongs: [MusicItem] {
        musicAPI.recentSongs
    }
    
    private var topArtists: [(artist: String, count: Int)] {
        let artistCounts = Dictionary(grouping: recentSongs, by: { $0.artist })
            .map { (artist: $0.key, count: $0.value.count) }
        return artistCounts.sorted { $0.count > $1.count }.prefix(5).map { $0 }
    }
    
    private var songCount: Int {
        recentSongs.count
    }
    
    // Simple mock for genre (MusicKit might not provide this directly from recent songs)
    private var topGenres: [(genre: String, count: Int)] {
        // This is a placeholder; you'd need actual genre data from MusicKit or an external API
        let mockGenres = [
            ("Pop", Int.random(in: 5...15)),
            ("Rock", Int.random(in: 3...10)),
            ("Hip Hop", Int.random(in: 2...8)),
            ("Electronic", Int.random(in: 1...5))
        ]
        return mockGenres.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching ContentView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Time range filter
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(0..<timeRanges.count, id: \.self) { index in
                                Text(timeRanges[index]).tag(index)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground).opacity(0.2))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                        .padding(.top, 10)
                        
                        // Total songs played
                        StatCardView(
                            title: "Songs Played",
                            value: "\(songCount)",
                            icon: "music.note.list",
                            color: Color(red: 0.94, green: 0.3, blue: 0.9)
                        )
                        
                        // Top artists bar chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Artists")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if topArtists.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.gray)
                            } else {
                                BarChartView(data: topArtists.map { ($0.artist, Double($0.count)) })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground).opacity(0.1))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                        
                        // Genre distribution (mock pie chart)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Genre Distribution")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if topGenres.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.gray)
                            } else {
                                PieChartView(data: topGenres.map { ($0.genre, Double($0.count)) })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground).opacity(0.1))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Music Insights")
            .foregroundColor(.white)
        }
        .task {
            await musicAPI.checkMusicAuthorizationStatus()
            await musicAPI.fetchRecentSongs(limit: 50) // Fetch more songs for better stats
        }
    }
}

// Simple Stat Card Component
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground).opacity(0.1))
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Simple Bar Chart Component
struct BarChartView: View {
    let data: [(label: String, value: Double)]
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(data, id: \.label) { item in
                HStack {
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 80, alignment: .leading)
                    
                    Rectangle()
                        .fill(Color(red: 0.94, green: 0.3, blue: 0.9))
                        .frame(width: CGFloat(item.value / maxValue * 200), height: 20)
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    Text("\(Int(item.value))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// Simple Pie Chart Component (mock using stacked rectangles)
struct PieChartView: View {
    let data: [(label: String, value: Double)]
    
    private var total: Double {
        data.map { $0.value }.reduce(0, +)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                ForEach(data.indices, id: \.self) { index in
                    Circle()
                        .trim(from: index == 0 ? 0 : data[0..<index].map { $0.value / total }.reduce(0, +),
                              to: data[0...index].map { $0.value / total }.reduce(0, +))
                        .stroke(colorForIndex(index), lineWidth: 20)
                        .frame(width: 100, height: 100)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.indices, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(colorForIndex(index))
                            .frame(width: 10, height: 10)
                        Text("\(data[index].label): \(Int(data[index].value))")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.94, green: 0.3, blue: 0.9)
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        default: return .gray
        }
    }
}

#Preview("Statistics View") {
    StatisticsView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
}