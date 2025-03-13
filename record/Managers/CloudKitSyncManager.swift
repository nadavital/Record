import Foundation
import CloudKit
import Combine

class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()
    
    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    
    // Record types
    private enum RecordType {
        static let rankedSongs = "RankedSongs"
        static let pinnedAlbums = "PinnedAlbums"
        static let pinnedArtists = "PinnedArtists"
        static let albumRatings = "AlbumRatings"
        static let profile = "UserProfile"
    }
    
    // Fields for records
    private enum Field {
        static let userId = "userId"
        static let data = "data"
        static let lastModified = "lastModified"
        static let recordName = "recordName"
    }
    
    // Publishers
    private let dataChangeSubject = PassthroughSubject<Void, Never>()
    var dataChangePublisher: AnyPublisher<Void, Never> {
        dataChangeSubject.eraseToAnyPublisher()
    }
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    // Sync status tracking
    private var syncInProgress = false
    private var queuedSyncRequest = false
    
    private init() {
        self.privateDatabase = container.privateCloudDatabase
        
        // Subscribe to remote notifications
        setupCloudKitSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Synchronize all data for the current user with CloudKit
    func syncAllData(forUserId userId: String, completion: ((Error?) -> Void)? = nil) {
        guard !syncInProgress else {
            // If a sync is already in progress, queue it for later
            queuedSyncRequest = true
            completion?(nil)
            return
        }
        
        syncInProgress = true
        isSyncing = true
        syncError = nil
        
        DispatchQueue.main.async {
            self.syncUserData(userId: userId) { error in
                if let error = error {
                    self.handleSyncError(error)
                    completion?(error)
                    return
                }
                
                // Update the last sync date and notify listeners
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    self.isSyncing = false
                    self.syncInProgress = false
                    
                    // Check if another sync was requested while we were syncing
                    if self.queuedSyncRequest {
                        self.queuedSyncRequest = false
                        self.syncAllData(forUserId: userId, completion: completion)
                    } else {
                        self.dataChangeSubject.send()
                        completion?(nil)
                    }
                }
            }
        }
    }
    
    /// Save ranked songs to CloudKit
    func saveRankedSongs(_ songs: [Song], userId: String, completion: ((Error?) -> Void)? = nil) {
        guard !songs.isEmpty else {
            // Skip empty data
            completion?(nil)
            return
        }
        
        saveDataAsAsset(songs, userId: userId, recordType: RecordType.rankedSongs) { error in
            completion?(error)
        }
    }
    
    /// Save pinned albums to CloudKit
    func savePinnedAlbums(_ albums: [Album], userId: String, completion: ((Error?) -> Void)? = nil) {
        guard !albums.isEmpty else {
            // Skip empty data
            completion?(nil)
            return
        }
        
        saveDataAsAsset(albums, userId: userId, recordType: RecordType.pinnedAlbums) { error in
            completion?(error)
        }
    }
    
    /// Save pinned artists to CloudKit
    func savePinnedArtists(_ artists: [Artist], userId: String, completion: ((Error?) -> Void)? = nil) {
        guard !artists.isEmpty else {
            // Skip empty data
            completion?(nil)
            return
        }
        
        saveDataAsAsset(artists, userId: userId, recordType: RecordType.pinnedArtists) { error in
            completion?(error)
        }
    }
    
    /// Save album ratings to CloudKit
    func saveAlbumRatings(_ ratings: [AlbumRating], userId: String, completion: ((Error?) -> Void)? = nil) {
        guard !ratings.isEmpty else {
            // Skip empty data
            completion?(nil)
            return
        }
        
        saveDataAsAsset(ratings, userId: userId, recordType: RecordType.albumRatings) { error in
            completion?(error)
        }
    }
    
    /// Save user profile to CloudKit
    func saveUserProfile(username: String, bio: String, userId: String, completion: ((Error?) -> Void)? = nil) {
        // Create a codable struct for the profile data
        struct ProfileData: Codable {
            let username: String
            let bio: String
        }
        
        let profileData = ProfileData(username: username, bio: bio)
        
        saveDataAsAsset(profileData, userId: userId, recordType: RecordType.profile) { error in
            completion?(error)
        }
    }
    
    /// Load ranked songs from CloudKit
    func loadRankedSongs(userId: String, completion: @escaping ([Song]?, Error?) -> Void) {
        loadDataFromAsset(userId: userId, recordType: RecordType.rankedSongs) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                do {
                    let songs = try JSONDecoder().decode([Song].self, from: data)
                    completion(songs, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion([], nil)
            }
        }
    }
    
    /// Load pinned albums from CloudKit
    func loadPinnedAlbums(userId: String, completion: @escaping ([Album]?, Error?) -> Void) {
        loadDataFromAsset(userId: userId, recordType: RecordType.pinnedAlbums) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                do {
                    let albums = try JSONDecoder().decode([Album].self, from: data)
                    completion(albums, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion([], nil)
            }
        }
    }
    
    /// Load pinned artists from CloudKit
    func loadPinnedArtists(userId: String, completion: @escaping ([Artist]?, Error?) -> Void) {
        loadDataFromAsset(userId: userId, recordType: RecordType.pinnedArtists) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                do {
                    let artists = try JSONDecoder().decode([Artist].self, from: data)
                    completion(artists, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion([], nil)
            }
        }
    }
    
    /// Load album ratings from CloudKit
    func loadAlbumRatings(userId: String, completion: @escaping ([AlbumRating]?, Error?) -> Void) {
        loadDataFromAsset(userId: userId, recordType: RecordType.albumRatings) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                do {
                    let ratings = try JSONDecoder().decode([AlbumRating].self, from: data)
                    completion(ratings, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion([], nil)
            }
        }
    }
    
    /// Load user profile from CloudKit
    func loadUserProfile(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        loadDataFromAsset(userId: userId, recordType: RecordType.profile) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                do {
                    // Define a struct that matches the data we stored
                    struct ProfileData: Codable {
                        let username: String
                        let bio: String
                    }
                    
                    let profileData = try JSONDecoder().decode(ProfileData.self, from: data)
                    
                    // Convert the struct to a dictionary
                    let dict: [String: Any] = [
                        "username": profileData.username,
                        "bio": profileData.bio
                    ]
                    
                    completion(dict, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion([:], nil)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func syncUserData(userId: String, completion: @escaping (Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var syncError: Error?
        
        // 1. Sync ranked songs
        dispatchGroup.enter()
        loadRankedSongs(userId: userId) { songs, error in
            if let error = error {
                syncError = error
            } else if let songs = songs, !songs.isEmpty {
                // Save the cloud data to local storage
                PersistenceManager.shared.saveRankedSongs(songs, syncToCloud: false)
            } else {
                // If no cloud data, push local data to cloud
                let localSongs = PersistenceManager.shared.loadRankedSongs()
                if !localSongs.isEmpty {
                    self.saveRankedSongs(localSongs, userId: userId)
                }
            }
            dispatchGroup.leave()
        }
        
        // 2. Sync pinned albums
        dispatchGroup.enter()
        loadPinnedAlbums(userId: userId) { albums, error in
            if let error = error {
                syncError = error
            } else if let albums = albums, !albums.isEmpty {
                PersistenceManager.shared.savePinnedAlbums(albums, syncToCloud: false)
            } else {
                let localAlbums = PersistenceManager.shared.loadPinnedAlbums()
                if !localAlbums.isEmpty {
                    self.savePinnedAlbums(localAlbums, userId: userId)
                }
            }
            dispatchGroup.leave()
        }
        
        // 3. Sync pinned artists
        dispatchGroup.enter()
        loadPinnedArtists(userId: userId) { artists, error in
            if let error = error {
                syncError = error
            } else if let artists = artists, !artists.isEmpty {
                PersistenceManager.shared.savePinnedArtists(artists, syncToCloud: false)
            } else {
                let localArtists = PersistenceManager.shared.loadPinnedArtists()
                if !localArtists.isEmpty {
                    self.savePinnedArtists(localArtists, userId: userId)
                }
            }
            dispatchGroup.leave()
        }
        
        // 4. Sync album ratings
        dispatchGroup.enter()
        loadAlbumRatings(userId: userId) { ratings, error in
            if let error = error {
                syncError = error
            } else if let ratings = ratings, !ratings.isEmpty {
                PersistenceManager.shared.saveAlbumRatings(ratings, syncToCloud: false)
            } else {
                let localRatings = PersistenceManager.shared.loadAlbumRatings()
                if !localRatings.isEmpty {
                    self.saveAlbumRatings(localRatings, userId: userId)
                }
            }
            dispatchGroup.leave()
        }
        
        // 5. Sync user profile
        dispatchGroup.enter()
        loadUserProfile(userId: userId) { profileData, error in
            if let error = error {
                syncError = error
            } else if let profileData = profileData, !profileData.isEmpty {
                if let username = profileData["username"] as? String,
                   let bio = profileData["bio"] as? String {
                    // Get the local profile
                    let localProfile = PersistenceManager.shared.loadUserProfile()
                    
                    // Only update if the local profile is empty or has default values
                    if localProfile == nil || localProfile?.username.isEmpty == true {
                        PersistenceManager.shared.saveUserProfile(
                            username: username,
                            bio: bio,
                            profileImage: localProfile?.profileImage ?? "profile_image",
                            syncToCloud: false
                        )
                    }
                }
            } else {
                // If no cloud profile, push local profile to cloud
                if let localProfile = PersistenceManager.shared.loadUserProfile() {
                    self.saveUserProfile(
                        username: localProfile.username,
                        bio: localProfile.bio,
                        userId: userId
                    )
                }
            }
            dispatchGroup.leave()
        }
        
        // When all operations are complete
        dispatchGroup.notify(queue: .main) {
            completion(syncError)
        }
    }
    
    // Save data as a CloudKit Asset
    private func saveDataAsAsset<T: Encodable>(_ data: T, userId: String, recordType: String, completion: ((Error?) -> Void)? = nil) {
        do {
            // Encode the data to JSON
            let jsonData = try JSONEncoder().encode(data)
            
            // Create a temporary file URL for the asset
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "\(UUID().uuidString).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // Write the data to the file
            try jsonData.write(to: fileURL)
            
            // Create the asset from the file
            let asset = CKAsset(fileURL: fileURL)
            
            // Create or update the record
            let recordId = generateRecordId(forUserId: userId, recordType: recordType)
            let predicate = NSPredicate(format: "userId == %@", userId)
            let query = CKQuery(recordType: recordType, predicate: predicate)
            
            // Check if a record already exists
            privateDatabase.perform(query, inZoneWith: nil) { [weak self] (records, error) in
                guard let self = self else {
                    // Clean up the temporary file
                    try? FileManager.default.removeItem(at: fileURL)
                    completion?(nil)
                    return
                }
                
                if let error = error {
                    // Clean up the temporary file
                    try? FileManager.default.removeItem(at: fileURL)
                    completion?(error)
                    return
                }
                
                if let existingRecord = records?.first {
                    // Update existing record
                    existingRecord[Field.data] = asset
                    existingRecord[Field.lastModified] = Date()
                    
                    self.privateDatabase.save(existingRecord) { (record, error) in
                        // Clean up the temporary file
                        try? FileManager.default.removeItem(at: fileURL)
                        
                        if let error = error {
                            print("Error updating \(recordType): \(error.localizedDescription)")
                            completion?(error)
                        } else {
                            print("Successfully updated \(recordType)")
                            completion?(nil)
                        }
                    }
                } else {
                    // Create new record
                    let newRecord = CKRecord(recordType: recordType, recordID: recordId)
                    newRecord[Field.userId] = userId
                    newRecord[Field.data] = asset
                    newRecord[Field.lastModified] = Date()
                    
                    self.privateDatabase.save(newRecord) { (record, error) in
                        // Clean up the temporary file
                        try? FileManager.default.removeItem(at: fileURL)
                        
                        if let error = error {
                            print("Error creating \(recordType): \(error.localizedDescription)")
                            completion?(error)
                        } else {
                            print("Successfully created \(recordType)")
                            completion?(nil)
                        }
                    }
                }
            }
        } catch {
            print("Error encoding data: \(error.localizedDescription)")
            completion?(error)
        }
    }
    
    // Load data from a CloudKit Asset
    private func loadDataFromAsset(userId: String, recordType: String, completion: @escaping (Data?, Error?) -> Void) {
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let record = records?.first, let asset = record[Field.data] as? CKAsset {
                if let fileURL = asset.fileURL {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        completion(data, nil)
                    } catch {
                        print("Error reading asset file: \(error.localizedDescription)")
                        completion(nil, error)
                    }
                } else {
                    completion(nil, nil)
                }
            } else {
                // No data found (not an error, just empty)
                completion(nil, nil)
            }
        }
    }
    
    private func generateRecordId(forUserId userId: String, recordType: String) -> CKRecord.ID {
        let recordName = "\(recordType)_\(userId)"
        return CKRecord.ID(recordName: recordName)
    }
    
    private func handleSyncError(_ error: Error) {
        DispatchQueue.main.async {
            self.syncError = error.localizedDescription
            self.isSyncing = false
            self.syncInProgress = false
        }
        print("Sync error: \(error.localizedDescription)")
    }
    
    private func setupCloudKitSubscriptions() {
        // Create a subscription for each record type to receive push notifications
        let recordTypes = [
            RecordType.rankedSongs,
            RecordType.pinnedAlbums,
            RecordType.pinnedArtists,
            RecordType.albumRatings,
            RecordType.profile
        ]
        
        for recordType in recordTypes {
            let subscription = CKQuerySubscription(
                recordType: recordType,
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            privateDatabase.save(subscription) { _, error in
                if let error = error {
                    // Handle only non-duplicate errors
                    if (error as NSError).code != CKError.Code.serverRejectedRequest.rawValue {
                        print("Error creating subscription for \(recordType): \(error.localizedDescription)")
                    }
                } else {
                    print("Successfully created subscription for \(recordType)")
                }
            }
        }
    }
}
