//
//  AuthManager.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//  Updated with CloudKit sync integration
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import CloudKit

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
    private let container = CKContainer.default()
    private let userRecordType = "User"
    private let usernameRecordType = "Username"
    
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
                
                // Save any user data we received to CloudKit
                self.saveUserData(
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
                    
                    // Trigger a data sync from CloudKit
                    self.syncUserDataFromCloud(userId: userIdentifier)
                    
                    completion(true)
                    return
                }
                
                // Check if we already have a username in CloudKit
                self.fetchUserData(for: userIdentifier) {
                    // Trigger a data sync from CloudKit
                    self.syncUserDataFromCloud(userId: userIdentifier)
                    
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
    
    // MARK: - CloudKit Storage
    
    private func saveUserData(userId: String, email: String?, firstName: String, lastName: String, suggestedUsername: String?) {
        print("Saving user data to CloudKit for userId: \(userId)")
        
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: userRecordType, predicate: predicate)
        
        container.privateCloudDatabase.perform(query, inZoneWith: nil) { [weak self] (records, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking if user exists: \(error.localizedDescription)")
                return
            }
            
            if let existingRecord = records?.first {
                print("User record already exists, updating")
                
                if let email = email, !email.isEmpty {
                    existingRecord["email"] = email
                }
                
                existingRecord["lastSignIn"] = Date()
                
                self.container.privateCloudDatabase.save(existingRecord) { (_, error) in
                    if let error = error {
                        print("Error updating user: \(error.localizedDescription)")
                    } else {
                        print("Successfully updated existing user record")
                    }
                }
            } else {
                print("Creating new user record")
                let newRecord = CKRecord(recordType: self.userRecordType)
                newRecord["userId"] = userId
                newRecord["createdAt"] = Date()
                newRecord["lastSignIn"] = Date()
                
                if let email = email, !email.isEmpty {
                    newRecord["email"] = email
                }
                
                if !firstName.isEmpty {
                    newRecord["firstName"] = firstName
                }
                
                if !lastName.isEmpty {
                    newRecord["lastName"] = lastName
                }
                
                if let suggestedUsername = suggestedUsername, !suggestedUsername.isEmpty {
                    newRecord["suggestedUsername"] = suggestedUsername
                }
                
                self.container.privateCloudDatabase.save(newRecord) { (_, error) in
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
        
        self.isLoading = true
        
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: userRecordType, predicate: predicate)
        
        container.privateCloudDatabase.perform(query, inZoneWith: nil) { [weak self] (records, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    completion?()
                    return
                }
                
                if let record = records?.first {
                    if let username = record["username"] as? String, !username.isEmpty {
                        print("Found username in CloudKit: \(username)")
                        self.username = username
                        UserDefaults.standard.set(username, forKey: "cachedUsername_\(userId)")
                    } else {
                        print("No username found in user record")
                        self.username = nil
                        UserDefaults.standard.removeObject(forKey: "cachedUsername_\(userId)")
                    }
                    
                    if let email = record["email"] as? String {
                        self.email = email
                    }
                } else {
                    print("No user record found")
                }
                
                completion?()
            }
        }
    }
    
    // MARK: - Username Management
    
    // Add this helper function to validate username characters
    private func isValidUsername(_ username: String) -> Bool {
        // Only allow letters, numbers, underscores, and dots
        let validCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")
        let usernameCharacterSet = CharacterSet(charactersIn: username)
        return validCharacterSet.isSuperset(of: usernameCharacterSet)
    }

    func updateUsername(username: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = self.userId else {
            let error = NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])
            print("Cannot update username - no user ID")
            completion(false, error)
            return
        }
        
        // Validate username characters
        guard isValidUsername(username) else {
            let error = NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username can only contain letters, numbers, underscores, and dots"])
            print("Invalid username characters: \(username)")
            DispatchQueue.main.async {
                self.errorMessage = "Username can only contain letters, numbers, underscores, and dots"
                self.showError = true
                self.isLoading = false
            }
            completion(false, error)
            return
        }
        
        print("Updating username to: \(username) for user: \(userId)")
        isLoading = true
        
        // Store the old username to delete it later if update succeeds
        let oldUsername = self.username?.lowercased()
        
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
            
            // Update username in user record
            let predicate = NSPredicate(format: "userId == %@", userId)
            let query = CKQuery(recordType: self.userRecordType, predicate: predicate)
            
            self.container.privateCloudDatabase.perform(query, inZoneWith: nil) { [weak self] (records, error) in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        self.isLoading = false
                    }
                    completion(false, error)
                    return
                }
                
                if let record = records?.first {
                    record["username"] = username
                    
                    self.container.privateCloudDatabase.save(record) { (_, error) in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.errorMessage = error.localizedDescription
                                self.showError = true
                                self.isLoading = false
                            }
                            completion(false, error)
                            return
                        }
                        
                        // Reserve the new username
                        let usernameRecord = CKRecord(recordType: self.usernameRecordType)
                        usernameRecord["username"] = username.lowercased()
                        usernameRecord["userId"] = userId
                        
                        self.container.privateCloudDatabase.save(usernameRecord) { (_, error) in
                            // If we successfully saved the new username, delete the old one
                            if let oldUsername = oldUsername {
                                let oldUsernamePredicate = NSPredicate(format: "username == %@", oldUsername)
                                let oldUsernameQuery = CKQuery(recordType: self.usernameRecordType, predicate: oldUsernamePredicate)
                                
                                self.container.privateCloudDatabase.perform(oldUsernameQuery, inZoneWith: nil) { (records, _) in
                                    if let oldRecord = records?.first {
                                        self.container.privateCloudDatabase.delete(withRecordID: oldRecord.recordID) { _, _ in }
                                    }
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.isLoading = false
                                
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.showError = true
                                    completion(false, error)
                                    return
                                }
                                
                                self.username = username
                                UserDefaults.standard.set(username, forKey: "cachedUsername_\(userId)")
                                completion(true, nil)
                            }
                        }
                    }
                } else {
                    let error = NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User record not found"])
                    DispatchQueue.main.async {
                        self.errorMessage = "User record not found"
                        self.showError = true
                        self.isLoading = false
                    }
                    completion(false, error)
                }
            }
        }
    }

    func checkUsernameAvailability(username: String, completion: @escaping (Bool, Error?) -> Void) {
        print("Checking availability for username: \(username)")
        
        let predicate = NSPredicate(format: "username == %@", username.lowercased())
        let query = CKQuery(recordType: usernameRecordType, predicate: predicate)
        
        container.privateCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error checking username: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            let isAvailable = records?.isEmpty ?? true
            print("Username '\(username)' available: \(isAvailable)")
            
            // Username is available if document doesn't exist
            completion(isAvailable, nil)
        }
    }
    
    // MARK: - Data Sync
    
    func syncUserDataFromCloud(userId: String) {
        // Trigger a sync with CloudKit
        PersistenceManager.shared.syncWithCloudKit { error in
            if let error = error {
                print("Error syncing data from CloudKit: \(error.localizedDescription)")
            } else {
                print("Successfully synced data from CloudKit")
            }
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
        let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier")
        
        // Remove cached username if it exists
        if let userId = userIdentifier {
            UserDefaults.standard.removeObject(forKey: "cachedUsername_\(userId)")
        }
        
        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userId = nil
            self.username = nil
            self.email = nil
        }
    }
}
