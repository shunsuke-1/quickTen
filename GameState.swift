import SwiftUI
import Combine

class GameState: ObservableObject {
    @Published var bestScore: Int?
    @Published var soundEnabled: Bool = true
    @Published var hapticEnabled: Bool = true
    @Published var hasSeenTutorial: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        soundEnabled = userDefaults.bool(forKey: "soundEnabled")
        hapticEnabled = userDefaults.bool(forKey: "hapticEnabled")
        hasSeenTutorial = userDefaults.bool(forKey: "hasSeenTutorial")
        
        // Set defaults if first launch
        if !userDefaults.bool(forKey: "hasLaunchedBefore") {
            soundEnabled = true
            hapticEnabled = true
            hasSeenTutorial = false
            userDefaults.set(true, forKey: "hasLaunchedBefore")
            saveSettings()
        }
    }
    
    func saveSettings() {
        userDefaults.set(soundEnabled, forKey: "soundEnabled")
        userDefaults.set(hapticEnabled, forKey: "hapticEnabled")
        userDefaults.set(hasSeenTutorial, forKey: "hasSeenTutorial")
    }
    
    func loadBestScore() {
        Task {
            do {
                let uid = try await FirebaseService.shared.ensureAnonymousSignIn()
                let score = try await FirebaseService.shared.fetchBestScore(uid: uid)
                await MainActor.run {
                    self.bestScore = score
                }
            } catch {
                print("Failed to load best score: \(error)")
            }
        }
    }
    
    func updateBestScore(_ score: Int) {
        if let current = bestScore {
            bestScore = max(current, score)
        } else {
            bestScore = score
        }
    }
    
    func markTutorialSeen() {
        hasSeenTutorial = true
        saveSettings()
    }
}