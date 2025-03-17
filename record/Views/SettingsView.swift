//
//  SettingsView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//  Updated with CloudKit sync options
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
    @State private var editingBio = false
    @State private var tempBio = ""
    @State private var showSaveSuccess = false
    @State private var showInvalidCharAlert = false
    @State private var showClearDataConfirmation = false
    @State private var showSyncingIndicator = false
    @State private var syncError: String? = nil
    
    // For sync status
    @ObservedObject private var persistenceManager = PersistenceManager.shared

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    // Username
                    if editingUsername {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Username", text: $newUsername)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onAppear {
                                    newUsername = profileManager.username
                                }
                                .onSubmit {
                                    if !newUsername.isEmpty {
                                        updateUsername()
                                    }
                                }
                                
                            Text("Tap return to save your new username")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                
                // Cloud Sync Section
                Section {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        Spacer()
                        if persistenceManager.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text(persistenceManager.lastSyncDate != nil ? "Enabled" : "Not synced")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        syncData()
                    }) {
                        HStack {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if persistenceManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                    .disabled(persistenceManager.isSyncing)
                    
                    if let lastSyncDate = persistenceManager.lastSyncDate {
                        HStack {
                            Label("Last Synced", systemImage: "clock")
                            Spacer()
                            Text(formatDate(lastSyncDate))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Cloud Sync")
                } footer: {
                    Text("Your data is synced across all your devices using iCloud")
                }
                
                // Account section
                Section(header: Text("Account")) {
                    // Clear data button
                    Button(role: .destructive) {
                        showClearDataConfirmation = true
                    } label: {
                        Label("Clear Local Data", systemImage: "trash")
                    }
                    
                    // Sign out button
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
            .alert("Clear Data", isPresented: $showClearDataConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Data", role: .destructive) {
                    PersistenceManager.shared.clearAllData()
                }
            } message: {
                Text("This will clear all your locally saved data. Your cloud data will remain intact. You can sync again to restore your data.")
            }
            .alert("Success!", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your changes have been saved.")
            }
            .alert("Error", isPresented: $authManager.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authManager.errorMessage ?? "An unknown error occurred")
            }
            .alert("Invalid Characters", isPresented: $showInvalidCharAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Username can only contain letters, numbers, underscores (_) and dots (.)")
            }
            .alert(isPresented: .constant(syncError != nil)) {
                Alert(
                    title: Text("Sync Error"),
                    message: Text(syncError ?? "Unknown sync error"),
                    dismissButton: .default(Text("OK")) {
                        syncError = nil
                    }
                )
            }
        }
    }
    
    private func updateUsername() {
        guard let currentUsername = authManager.username,
              currentUsername != newUsername else {
            editingUsername = false
            return
        }
        
        // Check for invalid characters before attempting to save
        guard isValidInput(newUsername) else {
            showInvalidCharAlert = true
            return
        }
        
        authManager.updateUsername(username: newUsername) { success, error in
            if success {
                profileManager.username = newUsername
                editingUsername = false
                showSaveSuccess = true
            } else {
                // If update fails, revert to old username
                newUsername = currentUsername
                profileManager.username = currentUsername
                editingUsername = false
            }
        }
    }

    private func isValidInput(_ input: String) -> Bool {
        let validCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")
        let inputCharacters = CharacterSet(charactersIn: input)
        return validCharacters.isSuperset(of: inputCharacters)
    }
    
    private func syncData() {
        guard authManager.userId != nil else { return }
        
        showSyncingIndicator = true
        
        persistenceManager.syncWithCloudKit { error in
            showSyncingIndicator = false
            
            if let error = error {
                syncError = error.localizedDescription
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserProfileManager())
        .environmentObject(AuthManager.shared)
}
