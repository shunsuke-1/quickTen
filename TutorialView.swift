import SwiftUI

struct TutorialView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var gameState: GameState
    @State private var currentPage = 0
    @State private var animateContent = false
    
    private let pages = [
        TutorialPage(
            title: "Quick Ten へようこそ！",
            description: "4つの数字を使って10を作る数学パズルゲームです",
            icon: "hand.wave.fill",
            color: .blue
        ),
        TutorialPage(
            title: "ルールは簡単",
            description: "与えられた4つの数字を全て使って、計算式で10を作りましょう",
            icon: "plus.forwardslash.minus",
            color: .green
        ),
        TutorialPage(
            title: "時間制限あり",
            description: "60秒の制限時間内に、できるだけ多くの問題を解きましょう",
            icon: "timer",
            color: .orange
        ),
        TutorialPage(
            title: "正解でボーナス",
            description: "正解すると+15秒のボーナスタイムがもらえます",
            icon: "plus.circle.fill",
            color: .purple
        ),
        TutorialPage(
            title: "例題を見てみよう",
            description: "数字 [2, 3, 4, 5] の場合\n2 + 3 + 5 = 10 ✓\n(4 + 3) × 2 - 5 = 9 ✗",
            icon: "lightbulb.fill",
            color: .yellow
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
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
                
                VStack(spacing: 0) {
                    // Progress Bar
                    HStack {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Rectangle()
                                .fill(index <= currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            TutorialPageView(page: page, isActive: index == currentPage)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                    
                    // Navigation Buttons
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button("戻る") {
                                withAnimation {
                                    currentPage -= 1
                                }
                                HapticManager.selection()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        } else {
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if currentPage < pages.count - 1 {
                            Button("次へ") {
                                withAnimation {
                                    currentPage += 1
                                }
                                HapticManager.selection()
                            }
                            .buttonStyle(PrimaryButtonStyle(color: pages[currentPage].color))
                        } else {
                            Button("ゲーム開始！") {
                                gameState.markTutorialSeen()
                                HapticManager.impact(.medium)
                                router.navigate(to: .game)
                            }
                            .buttonStyle(PrimaryButtonStyle(color: .green))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("遊び方")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateContent = true
        }
    }
}

struct TutorialPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct TutorialPageView: View {
    let page: TutorialPage
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: page.color.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isActive ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isActive)
            
            // Text Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(isActive ? 1.0 : 0.7)
            .offset(y: isActive ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: isActive)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        TutorialView()
            .environmentObject(Router())
            .environmentObject(GameState())
    }
}