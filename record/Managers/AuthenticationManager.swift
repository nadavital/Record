//
//  AuthenticationManager.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//


//
//  AuthenticationManager.swift
//  record
//
//  Created by Claude on 2/25/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import Firebase
import FirebaseFirestore
import CryptoKit

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var currentUser: User?
    @Published var error: Error?
    @Published var userProfile: UserProfile?
    
    private let db = Firestore.firestore()
    private var currentNonce: String?
    
    struct UserProfile {
        let uid: String
        let email: String?
        let displayName: String?
        let username: String
    }
    
    override init() {
        super.init()
        
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            self.fetchUserProfile()
        }
    }
    
    func fetchUserProfile() {
        guard let user = currentUser else { return }
        
        db.collection("users").document(user.uid).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user profile: \(error)")
                return
            }
            
            if let document = document, document.exists, 
               let data = document.data(),
               let username = data["username"] as? String {
                self?.userProfile = UserProfile(
                    uid: user.uid,
                    email: user.email,
                    displayName: user.displayName,
                    username: username
                )
            }
        }
    }
    
    // Check if a username is available
    func checkUsernameAvailability(username: String, completion: @escaping (Bool, Error?) -> Void) {
        db.collection("usernames")
            .document(username.lowercased())
            .getDocument { document, error in
                if let error = error {
                    completion(false, error)
                    return
                }
                
                completion(!document!.exists, nil)
            }
    }
    
    // Reserve a username
    func reserveUsername(username: String, for uid: String, completion: @escaping (Bool, Error?) -> Void) {
        let batch = db.batch()
        
        // Add to usernames collection to ensure uniqueness
        let usernameDoc = db.collection("usernames").document(username.lowercased())
        batch.setData(["uid": uid], forDocument: usernameDoc)
        
        // Update the user's profile
        let userDoc = db.collection("users").document(uid)
        batch.setData(["username": username], forDocument: userDoc, merge: true)
        
        batch.commit { error in
            if let error = error {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
}

// MARK: - Security methods for Sign in with Apple
    
// Adapted from Apple's example
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

// Hashing function using SHA256
private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    let hashString = hashed.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

// MARK: - Sign in with Apple
extension AuthenticationManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func signInWithApple() {
        isAuthenticating = true
        
        // Generate a random nonce for security
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce) // Hash the nonce for security
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Unable to obtain Apple ID credential")
            isAuthenticating = false
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            isAuthenticating = false
            return
        }
        
        // Retrieve the secure nonce we stored earlier
        guard let nonce = currentNonce else {
            print("Invalid state: A login callback was received, but no login request was sent.")
            isAuthenticating = false
            return
        }
        
        // Create Firebase credential with the token and nonce
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            self.isAuthenticating = false
            
            if let error = error {
                self.error = error
                print("Firebase sign-in error: \(error.localizedDescription)")
                return
            }
            
            guard let user = authResult?.user else {
                print("Firebase user is nil")
                return
            }
            
            self.currentUser = user
            self.isAuthenticated = true
            
            // Check if this is the first time the user signed in
            self.checkIfUserExists(user) { exists in
                if !exists {
                    // Create a new user profile if this is their first time
                    self.createUserProfile(user, appleIDCredential: appleIDCredential)
                } else {
                    // Fetch existing profile
                    self.fetchUserProfile()
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple failed: \(error.localizedDescription)")
        self.error = error
        self.isAuthenticating = false
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the connected scenes
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window ?? UIWindow()
    }
    
    private func checkIfUserExists(_ user: User, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(user.uid).getDocument { document, error in
            if let error = error {
                print("Error checking if user exists: \(error)")
                completion(false)
                return
            }
            
            let exists = document != nil && document!.exists
            completion(exists)
        }
    }
    
    private func createUserProfile(_ user: User, appleIDCredential: ASAuthorizationAppleIDCredential) {
        // Get the user's full name if available
        let fullName = [
            appleIDCredential.fullName?.givenName,
            appleIDCredential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")
        
        // Extract the email domain to suggest a username
        let email = appleIDCredential.email ?? user.email
        let suggestedUsername = generateSuggestedUsername(from: email, fallback: fullName)
        
        // Create a temporary profile with a generated username
        let tempProfile = UserProfile(
            uid: user.uid,
            email: email,
            displayName: fullName.isEmpty ? nil : fullName,
            username: suggestedUsername
        )
        
        // Store basic info while the user completes their profile
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": email ?? "",
            "displayName": fullName,
            "createdAt": FieldValue.serverTimestamp(),
            "tempUsername": suggestedUsername,
            "needsUsernameSetup": true
        ]
        
        db.collection("users").document(user.uid).setData(userData) { [weak self] error in
            if let error = error {
                print("Error creating user document: \(error)")
                return
            }
            
            self?.userProfile = tempProfile
        }
    }
    
    private func generateSuggestedUsername(from email: String?, fallback: String) -> String {
        if let email = email, let username = email.components(separatedBy: "@").first {
            // Clean up the username
            let cleaned = username.filter { char in
                char.isLetter || char.isNumber || char == "." || char == "_"
            }
            if !cleaned.isEmpty {
                return cleaned
            }
        }
        
        // Use fallback and add random number
        if !fallback.isEmpty {
            let cleaned = fallback.lowercased().filter { $0.isLetter || $0.isNumber }
            if !cleaned.isEmpty {
                return cleaned + String(Int.random(in: 100...999))
            }
        }
        
        // Last resort
        return "user\(Int.random(in: 10000...99999))"
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false
        } catch {
            print("Error signing out: \(error)")
            self.error = error
        }
    }
}