//
//  FirebaseConfig.swift
//  record
//
//  Created by Claude on 2/25/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// Add this file to provide a centralized configuration for Firebase
// This is a helper class that provides additional Firebase functionality
// specific to your app's needs

class FirebaseConfig {
    
    static let shared = FirebaseConfig()
    
    private let db = Firestore.firestore()
    
    private init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - User Profile Management
    
    func createInitialUserProfile(for user: User, username: String, completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "username": username,
            "createdAt": FieldValue.serverTimestamp(),
            "profileCompleted": true,
            "needsUsernameSetup": false
        ]
        
        // Create user document
        db.collection("users").document(user.uid).setData(userData) { error in
            completion(error)
        }
    }
    
    // MARK: - Username Management
    
    func isUsernameAvailable(_ username: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isValidUsername(username) else {
            completion(false, NSError(domain: "InvalidUsername", code: -1, userInfo: nil))
            return
        }
        
        db.collection("usernames")
            .document(username.lowercased())
            .getDocument { document, error in
                if let error = error {
                    completion(false, error)
                    return
                }
                
                // Username is available if document doesn't exist
                completion(document == nil || !document!.exists, nil)
            }
    }
    
    func reserveUsername(_ username: String, for user: User, completion: @escaping (Bool, Error?) -> Void) {
        // First check if username is available
        isUsernameAvailable(username) { isAvailable, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if !isAvailable {
                completion(false, NSError(domain: "UsernameUnavailable", code: -1, userInfo: nil))
                return
            }
            
            // Use a batch to ensure atomic operations
            let batch = self.db.batch()
            
            // Set username document (for uniqueness)
            let usernameDoc = self.db.collection("usernames").document(username.lowercased())
            batch.setData(["uid": user.uid], forDocument: usernameDoc)
            
            // Update user profile with username
            let userDoc = self.db.collection("users").document(user.uid)
            batch.updateData(["username": username, "needsUsernameSetup": false], forDocument: userDoc)
            
            // Commit the batch
            batch.commit { error in
                completion(error == nil, error)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func isValidUsername(_ username: String) -> Bool {
        // 3-20 characters, letters, numbers, underscores, and periods only
        let regex = "^[a-zA-Z0-9_.]{3,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: username)
    }
    
    // MARK: - Data Synchronization
    
    func syncUserProfileToCache(for uid: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil, NSError(domain: "DocumentNotFound", code: -1, userInfo: nil))
                return
            }
            
            completion(data, nil)
        }
    }
}
