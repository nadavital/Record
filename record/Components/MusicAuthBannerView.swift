//
//  MusicAuthBannerView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI
import MusicKit

struct MusicAuthBannerView: View {
    var authorizationStatus: MusicAuthorization.Status
    var requestAuthAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Apple Music Access Required")
                .font(.headline)
            
            Text("Allow Record access to Apple Music to search for songs, albums, and artists.")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            
            Button(action: {
                requestAuthAction()
            }) {
                Text("Request Access")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                    )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

#Preview {
    MusicAuthBannerView(
        authorizationStatus: .notDetermined,
        requestAuthAction: {}
    )
}
