import Foundation

enum NavigationDestination: Hashable {
    case game
    case score(Int)
    case ranking
    case tutorial
    case settings
}