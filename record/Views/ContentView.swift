//
//  ContentView.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RankingView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Rank")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Stats")
                    }
                    .tag(1)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(2)
            }
            .accentColor(Color(red: 0.94, green: 0.3, blue: 0.9))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
}
