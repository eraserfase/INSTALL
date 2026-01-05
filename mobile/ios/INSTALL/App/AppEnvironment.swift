import Foundation
import Combine

/// Global app environment holding shared services
class AppEnvironment: ObservableObject {
    // Services
    let authService: AuthService
    let firestoreService: FirestoreService
    let storageService: StorageService
    let messagingService: MessagingService
    let teamService: TeamService
    let setsService: SetsService
    let defenseService: DefenseService
    let notesService: NotesService
    let filmService: FilmService
    let practicesService: PracticesService

    init() {
        // Initialize services
        self.authService = AuthService()
        self.firestoreService = FirestoreService()
        self.storageService = StorageService()
        self.messagingService = MessagingService()

        // Content services depend on Firestore
        self.teamService = TeamService(firestoreService: firestoreService)
        self.setsService = SetsService(firestoreService: firestoreService)
        self.defenseService = DefenseService(firestoreService: firestoreService)
        self.notesService = NotesService(firestoreService: firestoreService, storageService: storageService)
        self.filmService = FilmService(firestoreService: firestoreService)
        self.practicesService = PracticesService(firestoreService: firestoreService)
    }
}
