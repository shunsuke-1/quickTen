import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var gameState: GameState
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("設定")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                
                // Settings Sections
                VStack(spacing: 16) {
                    // Audio & Haptics
                    SettingsSection(title: "音とバイブレーション") {
                        SettingsToggle(
                            title: "効果音",
                            subtitle: "ボタンや正解時の音",
                            icon: "speaker.wave.2.fill",
                            isOn: $gameState.soundEnabled
                        ) {
                            gameState.saveSettings()
                            if gameState.soundEnabled {
                                SoundManager.shared.playSound("button")
                            }
                        }
                        
                        SettingsToggle(
                            title: "バイブレーション",
                            subtitle: "触覚フィードバック",
                            icon: "iphone.radiowaves.left.and.right",
                            isOn: $gameState.hapticEnabled
                        ) {
                            gameState.saveSettings()
                            if gameState.hapticEnabled {
                                HapticManager.impact(.light)
                            }
                        }
                    }
                    
                    // Game Info
                    SettingsSection(title: "ゲーム情報") {
                        SettingsRow(
                            title: "遊び方を見る",
                            subtitle: "ルールとコツを確認",
                            icon: "questionmark.circle.fill",
                            action: {
                                HapticManager.selection()
                                router.navigate(to: .tutorial)
                            }
                        )
                        
                        if let bestScore = gameState.bestScore {
                            SettingsInfoRow(
                                title: "ベストスコア",
                                value: "\(bestScore)問",
                                icon: "star.fill"
                            )
                        }
                    }
                    
                    // Data Management
                    SettingsSection(title: "データ管理") {
                        SettingsRow(
                            title: "データをリセット",
                            subtitle: "ベストスコアを削除",
                            icon: "trash.fill",
                            isDestructive: true,
                            action: {
                                showingResetAlert = true
                            }
                        )
                    }
                    
                    // App Info
                    SettingsSection(title: "アプリ情報") {
                        SettingsInfoRow(
                            title: "バージョン",
                            value: "1.0.0",
                            icon: "info.circle.fill"
                        )
                        
                        SettingsInfoRow(
                            title: "開発者",
                            value: "Shunsuke Shimomura",
                            icon: "person.fill"
                        )
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.90, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("データをリセット", isPresented: $showingResetAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("リセット", role: .destructive) {
                resetGameData()
            }
        } message: {
            Text("ベストスコアなどのデータが削除されます。この操作は取り消せません。")
        }
    }
    
    private func resetGameData() {
        gameState.bestScore = nil
        gameState.hasSeenTutorial = false
        gameState.saveSettings()
        HapticManager.notification(.success)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    let onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { _ in
                    onChange()
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill((isDestructive ? Color.red : Color.blue).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDestructive ? .red : .blue)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)
            }
            
            // Text
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(Router())
            .environmentObject(GameState())
    }
}