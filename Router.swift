import SwiftUI

final class Router: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to destination: NavigationDestination) {
        DispatchQueue.main.async {
            self.path.append(destination)
        }
    }
    
    func pushScore(_ score: Int) {
        navigate(to: .score(score))
    }

    func pushRanking() {
        navigate(to: .ranking)
    }
    
    func pushGame() {
        navigate(to: .game)
    }
    
    func pushTutorial() {
        navigate(to: .tutorial)
    }
    
    func pushSettings() {
        navigate(to: .settings)
    }

    func pop() {
        DispatchQueue.main.async {
            if !self.path.isEmpty {
                self.path.removeLast()
            }
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.path = NavigationPath()
        }
    }
}
