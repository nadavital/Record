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
    // Bio editing state
    @State private var editingBio = false
    @State private var tempBio = ""
    @State private var showSaveSuccess = false // Add feedback for successful saves

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
                Section {
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
                                    showSaveSuccess = true
                                }
                            }
                        Text("Tap return to save your new username")
                            .font(.caption)
                            .foregroundColor(.secondary)
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

                    // Bio
                    if editingBio {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Tell us about yourself!", text: $tempBio, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            HStack {
                                Text("\(tempBio.count)/150 characters")
                                    .font(.caption)
                                    .foregroundColor(tempBio.count > 150 ? .red : .secondary)
                                
                                Spacer()
                                
                                Button("Save") {
                                    if tempBio.count <= 150 {
                                        profileManager.bio = tempBio
                                        profileManager.saveUserProfile()
                                        editingBio = false
                                        showSaveSuccess = true
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(tempBio.count > 150)
                                
                                Button("Cancel") {
                                    editingBio = false
                                    tempBio = profileManager.bio
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .onAppear {
                            tempBio = profileManager.bio
                        }
                    } else {
                        HStack {
                            Label("Bio", systemImage: "text.quote")
                            Spacer()
                            Text(profileManager.bio.isEmpty ? "Add a bio to your profile" : profileManager.bio)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingBio = true
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
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Customize how others see you on Record")
                }
                
                // Appearance section
                Section {
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
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        profileManager.accentColor = color
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Pick a color that matches your style")
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
            .alert("Success!", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your changes have been saved.")
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
