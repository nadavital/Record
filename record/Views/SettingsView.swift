//
//  SettingsView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showSignOutConfirmation = false
    @State private var showUsernamePrompt = false
    @State private var editingUsername = false
    @State private var newUsername = ""
    
    // Theme color options matching the app's design
    private let colorOptions = [
        Color(red: 0.94, green: 0.3, blue: 0.9),   // Pink
        Color(red: 0.3, green: 0.85, blue: 0.9),   // Cyan
        Color(red: 0.9, green: 0.4, blue: 0.4),    // Coral
        Color(red: 0.5, green: 0.9, blue: 0.3),    // Lime
        Color(red: 0.9, green: 0.7, blue: 0.2)     // Gold
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section(header: Text("Profile")) {
                    // Username
                    if editingUsername {
                        TextField("Username", text: $newUsername)
                            .onAppear {
                                newUsername = profileManager.username
                            }
                            .onSubmit {
                                if !newUsername.isEmpty {
                                    profileManager.username = newUsername
                                    if let currentUsername = authManager.username, currentUsername != newUsername {
                                        authManager.updateUsername(username: newUsername) { _, _ in }
                                    }
                                    editingUsername = false
                                }
                            }
                    } else {
                        HStack {
                            Label("Username", systemImage: "person")
                            Spacer()
                            Text(profileManager.username)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingUsername = true
                        }
                    }
                    
                    if let email = authManager.email {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Appearance section
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Theme Color")
                        Spacer()
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: profileManager.accentColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    profileManager.accentColor = color
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Account section
                Section(header: Text("Account")) {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                // App info section
                Section(header: Text("About")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .tint(profileManager.accentColor)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserProfileManager())
        .environmentObject(AuthManager.shared)
}