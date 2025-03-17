//
//  AppleSignInButtonFix.swift
//  record
//

import SwiftUI
import AuthenticationServices

// This fixes the constraint issues with the Apple Sign In button
extension SignInWithAppleButton {
    func fixedSize() -> some View {
        self
            .frame(width: 280, height: 45)
            .signInWithAppleButtonStyle(.black)
            .fixedSize()
    }
}

// Use this wrapper in your sign in view
struct FixedAppleSignInButton: View {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    var body: some View {
        SignInWithAppleButton(
            onRequest: onRequest,
            onCompletion: onCompletion
        )
        .fixedSize()
        .frame(width: 280, height: 45)
    }
}
