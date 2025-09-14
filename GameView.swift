import SwiftUI
import Combine

// MARK: - Helpers
private func generateRandomNumbers() -> [Int] {
    var set = Set<Int>()
    while set.count < 4 { set.insert(Int.random(in: 1...9)) }
    return Array(set)
}

private func isValidUsage(usedDigits: [Int], given: [Int]) -> Bool {
    var pool = given
    for d in usedDigits {
        if let i = pool.firstIndex(of: d) { pool.remove(at: i) } else { return false }
    }
    return true
}

// MARK: - GameView
struct GameView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var gameState: GameState

    // Config
    private let initialTime: Int = 60
    private let rewardTime: Int = 15

    // State
    @State private var timeLeft: Int = 60
    @State private var score: Int = 0
    @State private var numbers: [Int] = generateRandomNumbers()
    @State private var usedNumbers: [Int] = []
    @State private var expression: String = ""

    // Timer
    @State private var timerCancellable: AnyCancellable?
    @State private var warningShown = false

    // Animations
    @State private var showPlus15: Bool = false
    @State private var plus15Offset: CGFloat = 0
    @State private var scoreAnimation: Bool = false
    @State private var timeWarning: Bool = false
    @State private var timeFlashOpacity: Double = 1.0
    @State private var correctAnimation: Bool = false
    @State private var shakeAnimation: Bool = false

    // Alert
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    // UI
    private let operatorsRow1 = ["+", "−", "×", "÷"]
    private let operatorsRow2 = ["(", ")"]

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

            GeometryReader { proxy in
                let safeWidth = max(proxy.size.width, 320)
                let gap: CGFloat = 12
                let hPad: CGFloat = 24
                let rawBtnW = (safeWidth - hPad * 2 - gap * 3) / 4
                let btnW = max(min(rawBtnW, 200), 44)
                let numBtnH: CGFloat = 70
                let opBtnH: CGFloat = 56

                VStack(spacing: 20) {
                    // Header with TIME and SCORE
                    HStack(spacing: 16) {
                        infoCard(
                            title: "TIME",
                            bg: timeLeft <= 10 ? .red : .blue,
                            content: Text("\(timeLeft)s")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        )
                        .opacity(timeWarning ? timeFlashOpacity : 1.0)
                        .overlay(alignment: .topTrailing) {
                            if showPlus15 {
                                Text("+15秒")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                    )
                                    .offset(y: plus15Offset)
                                    .allowsHitTesting(false)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        infoCard(
                            title: "SCORE",
                            bg: LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            content: Text("\(score)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .scaleEffect(scoreAnimation ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scoreAnimation)
                        )
                    }
                    .padding(.horizontal, 24)

                    // Expression Display
                    VStack(spacing: 8) {
                        Text("目標: 10")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(expression.isEmpty ? "数字と演算子で式を作ろう" : expression)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(expression.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(correctAnimation ? Color.green : Color.clear, lineWidth: 3)
                                            .animation(.easeInOut(duration: 0.3), value: correctAnimation)
                                    )
                            )
                            .offset(x: shakeAnimation ? -5 : 0)
                            .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: shakeAnimation)
                    }
                    .padding(.horizontal, 32)

                    // Number Buttons
                    HStack(spacing: gap) {
                        ForEach(numbers, id: \.self) { n in
                            NumberButton(
                                number: n,
                                isUsed: usedNumbers.contains(n),
                                width: btnW,
                                height: numBtnH
                            ) {
                                handleNumberPress(n)
                            }
                        }
                    }
                    .padding(.horizontal, hPad)

                    // Operator Buttons Row 1
                    HStack(spacing: gap) {
                        ForEach(operatorsRow1, id: \.self) { op in
                            OperatorButton(operator: op, width: btnW, height: opBtnH) {
                                handleOperatorPress(op)
                            }
                        }
                    }
                    .padding(.horizontal, hPad)

                    // Operator Buttons Row 2
                    HStack(spacing: gap) {
                        ForEach(operatorsRow2, id: \.self) { op in
                            OperatorButton(operator: op, width: btnW, height: opBtnH) {
                                handleOperatorPress(op)
                            }
                        }
                    }
                    .padding(.horizontal, hPad)

                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(
                            title: "送信",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            action: handleSubmit
                        )

                        ActionButton(
                            title: "クリア",
                            icon: "xmark.circle.fill",
                            color: .red,
                            action: handleClear
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
        }
        .navigationTitle("Quick Ten")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("終了") {
                    timerCancellable?.cancel()
                    router.reset()
                }
                .foregroundColor(.red)
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timerCancellable?.cancel() }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    handleClear()
                }
            )
        }
    }

    // MARK: - UI Components
    private func infoCard<T: View>(title: String, bg: Color, content: T) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .kerning(1)
                .foregroundStyle(.white.opacity(0.8))
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(bg)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
    }
    
    private func infoCard<T: View>(title: String, bg: LinearGradient, content: T) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .kerning(1)
                .foregroundStyle(.white.opacity(0.8))
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(bg)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
    }

    // MARK: - Logic
    private func handleNumberPress(_ n: Int) {
        guard !usedNumbers.contains(n) else { return }
        
        if gameState.soundEnabled {
            SoundManager.shared.playSound("button")
        }
        if gameState.hapticEnabled {
            HapticManager.selection()
        }
        
        expression.append(String(n))
        usedNumbers.append(n)
    }
    
    private func handleOperatorPress(_ op: String) {
        if gameState.soundEnabled {
            SoundManager.shared.playSound("button")
        }
        if gameState.hapticEnabled {
            HapticManager.selection()
        }
        
        expression.append(op)
    }

    private func handleClear() {
        if gameState.soundEnabled {
            SoundManager.shared.playSound("button")
        }
        if gameState.hapticEnabled {
            HapticManager.impact(.light)
        }
        
        expression = ""
        usedNumbers = []
    }

    private func startTimer() {
        timeLeft = initialTime
        score = 0
        numbers = generateRandomNumbers()
        usedNumbers = []
        expression = ""
        warningShown = false
        timeWarning = false
        timeFlashOpacity = 1.0

        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timeLeft -= 1
                
                // Time warning at 10 seconds
                if timeLeft == 10 && !warningShown {
                    timeWarning = true
                    warningShown = true
                    startTimeFlashing()
                    if gameState.soundEnabled {
                        SoundManager.shared.playSound("timeWarning")
                    }
                    if gameState.hapticEnabled {
                        HapticManager.notification(.warning)
                    }
                }
                
                // Stop flashing when time runs out
                if timeLeft <= 0 {
                    timeWarning = false
                    timeFlashOpacity = 1.0
                }
                
                if timeLeft <= 0 {
                    timeLeft = 0
                    timerCancellable?.cancel()
                    
                    if gameState.soundEnabled {
                        SoundManager.shared.playSound("gameOver")
                    }
                    if gameState.hapticEnabled {
                        HapticManager.notification(.error)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        router.pushScore(score)
                    }
                }
            }
    }
    
    private func startTimeFlashing() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            timeFlashOpacity = 0.3
        }
    }

    private func correctFeedback() {
        // Visual feedback
        correctAnimation = true
        scoreAnimation = true
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showPlus15 = true
            plus15Offset = 0
        }
        
        withAnimation(.easeOut(duration: 1.0)) {
            plus15Offset = -40
        }
        
        // Audio and haptic feedback
        if gameState.soundEnabled {
            SoundManager.shared.playSound("correct")
        }
        if gameState.hapticEnabled {
            HapticManager.notification(.success)
        }
        
        // Reset animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            correctAnimation = false
            scoreAnimation = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.2)) {
                showPlus15 = false
                plus15Offset = 0
            }
        }
    }

    private func handleSubmit() {
        let used = expression.compactMap { ch -> Int? in
            guard ch.isNumber else { return nil }
            return Int(String(ch))
        }

        guard used.count == 4, isValidUsage(usedDigits: used, given: numbers) else {
            showError("エラー", "与えられた4つの数字を1回ずつ使ってください！")
            return
        }

        let safeExpr = expression
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")

        let allowed = CharacterSet(charactersIn: "0123456789()+-*/ ")
        guard safeExpr.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            showError("式エラー", "数式が不正です")
            return
        }

        let expr = NSExpression(format: safeExpr)
        guard let num = expr.expressionValue(with: nil, context: nil) as? NSNumber else {
            showError("式エラー", "数式を評価できませんでした")
            return
        }

        if abs(num.doubleValue - 10.0) < 1e-9 {
            correctFeedback()
            score += 1
            timeLeft += rewardTime
            numbers = generateRandomNumbers()
            usedNumbers = []
            expression = ""
        } else {
            showError("不正解", "答えが10ではありません！\n計算結果: \(num.doubleValue)")
        }
    }

    private func showError(_ title: String, _ message: String) {
        shakeAnimation = true
        
        if gameState.soundEnabled {
            SoundManager.shared.playSound("incorrect")
        }
        if gameState.hapticEnabled {
            HapticManager.notification(.error)
        }
        
        alertTitle = title
        alertMessage = message
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeAnimation = false
        }
    }
}

// MARK: - Custom Button Components
struct NumberButton: View {
    let number: Int
    let isUsed: Bool
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: isUsed ? [.gray, .gray.opacity(0.7)] : [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: isUsed ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .opacity(isUsed ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isUsed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing && !isUsed
        }, perform: {})
    }
}

struct OperatorButton: View {
    let `operator`: String
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(`operator`)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
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

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
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

#Preview {
    NavigationView {
        GameView()
            .environmentObject(Router())
            .environmentObject(GameState())
    }
}