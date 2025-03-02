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
    
    // Track focus state to enhance visual feedback
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.secondaryLabel))
                .font(.system(size: 16))
                .padding(.leading, 8)
            
            TextField(placeholder, text: $searchText)
                .font(.system(size: 16))
                .padding(.vertical, 7)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .onChange(of: searchText) {
                    // Trigger search on each keystroke
                    onTextChange()
                }
                .onSubmit {
                    // Also trigger search on submit (pressing return/enter)
                    onTextChange()
                    isSearchFieldFocused = false
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onClearText()
                    // Re-focus the search field after clearing
                    isSearchFieldFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.tertiaryLabel))
                        .font(.system(size: 16))
                }
                .padding(.trailing, 8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSearchFieldFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
    }
}

#Preview {
    @Previewable @State var searchText = ""
    
    return SearchBarView(
        searchText: $searchText,
        placeholder: "Search...",
        onTextChange: {},
        onClearText: {}
    )
}
