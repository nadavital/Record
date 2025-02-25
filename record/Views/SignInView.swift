//
//  SignInView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//


//
//  SignInView.swift
//  record
//
//  Created by Claude on 2/25/25.
//

import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseFirestore

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showUsernameSetup = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo and app name
                VStack(spacing: 20) {
                    // Vinyl record logo
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 150, height: 150)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.94, green: 0.3, blue: 0.9),
                                                Color(red: 0.4, green: 0.2, blue: 0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(
                                color: Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.5),
                                radius: 15
                            )
                        
                        // Inner circle
                        Circle()
                            .fill(Color.black)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        // Vinyl grooves
                        ForEach(0..<5) { i in
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                .frame(width: CGFloat(120 - i*20), height: CGFloat(120 - i*20))
                        }
                        
                        // Musical note
                        Image(systemName: "music.note")
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 0.94, green: 0.3, blue: 0.9))
                    }
                    
                    Text("Record")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.5), radius: 10)
                    
                    Text("Your personal music ranking app")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Feature highlights
                VStack(spacing: 30) {
                    featureItem(icon: "music.note.list", title: "Rank Your Favorites", description: "Create personalized music rankings")
                    
                    featureItem(icon: "person.2.fill", title: "Find New Music", description: "Discover through friends' rankings")
                    
                    featureItem(icon: "chart.bar.fill", title: "Track Listening", description: "See how your taste evolves")
                }
                
                Spacer()
                
                // Sign in buttons
                VStack(spacing: 15) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        // Authentication will be handled by our AuthenticationManager
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .disabled(authManager.isAuthenticating)
                    .opacity(authManager.isAuthenticating ? 0.6 : 1)
                    .onTapGesture {
                        if !authManager.isAuthenticating {
                            authManager.signInWithApple()
                        }
                    }
                    
                    // Custom Apple sign-in button
                    Button {
                        if !authManager.isAuthenticating {
                            authManager.signInWithApple()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.title3)
                            
                            if authManager.isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.leading, 8)
                            } else {
                                Text("Sign in with Apple")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .background(
                                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                )
                        )
                    }
                    .disabled(authManager.isAuthenticating)
                    
                    // Auth progress indicator
                    if let error = authManager.error {
                        Text("Authentication error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                            .padding()
                    }
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Check if user needs to set up username
                checkIfUsernameSetupNeeded()
            }
        }
        .fullScreenCover(isPresented: $showUsernameSetup) {
            UsernameSetupView()
        }
    }
    
    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.5), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func checkIfUsernameSetupNeeded() {
        guard let uid = authManager.currentUser?.uid else { return }
        
        // Check if the user needs to set up a username
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error checking username setup: \(error)")
                return
            }
            
            if let data = snapshot?.data(),
               let needsSetup = data["needsUsernameSetup"] as? Bool,
               needsSetup {
                showUsernameSetup = true
            }
        }
    }
}