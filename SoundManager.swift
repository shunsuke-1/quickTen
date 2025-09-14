import AVFoundation
import UIKit

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playSound(_ soundName: String, volume: Float = 1.0) {
        // For now, we'll use system sounds since we don't have audio files
        // In a real app, you would load actual sound files
        switch soundName {
        case "correct":
            AudioServicesPlaySystemSound(1057) // Tink sound
        case "incorrect":
            AudioServicesPlaySystemSound(1053) // Error sound
        case "button":
            AudioServicesPlaySystemSound(1104) // Click sound
        case "gameOver":
            AudioServicesPlaySystemSound(1005) // New mail sound
        case "timeWarning":
            AudioServicesPlaySystemSound(1016) // Alert sound
        default:
            AudioServicesPlaySystemSound(1104) // Default click
        }
    }
    
    func playHaptic(_ type: HapticType) {
        switch type {
        case .light:
            HapticManager.impact(.light)
        case .medium:
            HapticManager.impact(.medium)
        case .heavy:
            HapticManager.impact(.heavy)
        case .success:
            HapticManager.notification(.success)
        case .error:
            HapticManager.notification(.error)
        case .warning:
            HapticManager.notification(.warning)
        case .selection:
            HapticManager.selection()
        }
    }
}

enum HapticType {
    case light, medium, heavy
    case success, error, warning
    case selection
}