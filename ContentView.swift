import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var gameState: GameState
    @State private var showingTutorial = false
    @State private var animateTitle = false
    @State private var animateButtons = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.90, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Title Section
                    VStack(spacing: 16) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Text("10")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(animateTitle ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateTitle)
                        
                        // Title
                        VStack(spacing: 8) {
                            Text("Quick Ten")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("数字で10を作ろう！")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .offset(y: animateTitle ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateTitle)
                    }
                    
                    Spacer()
                    
                    // Menu Buttons
                    VStack(spacing: 20) {
                        // Play Button
                        MenuButton(
                            title: "ゲームスタート",
                            subtitle: "60秒で何問解ける？",
                            icon: "play.fill",
                            gradient: LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            action: {
                                HapticManager.impact(.medium)
                                router.navigate(to: .game)
                            }
                        )
                        
                        // Tutorial Button
                        MenuButton(
                            title: "遊び方",
                            subtitle: "ルールを覚えよう",
                            icon: "questionmark.circle.fill",
                            gradient: LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            action: {
                                HapticManager.impact(.light)
                                router.navigate(to: .tutorial)
                            }
                        )
                        
                        // Ranking Button
                        MenuButton(
                            title: "ランキング",
                            subtitle: "世界の記録を見る",
                            icon: "trophy.fill",
                            gradient: LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            action: {
                                HapticManager.impact(.light)
                                router.navigate(to: .ranking)
                            }
                        )
                        
                        // Settings Button
                        MenuButton(
                            title: "設定",
                            subtitle: "音やバイブレーション",
                            icon: "gearshape.fill",
                            gradient: LinearGradient(
                                colors: [Color.gray, Color.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            action: {
                                HapticManager.impact(.light)
                                router.navigate(to: .settings)
                            }
                        )
                    }
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: animateButtons)
                    
                    Spacer()
                    
                    // Best Score Display
                    if let bestScore = gameState.bestScore {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("ベストスコア: \(bestScore)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .opacity(animateButtons ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateButtons)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateTitle = true
            animateButtons = true
            gameState.loadBestScore()
        }
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    ContentView()
        .environmentObject(Router())
        .environmentObject(GameState())
}
