import SwiftUI

/// Team gate: create or join team
struct TeamGateView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var teamViewModel: TeamViewModel

    @State private var showCreateTeam: Bool = false
    @State private var showJoinTeam: Bool = false

    init() {
        _teamViewModel = StateObject(wrappedValue: TeamViewModel(teamService: TeamService(firestoreService: FirestoreService())))
    }

    var body: some View {
        Group {
            if let teamId = teamViewModel.currentTeamId,
               teamViewModel.currentTeam != nil {
                // User is in a team, show main app
                HomeView()
                    .environmentObject(teamViewModel)
            } else {
                // User needs to create or join a team
                teamGateContent
            }
        }
        .task {
            // Try to load existing team
            if let teamId = teamViewModel.currentTeamId,
               let userId = authViewModel.currentUser?.uid {
                await teamViewModel.loadTeam(teamId: teamId, userId: userId)
            }
        }
    }

    var teamGateContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)

                Text("Join Your Team")
                    .font(.title.bold())

                Text("Create a new team or join an existing one")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    showCreateTeam = true
                }) {
                    Label("Create Team", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    showJoinTeam = true
                }) {
                    Label("Join Team", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Sign out button
            Button(action: {
                authViewModel.signOut()
            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamView(teamViewModel: teamViewModel)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showJoinTeam) {
            JoinTeamView(teamViewModel: teamViewModel)
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Placeholder HomeView

struct HomeView: View {
    @EnvironmentObject var teamViewModel: TeamViewModel

    var body: some View {
        TabView {
            SetsLibraryView()
                .tabItem {
                    Label("Sets", systemImage: "basketball")
                }

            DefenseLibraryView()
                .tabItem {
                    Label("Defense", systemImage: "shield")
                }

            PracticesListView()
                .tabItem {
                    Label("Practices", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// Placeholder library views
struct SetsLibraryView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Sets will appear here")
            }
            .navigationTitle("Sets")
        }
    }
}

struct DefenseLibraryView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Defense scenarios will appear here")
            }
            .navigationTitle("Defense")
        }
    }
}

struct PracticesListView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Practices will appear here")
            }
            .navigationTitle("Practices")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var teamViewModel: TeamViewModel

    var body: some View {
        NavigationView {
            List {
                if let team = teamViewModel.currentTeam {
                    Section("Team") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(team.name)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Join Code")
                            Spacer()
                            Text(team.joinCode)
                                .foregroundColor(.secondary)
                                .fontWeight(.bold)
                        }
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        // Sign out logic
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
