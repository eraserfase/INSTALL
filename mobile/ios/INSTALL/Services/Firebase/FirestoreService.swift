import Foundation
import FirebaseFirestore
import Combine

/// Service for interacting with Firestore
class FirestoreService {

    let db: Firestore

    init() {
        self.db = Firestore.firestore()
    }

    // MARK: - Generic CRUD

    /// Create a document
    func create<T: Encodable>(
        _ data: T,
        collection: String,
        documentId: String? = nil
    ) async throws -> String {
        let docRef: DocumentReference

        if let id = documentId {
            docRef = db.collection(collection).document(id)
        } else {
            docRef = db.collection(collection).document()
        }

        try docRef.setData(from: data)
        return docRef.documentID
    }

    /// Read a document
    func read<T: Decodable>(
        collection: String,
        documentId: String
    ) async throws -> T {
        let snapshot = try await db.collection(collection).document(documentId).getDocument()
        return try snapshot.data(as: T.self)
    }

    /// Update a document
    func update(
        collection: String,
        documentId: String,
        data: [String: Any]
    ) async throws {
        try await db.collection(collection).document(documentId).updateData(data)
    }

    /// Delete a document
    func delete(
        collection: String,
        documentId: String
    ) async throws {
        try await db.collection(collection).document(documentId).delete()
    }

    /// Listen to a document (real-time)
    func listen<T: Decodable>(
        collection: String,
        documentId: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> ListenerRegistration {
        return db.collection(collection).document(documentId).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                return
            }

            do {
                let data = try snapshot.data(as: T.self)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Query documents
    func query<T: Decodable>(
        collection: String,
        filters: [(field: String, value: Any)] = [],
        orderBy: String? = nil,
        descending: Bool = false,
        limit: Int? = nil
    ) async throws -> [T] {
        var query: Query = db.collection(collection)

        // Apply filters
        for filter in filters {
            query = query.whereField(filter.field, isEqualTo: filter.value)
        }

        // Apply ordering
        if let orderBy = orderBy {
            query = query.order(by: orderBy, descending: descending)
        }

        // Apply limit
        if let limit = limit {
            query = query.limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }
}
