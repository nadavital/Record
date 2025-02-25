//
//  AddAlbumButtonView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//


//
//  AddAlbumButtonView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct AddAlbumButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 120)
    }
}