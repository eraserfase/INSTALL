import Foundation
import FirebaseStorage

/// Service for interacting with Firebase Storage
class StorageService {

    private let storage: Storage

    init() {
        self.storage = Storage.storage()
    }

    /// Upload audio file
    /// - Parameters:
    ///   - audioURL: Local file URL
    ///   - storagePath: Remote storage path
    /// - Returns: Download URL
    func uploadAudio(from audioURL: URL, to storagePath: String) async throws -> URL {
        let storageRef = storage.reference().child(storagePath)

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"

        // Upload
        _ = try await storageRef.putFileAsync(from: audioURL, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }

    /// Download audio file to temporary location
    /// - Parameter storagePath: Remote storage path
    /// - Returns: Local temporary file URL
    func downloadAudio(from storagePath: String) async throws -> URL {
        let storageRef = storage.reference().child(storagePath)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")

        _ = try await storageRef.writeAsync(toFile: tempURL)
        return tempURL
    }

    /// Delete audio file
    /// - Parameter storagePath: Remote storage path
    func deleteAudio(at storagePath: String) async throws {
        let storageRef = storage.reference().child(storagePath)
        try await storageRef.delete()
    }

    /// Get download URL for existing file
    /// - Parameter storagePath: Remote storage path
    /// - Returns: Download URL
    func getDownloadURL(for storagePath: String) async throws -> URL {
        let storageRef = storage.reference().child(storagePath)
        return try await storageRef.downloadURL()
    }
}
