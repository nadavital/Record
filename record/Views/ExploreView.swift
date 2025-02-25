//
//  ExploreView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

// Explore View
struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedFilter = 0
    
    let filters = ["Discover", "Trending", "New Releases"]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.2).ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search users or music...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal)
                
                // Filter selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(0..<filters.count, id: \.self) { index in
                            Button(action: {
                                selectedFilter = index
                            }) {
                                Text(filters[index])
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == index ? .semibold : .regular)
                                    .foregroundColor(selectedFilter == index ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == index ? 
                                                  Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.3) : 
                                                  Color.clear)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedFilter == index ? 
                                                Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.5) : 
                                                Color.white.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Content
                ScrollView {
                    VStack(spacing: 25) {
                        // Featured profiles
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Featured Profiles")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(1...5, id: \.self) { _ in
                                        VStack(spacing: 8) {
                                            // Profile pic
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: Double.random(in: 0.3...0.9), 
                                                                      green: Double.random(in: 0.3...0.9), 
                                                                      blue: Double.random(in: 0.3...0.9)).opacity(0.3),
                                                                Color(red: Double.random(in: 0.3...0.9), 
                                                                      green: Double.random(in: 0.3...0.9), 
                                                                      blue: Double.random(in: 0.3...0.9)).opacity(0.1)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 80, height: 80)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.white.opacity(0.5),
                                                                        Color.white.opacity(0.2)
                                                                    ]),
                                                                    startPoint: .top,
                                                                    endPoint: .bottom
                                                                ),
                                                                lineWidth: 1.5
                                                            )
                                                    )
                                                
                                                Text(["VS", "DJ", "MK", "AZ", "RB"][Int.random(in: 0...4)])
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(["VinylSeeker", "DeeJay", "MusicKing", "AudioZen", "RecordBuff"][Int.random(in: 0...4)])
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            
                                            Text("\(Int.random(in: 10...500)) songs")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 5)
                        
                        // Trending lists
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trending Lists")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 15) {
                                ForEach(1...3, id: \.self) { _ in
                                    Button(action: {}) {
                                        HStack {
                                            // Record icon
                                            ZStack {
                                                Circle()
                                                    .fill(Color.black.opacity(0.5))
                                                    .frame(width: 50, height: 50)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                                
                                                Circle()
                                                    .fill(Color.clear)
                                                    .frame(width: 20, height: 20)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(["80s Greatest Hits", "Indie Gems", "Hip Hop Essentials", 
                                                      "Electronic Masterpieces", "Rock Anthems"][Int.random(in: 0...4)])
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                
                                                HStack {
                                                    Text(["VinylSeeker", "DeeJay", "MusicKing", "AudioZen", "RecordBuff"][Int.random(in: 0...4)])
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.7))
                                                    
                                                    Text("•")
                                                        .foregroundColor(.white.opacity(0.5))
                                                    
                                                    Text("\(Int.random(in: 5...50)) songs")
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Popularity indicator
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill")
                                                    .font(.caption)
                                                    .foregroundColor(Color(red: 0.94, green: 0.3, blue: 0.9))
                                                
                                                Text("\(Int.random(in: 30...999))")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Recently active users
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Active")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(1...4, id: \.self) { _ in
                                HStack {
                                    // Profile pic
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: Double.random(in: 0.3...0.9), 
                                                          green: Double.random(in: 0.3...0.9), 
                                                          blue: Double.random(in: 0.3...0.9)).opacity(0.3),
                                                    Color(red: Double.random(in: 0.3...0.9), 
                                                          green: Double.random(in: 0.3...0.9), 
                                                          blue: Double.random(in: 0.3...0.9)).opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Text(["VinylSeeker", "DeeJay", "MusicKing", "AudioZen", "RecordBuff"][Int.random(in: 0...4)])
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(Int.random(in: 1...60))m ago")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
