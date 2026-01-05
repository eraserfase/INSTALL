import Foundation
import FirebaseCore

/// Firebase configuration constants
enum FirebaseConfig {

    /// Firestore collection names
    enum Collections {
        static let users = "users"
        static let teams = "teams"
        static let members = "members"
        static let sets = "sets"
        static let defense = "defense"
        static let practices = "practices"
        static let notes = "notes"
        static let film = "film"
    }

    /// Storage paths
    enum Storage {
        static func notesAudioPath(teamId: String, noteId: String) -> String {
            return "teams/\(teamId)/notes/\(noteId)/audio.m4a"
        }

        static func filmAudioPath(teamId: String, filmId: String) -> String {
            return "teams/\(teamId)/film/\(filmId)/audio.m4a"
        }
    }

    /// User defaults keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userRole = "userRole"
        static let currentTeamId = "currentTeamId"
    }
}
