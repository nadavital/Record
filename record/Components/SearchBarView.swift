//
//  SearchBarView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    var placeholder: String
    var onTextChange: () -> Void
    var onClearText: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.secondaryLabel))
                .font(.system(size: 16))
                .padding(.leading, 8)
            
            TextField(placeholder, text: $searchText)
                .font(.system(size: 16))
                .padding(.vertical, 7)
                .onChange(of: searchText) { _ in
                    onTextChange()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onClearText()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.tertiaryLabel))
                        .font(.system(size: 16))
                }
                .padding(.trailing, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

#Preview {
    @State var searchText = ""
    
    return SearchBarView(
        searchText: $searchText,
        placeholder: "Search...",
        onTextChange: {},
        onClearText: {}
    )
}