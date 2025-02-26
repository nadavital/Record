//
//  AuthManager.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import Firebase
import FirebaseFirestore

class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var username: String?
    @Published var email: String?
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isLoading = false
    
    // Used to store state for Apple Sign In
    private var currentNonce: String?
    
    static let shared = AuthManager()
    
    private override init() {
        super.init()
        
        print("AuthManager initialized")
        // Check if user is already signed in (from keychain)
        checkExistingSignIn()
    }
    
    // Check if user is already authenticated via keychain
    private func checkExistingSignIn() {
        print("Checking for existing sign in")
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            print("Found saved user identifier: \(userIdentifier)")
            
            // Check if we have a cached username for this user
            if let cachedUsername = UserDefaults.standard.string(forKey: "cachedUsername_\(userIdentifier)") {
                print("Found cached username: \(cachedUsername)")
                DispatchQueue.main.async {
                    self.username = cachedUsername
                }
            }
            
            appleIDProvider.getCredentialState(forUserID: userIdentifier) { [weak self] (credentialState, error) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        print("Apple credential state: authorized")
                        // User is authenticated
                        self.isAuthenticated = true
                        self.userId = userIdentifier
                        self.fetchUserData(for: userIdentifier)
                    case .revoked:
                        print("Apple credential state: revoked")
                        // User not authenticated
                        self.isAuthenticated = false
                        self.clearUserData()
                    case .notFound:
                        print("Apple credential state: not found")
                        self.isAuthenticated = false
                        self.clearUserData()
                    default:
                        print("Apple credential state: unknown")
                        self.isAuthenticated = false
                        self.clearUserData()
                    }
                }
            }
        } else {
            print("No saved user identifier found")
            isAuthenticated = false
        }
    }
    
    // MARK: - Apple Sign In
    
    /// Generates a random nonce string for Apple Sign In
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
    
    /// SHA256 hash of the input string
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// Prepares a nonce for Apple Sign In request
    func prepareNonceForSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    /// Handle the Sign in with Apple credential
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential, completion: @escaping (Bool) -> Void) {
        // Get user identifier
        let userIdentifier = credential.user
        print("Handling Apple sign in for user: \(userIdentifier)")
        
        // Validate the credential
        validateAppleCredential(userIdentifier: userIdentifier) { [weak self] isValid in
            guard let self = self else { return }
            
            if !isValid {
                print("Apple credential is not valid - aborting sign in")
                completion(false)
                return
            }
            
            // Credential is valid, proceed with sign in
            // Store user identifier in UserDefaults
            UserDefaults.standard.set(userIdentifier, forKey: "appleUserIdentifier")
            
            // Update local state
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.userId = userIdentifier
                self.email = credential.email
                
                // Check if we have a name
                let firstName = credential.fullName?.givenName ?? ""
                let lastName = credential.fullName?.familyName ?? ""
                let suggestionBase = "\(firstName)\(lastName)".isEmpty ? "user" : "\(firstName)\(lastName)"
                let suggestedUsername = suggestionBase.lowercased().replacingOccurrences(of: " ", with: "")
                
                print("Using suggested username base: \(suggestedUsername)")
                
                // Save any user data we received to Firestore
                self.saveUserDataToFirestore(
                    userId: userIdentifier,
                    email: credential.email,
                    firstName: firstName,
                    lastName: lastName,
                    suggestedUsername: suggestedUsername
                )
                
                // Check if we already have a username in UserDefaults cache
                if let cachedUsername = UserDefaults.standard.string(forKey: "cachedUsername_\(userIdentifier)"),
                   !cachedUsername.isEmpty {
                    print("Found cached username: \(cachedUsername)")
                    self.username = cachedUsername
                    completion(true)
                    return
                }
                
                // Check if we already have a username in Firestore
                self.fetchUserData(for: userIdentifier) {
                    completion(true)
                }
            }
        }
    }
    
    func validateAppleCredential(userIdentifier: String, completion: @escaping (Bool) -> Void) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        appleIDProvider.getCredentialState(forUserID: userIdentifier) { credentialState, error in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid
                print("Apple credential is valid")
                completion(true)
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or not found
                print("Apple credential is not valid: \(credentialState)")
                completion(false)
            default:
                print("Unknown credential state: \(credentialState)")
                completion(false)
            }
        }
    }
    
    // MARK: - Firebase Storage
    
    private func saveUserDataToFirestore(userId: String, email: String?, firstName: String, lastName: String, suggestedUsername: String?) {
        print("Saving user data to Firestore for userId: \(userId)")
        let db = Firestore.firestore()
        
        // First check if user already exists
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard self != nil else { return }
            
            if let error = error {
                print("Error checking if user exists: \(error.localizedDescription)")
                return
            }
            
            if let document = snapshot, document.exists {
                print("User document already exists, updating")
                // User already exists, just update any new information
                var dataToUpdate: [String: Any] = [
                    "lastSignIn": FieldValue.serverTimestamp()
                ]
                
                // Only update email if it's new
                if let email = email, !email.isEmpty {
                    dataToUpdate["email"] = email
                }
                
                db.collection("users").document(userId).updateData(dataToUpdate) { error in
                    if let error = error {
                        print("Error updating user: \(error.localizedDescription)")
                    } else {
                        print("Successfully updated existing user document")
                    }
                }
            } else {
                print("Creating new user document")
                // New user, create record
                var userData: [String: Any] = [
                    "userId": userId,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastSignIn": FieldValue.serverTimestamp()
                ]
                
                if let email = email, !email.isEmpty {
                    userData["email"] = email
                }
                
                if !firstName.isEmpty {
                    userData["firstName"] = firstName
                }
                
                if !lastName.isEmpty {
                    userData["lastName"] = lastName
                }
                
                // If we have a suggested username, store it
                if let suggestedUsername = suggestedUsername, !suggestedUsername.isEmpty {
                    userData["suggestedUsername"] = suggestedUsername
                }
                
                db.collection("users").document(userId).setData(userData) { error in
                    if let error = error {
                        print("Error creating user record: \(error.localizedDescription)")
                    } else {
                        print("User record created successfully")
                    }
                }
            }
        }
    }
    
    func fetchUserData(for userId: String, completion: (() -> Void)? = nil) {
        print("Fetching user data for userId: \(userId)")
        let db = Firestore.firestore()
        
        // Mark as loading
        self.isLoading = true
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // Reset loading state
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion?()
                return
            }
            
            if let data = snapshot?.data() {
                if let username = data["username"] as? String, !username.isEmpty {
                    print("Found username in Firestore: \(username)")
                    DispatchQueue.main.async {
                        self.username = username
                        // Store in UserDefaults as a cache
                        UserDefaults.standard.set(username, forKey: "cachedUsername_\(userId)")
                    }
                } else {
                    print("No username found in user document")
                    DispatchQueue.main.async {
                        self.username = nil
                        // Clear any cached username
                        UserDefaults.standard.removeObject(forKey: "cachedUsername_\(userId)")
                    }
                }
                
                // Also update email if available
                if let email = data["email"] as? String {
                    DispatchQueue.main.async {
                        self.email = email
                    }
                }
            } else {
                print("No user document found or document is empty")
            }
            
            completion?()
        }
    }
    
    // MARK: - Username Management
    
    func updateUsername(username: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = self.userId else {
            let error = NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])
            print("Cannot update username - no user ID")
            completion(false, error)
            return
        }
        
        print("Updating username to: \(username) for user: \(userId)")
        isLoading = true
        
        // First, check if username is already taken
        checkUsernameAvailability(username: username) { [weak self] available, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Username availability check failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
                completion(false, error)
                return
            }
            
            if !available {
                print("Username is already taken: \(username)")
                let error = NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username is already taken"])
                DispatchQueue.main.async {
                    self.errorMessage = "Username is already taken"
                    self.showError = true
                    self.isLoading = false
                }
                completion(false, error)
                return
            }
            
            print("Username is available, saving...")
            // Username is available, save it
            let db = Firestore.firestore()
            
            // Save username to user record
            db.collection("users").document(userId).updateData([
                "username": username
            ]) { error in
                if let error = error {
                    print("Error saving username to user document: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        self.isLoading = false
                    }
                    completion(false, error)
                    return
                }
                
                print("Username saved to user document, now reserving in usernames collection")
                // Reserve the username
                db.collection("usernames").document(username.lowercased()).setData([
                    "userId": userId,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let error = error {
                            print("Error reserving username: \(error.localizedDescription)")
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                            completion(false, error)
                            return
                        }
                        
                        print("Username successfully reserved")
                        // Update local state and cache
                        self.username = username
                        UserDefaults.standard.set(username, forKey: "cachedUsername_\(userId)")
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    func checkUsernameAvailability(username: String, completion: @escaping (Bool, Error?) -> Void) {
        print("Checking availability for username: \(username)")
        let db = Firestore.firestore()
        
        // Check if username exists
        db.collection("usernames").document(username.lowercased()).getDocument { document, error in
            if let error = error {
                print("Error checking username: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            let isAvailable = !(document?.exists ?? false)
            print("Username '\(username)' available: \(isAvailable)")
            
            // Username is available if document doesn't exist
            completion(isAvailable, nil)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        print("Signing out")
        // Clear local auth state
        clearUserData()
    }
    
    private func clearUserData() {
        print("Clearing user data")
        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userId = nil
            self.username = nil
            self.email = nil
        }
    }
}
