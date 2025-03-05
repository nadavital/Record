//
//  SignInView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI
import AuthenticationServices
import Firebase

struct SignInView: View {
    @StateObject private var viewModel: SignInViewModel
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showUsernamePrompt = false
    @State private var username = ""
    
    init(authManager: AuthManager, profileManager: UserProfileManager) {
        self._viewModel = StateObject(wrappedValue: SignInViewModel(authManager: authManager, profileManager: profileManager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App Icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Record")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Text("Rank, share, and explore your favorite music")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Sign in button
                    VStack(spacing: 16) {
                        SignInWithAppleButton(
                            onRequest: viewModel.configureAppleSignInRequest,
                            onCompletion: viewModel.handleAppleSignInCompletion
                        )
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
                .padding()
                
                // Username prompt overlay
                if showUsernamePrompt {
                    Color(.systemBackground)
                        .opacity(0.98)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 24) {
                                Text("Create Username")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Please create a unique username for your profile")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                TextField("Username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(.vertical)
                                
                                Button(action: viewModel.saveUsername) {
                                    Group {
                                        if authManager.isLoading {
                                            ProgressView()
                                        } else {
                                            Text("Continue")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(username.count >= 3 ? Color.accentColor : Color.gray)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(username.count < 3 || authManager.isLoading)
                            }
                                .padding(24)
                                .transition(.opacity)
                        )
                        .zIndex(1)
                }
            }
        }
        .alert(isPresented: $authManager.showError) {
            Alert(
                title: Text("Error"),
                message: Text(authManager.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            print("SignInView appeared - checking username status")
            // Force username prompt to show if authenticated but no username
            if authManager.isAuthenticated {
                if authManager.username == nil || authManager.username!.isEmpty {
                    print("User is authenticated but has no username - showing prompt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showUsernamePrompt = true
                    }
                } else {
                    print("User already has username: \(authManager.username!)")
                }
            } else {
                print("User is not authenticated")
            }
        }
    }
}

#Preview {
    let profileManager = UserProfileManager()
    SignInView(authManager: AuthManager.shared, profileManager: profileManager)
    .environmentObject(AuthManager.shared)
    .environmentObject(profileManager)
}
