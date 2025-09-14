import SwiftUI
import FirebaseAuth

struct RankingView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var gameState: GameState

    @State private var entries: [RankingEntry] = []
    @State private var myBest: Int?
    @State private var loading = true
    @State private var animateList = false
    @State private var selectedTab = 0
    
    private var myUid: String? { Auth.auth().currentUser?.uid }
    private var myRank: Int? {
        guard let uid = myUid else { return nil }
        return entries.firstIndex(where: { $0.userId == uid }).map { $0 + 1 }
    }

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

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("ランキング")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Text("世界中のプレイヤーと競争しよう！")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                if loading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("ランキングを読み込み中...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // My Stats Card
                    if let best = myBest {
                        MyStatsCard(
                            bestScore: best,
                            rank: myRank,
                            totalPlayers: entries.count
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .opacity(animateList ? 1.0 : 0.0)
                        .offset(y: animateList ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateList)
                    }

                    // Ranking List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(entries.enumerated()), id: \.1.id) { (index, entry) in
                                RankingRow(
                                    rank: index + 1,
                                    entry: entry,
                                    isCurrentUser: isMe(entry),
                                    animationDelay: Double(index) * 0.05
                                )
                                .opacity(animateList ? 1.0 : 0.0)
                                .offset(x: animateList ? 0 : -50)
                                .animation(
                                    .easeOut(duration: 0.5)
                                    .delay(0.2 + Double(index) * 0.05),
                                    value: animateList
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }

                // Bottom Actions
                VStack(spacing: 16) {
                    Button {
                        Task { await load() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            Text("更新")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: .blue.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    }
                    .disabled(loading)

                    Button {
                        router.reset()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("ホームに戻る")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(animateList ? 1.0 : 0.0)
                .offset(y: animateList ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateList)
            }
        }
        .navigationBarHidden(true)
        .task {
            await load()
        }
        .onAppear {
            animateList = true
        }
    }

    private func load() async {
        loading = true
        do {
            let uid = try await FirebaseService.shared.ensureAnonymousSignIn()
            myBest = try await FirebaseService.shared.fetchBestScore(uid: uid)
            entries = try await FirebaseService.shared.fetchRanking(limit: 10)
        } catch {
            print("Ranking load error:", error)
        }
        loading = false
    }

    private func isMe(_ e: RankingEntry) -> Bool { e.userId == myUid }
}

struct MyStatsCard: View {
    let bestScore: Int
    let rank: Int?
    let totalPlayers: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("あなたの記録")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("\(bestScore)問")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let rank = rank {
                        Text("順位")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("#\(rank)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                    } else {
                        Text("圏外")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("TOP10入りを目指そう！")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
}

struct RankingRow: View {
    let rank: Int
    let entry: RankingEntry
    let isCurrentUser: Bool
    let animationDelay: Double
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "number.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(rankColor)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Player \(entry.userId.prefix(8))...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCurrentUser ? .green : .primary)
                    
                    if isCurrentUser {
                        Text("あなた")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                }
                
                if let date = entry.updatedAt {
                    Text(formatDate(date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.bestScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentUser ? .green : .primary)
                
                Text("問")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentUser ? Color.green.opacity(0.1) : Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentUser ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        RankingView()
            .environmentObject(Router())
            .environmentObject(GameState())
    }
}

