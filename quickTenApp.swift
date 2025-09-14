import SwiftUI
import FirebaseCore

@main
struct QuickTenApp: App {
    @StateObject private var router = Router()
    @StateObject private var gameState = GameState()

    init() {
        FirebaseApp.configure()
        
        // Configure app appearance
        setupAppearance()

        // Initialize ads with tracking permission
        AdsManager.requestTrackingIfNeeded { status in
            let allowPersonalized = (status == .authorized)
            AdsManager.shared.start(allowPersonalized: allowPersonalized, useProductionIDs: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .game:
                            GameView()
                        case .score(let score):
                            ScoreView(score: score)
                        case .ranking:
                            RankingView()
                        case .tutorial:
                            TutorialView()
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .environmentObject(router)
            .environmentObject(gameState)
            .preferredColorScheme(.light)
        }
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
