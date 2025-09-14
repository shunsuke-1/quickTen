import SwiftUI
import FirebaseAuth

struct ScoreView: View {
    let score: Int
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var gameState: GameState

    @State private var userId: String = ""
    @State private var saved = false
    @State private var isBest = false
    @State private var bestScore: Int?
    @State private var animateScore = false
    @State private var animateButtons = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.90, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti effect
            if showConfetti && isBest {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Game Over Header
                    VStack(spacing: 16) {
                        Text(isBest ? "🎉 新記録達成！ 🎉" : "🎮 ゲーム終了 🎮")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isBest ? [.yellow, .orange] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .scaleEffect(animateScore ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateScore)
                    }

                    // Score Display
                    VStack(spacing: 20) {
                        Text("あなたのスコア")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.secondary)

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)

                            VStack(spacing: 8) {
                                Text("\(score)")
                                    .font(.system(size: 72, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("問正解")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .scaleEffect(animateScore ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateScore)
                    }

                    // Status Message
                    VStack(spacing: 12) {
                        if saved && isBest {
                            StatusCard(
                                icon: "trophy.fill",
                                title: "自己ベスト更新！",
                                subtitle: "ランキングに登録されました",
                                color: .yellow
                            )
                        } else if saved {
                            StatusCard(
                                icon: "checkmark.circle.fill",
                                title: "お疲れさまでした！",
                                subtitle: "次回はもっと高得点を目指そう",
                                color: .green
                            )
                        }

                        if let uid = Auth.auth().currentUser?.uid {
                            Text("プレイヤーID: \(uid.prefix(8))...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.6))
                                )
                        }
                    }
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateButtons)

                    // Best Score Display
                    if let b = bestScore {
                        BestScoreCard(bestScore: b, currentScore: score)
                            .opacity(animateButtons ? 1.0 : 0.0)
                            .offset(y: animateButtons ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateButtons)
                    }

                    // Action Buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ScoreActionButton(
                                title: "もう一度",
                                icon: "arrow.clockwise",
                                color: .green,
                                action: {
                                    navigateAfterAd {
                                        router.reset()
                                    }
                                }
                            )

                            ScoreActionButton(
                                title: "ランキング",
                                icon: "trophy.fill",
                                color: .orange,
                                action: {
                                    navigateAfterAd {
                                        router.pushRanking()
                                    }
                                }
                            )
                        }

                        ScoreActionButton(
                            title: "ホームに戻る",
                            icon: "house.fill",
                            color: .blue,
                            isWide: true,
                            action: {
                                router.reset()
                            }
                        )
                    }
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .offset(y: animateButtons ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateButtons)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateScore = true
            animateButtons = true
            
            if gameState.hapticEnabled {
                HapticManager.notification(.success)
            }
        }
        .task {
            do {
                let uid = try await FirebaseService.shared.ensureAnonymousSignIn()
                userId = uid
                let updated = try await FirebaseService.shared.saveIfBestScore(score)
                isBest = updated
                saved = true
                bestScore = try await FirebaseService.shared.fetchBestScore(uid: uid)
                
                if updated {
                    gameState.updateBestScore(score)
                    showConfetti = true
                    
                    if gameState.soundEnabled {
                        SoundManager.shared.playSound("correct")
                    }
                    if gameState.hapticEnabled {
                        HapticManager.notification(.success)
                    }
                }
            } catch {
                print("Save/fetch error:", error)
                saved = true
            }
        }
    }
    
    private func navigateAfterAd(_ after: @escaping () -> Void) {
        AdsManager.shared.showInterstitial(after: after)
    }
}

struct StatusCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct BestScoreCard: View {
    let bestScore: Int
    let currentScore: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("ベストスコア")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(bestScore)問")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            if currentScore < bestScore {
                HStack {
                    Text("目標まで")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("あと\(bestScore - currentScore)問")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ScoreActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isWide: Bool
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, isWide: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isWide = isWide
        self.action = action
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                
                if !isWide {
                    Spacer()
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .frame(maxWidth: isWide ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
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

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                ConfettiPiece()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    @State private var animate = false
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let startX = Double.random(in: -50...UIScreen.main.bounds.width + 50)
    private let endX = Double.random(in: -100...UIScreen.main.bounds.width + 100)
    private let duration = Double.random(in: 2...4)
    private let delay = Double.random(in: 0...2)
    
    var body: some View {
        Rectangle()
            .fill(colors.randomElement() ?? .blue)
            .frame(width: 8, height: 8)
            .position(
                x: animate ? endX : startX,
                y: animate ? UIScreen.main.bounds.height + 50 : -50
            )
            .animation(
                .linear(duration: duration)
                .delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

#Preview {
    ScoreView(score: 15)
        .environmentObject(Router())
        .environmentObject(GameState())
}
