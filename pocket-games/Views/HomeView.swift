import SwiftUI

struct HomeView: View {
    @AppStorage("pocketQuestXP") private var xp = 1250
    @AppStorage("pocketQuestDailyChallengeProgress") private var dailyChallengeProgress = 0
    @AppStorage("pocketQuestDailyChallengeClaimed") private var dailyChallengeClaimed = false

    var body: some View {
        TabView {
            GameHubHomeScreen(
                xp: $xp,
                dailyChallengeProgress: $dailyChallengeProgress,
                dailyChallengeClaimed: $dailyChallengeClaimed
            )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            GamesLibraryScreen(
                xp: $xp,
                dailyChallengeProgress: $dailyChallengeProgress
            )
                .tabItem {
                    Label("Games", systemImage: "gamecontroller.fill")
                }

            AchievementsScreen(
                xp: xp,
                dailyChallengeProgress: dailyChallengeProgress,
                dailyChallengeClaimed: dailyChallengeClaimed
            )
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }

            SettingsScreen(
                xp: $xp,
                dailyChallengeProgress: $dailyChallengeProgress,
                dailyChallengeClaimed: $dailyChallengeClaimed
            )
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

private struct GameHubHomeScreen: View {
    @Binding var xp: Int
    @Binding var dailyChallengeProgress: Int
    @Binding var dailyChallengeClaimed: Bool

    @State private var searchText = ""
    @State private var selectedCategory: GameCategory?

    private var filteredGames: [GameOption] {
        GameOption.allCases.filter { game in
            let matchesCategory = selectedCategory == nil || game.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || game.rawValue.localizedCaseInsensitiveContains(query)
                || game.shortDescription.localizedCaseInsensitiveContains(query)
                || game.category.rawValue.localizedCaseInsensitiveContains(query)

            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                hubBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        HeroHeader(totalGames: GameOption.allCases.count, xp: xp)
                        ProgressStrip(
                            xp: $xp,
                            dailyChallengeProgress: $dailyChallengeProgress,
                            dailyChallengeClaimed: $dailyChallengeClaimed
                        )
                        CategoryPicker(selectedCategory: $selectedCategory)

                        SectionHeader(
                            title: selectedCategory?.rawValue ?? "Featured Games",
                            subtitle: "\(filteredGames.count) ready to play"
                        )

                        GameGrid(games: filteredGames) { _ in
                            awardPlayXP()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .frame(maxWidth: 1080)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Pocket Quest")
            .hiddenNavigationTitle()
            .searchable(text: $searchText, placement: .automatic, prompt: "Search games")
            .navigationDestination(for: GameOption.self) { game in
                GameDestination(game: game)
            }
        }
    }

    private func awardPlayXP() {
        xp += 25
        dailyChallengeProgress = min(3, dailyChallengeProgress + 1)
    }
}

private struct GamesLibraryScreen: View {
    @Binding var xp: Int
    @Binding var dailyChallengeProgress: Int

    @State private var searchText = ""

    private var filteredCategories: [GameCategory] {
        GameCategory.allCases.filter { category in
            let categoryGames = games(in: category)
            return !categoryGames.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                hubBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        SectionHeader(title: "Games Library", subtitle: "Browse by category")

                        ForEach(filteredCategories) { category in
                            let categoryGames = games(in: category)

                            VStack(alignment: .leading, spacing: 14) {
                                CategoryTitle(category: category, count: categoryGames.count)
                                GameGrid(games: categoryGames) { _ in
                                    awardPlayXP()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 1080)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Games")
            .hiddenNavigationTitle()
            .searchable(text: $searchText, placement: .automatic, prompt: "Search library")
            .navigationDestination(for: GameOption.self) { game in
                GameDestination(game: game)
            }
        }
    }

    private func games(in category: GameCategory) -> [GameOption] {
        GameOption.allCases.filter { game in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || game.rawValue.localizedCaseInsensitiveContains(query)
                || game.shortDescription.localizedCaseInsensitiveContains(query)

            return game.category == category && matchesSearch
        }
    }

    private func awardPlayXP() {
        xp += 25
        dailyChallengeProgress = min(3, dailyChallengeProgress + 1)
    }
}

private struct AchievementsScreen: View {
    let xp: Int
    let dailyChallengeProgress: Int
    let dailyChallengeClaimed: Bool

    private var achievements: [AchievementBadge] {
        [
            AchievementBadge(title: "First Quest", subtitle: "Play any game", icon: "sparkles", progress: min(Double(xp) / 25, 1)),
            AchievementBadge(title: "Level Up", subtitle: "Reach level 3", icon: "arrow.up.circle.fill", progress: min(Double(XPStatus(xp: xp).level) / 3, 1)),
            AchievementBadge(title: "Daily Hero", subtitle: "Finish today’s challenge", icon: "calendar.badge.checkmark", progress: dailyChallengeClaimed ? 1 : Double(dailyChallengeProgress) / 3),
            AchievementBadge(title: "XP Collector", subtitle: "Earn 2,000 XP", icon: "flame.fill", progress: min(Double(xp) / 2_000, 1))
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                hubBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SectionHeader(title: "Achievements", subtitle: "Badges, streaks, and milestones")
                        DailyChallengeCard()

                        LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                            ForEach(achievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Achievements")
            .hiddenNavigationTitle()
        }
    }
}

private struct SettingsScreen: View {
    @Binding var xp: Int
    @Binding var dailyChallengeProgress: Int
    @Binding var dailyChallengeClaimed: Bool

    @State private var soundEnabled = true
    @State private var animationsEnabled = true
    @State private var dailyReminder = false

    private var xpStatus: XPStatus {
        XPStatus(xp: xp)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                hubBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Settings", subtitle: "Tune Pocket Quest for how you play")

                        SettingsGroup {
                            Toggle("Sound Effects", isOn: $soundEnabled)
                            Toggle("Animations", isOn: $animationsEnabled)
                            Toggle("Daily Challenge Reminder", isOn: $dailyReminder)
                        }

                        SettingsGroup {
                            SettingsInfoRow(title: "Player Level", value: "Level \(xpStatus.level)")
                            SettingsInfoRow(title: "XP", value: "\(xp)")
                            SettingsInfoRow(title: "Next Level", value: "\(xpStatus.remainingXP) XP left")
                            SettingsInfoRow(title: "Games Available", value: "\(GameOption.allCases.count)")
                        }

                        Button("Reset XP Progress") {
                            xp = 0
                            dailyChallengeProgress = 0
                            dailyChallengeClaimed = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .hiddenNavigationTitle()
        }
    }
}

private struct HeroHeader: View {
    let totalGames: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)
                .shadow(color: .blue.opacity(0.28), radius: 18, y: 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pocket Quest")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("Welcome back. Pick a quest and keep your streak moving.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                HeroMetric(title: "Games", value: "\(totalGames)", tint: .cyan)
                HeroMetric(title: "Level", value: "4", tint: .orange)
                HeroMetric(title: "XP", value: "1.2K", tint: .green)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 22, y: 12)
    }
}

private struct ProgressStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Daily Challenge", systemImage: "calendar.badge.clock")
                    .font(.headline)

                Spacer()

                Text("3 quests left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: 0.45)
                .tint(.orange)

            Text("Play a puzzle, a reaction game, and any bonus quest to earn 500 XP.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct CategoryPicker: View {
    @Binding var selectedCategory: GameCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    title: "All",
                    systemImage: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedCategory = nil
                    }
                }

                ForEach(GameCategory.allCases) { category in
                    CategoryPill(
                        title: category.rawValue,
                        systemImage: category.systemImage,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct GameGrid: View {
    let games: [GameOption]

    var body: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: 18) {
            ForEach(games) { game in
                NavigationLink(value: game) {
                    GameCard(game: game)
                }
                .buttonStyle(PressableCardButtonStyle())
            }
        }
    }
}

private struct GameCard: View {
    let game: GameOption

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                GameIcon(game: game)

                Spacer()

                DifficultyBadge(text: game.difficulty)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(game.rawValue)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(game.shortDescription)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                Label(game.statLabel, systemImage: "chart.bar.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack {
                    Text(game.category.rawValue)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    Label("Play", systemImage: "play.fill")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white, in: Capsule())
                }
            }
        }
        .padding(18)
        .frame(minHeight: 238)
        .background(
            LinearGradient(
                colors: gradientColors(for: game),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 116, height: 116)
                .offset(x: 38, y: -42)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: shadowColor(for: game).opacity(0.26), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.rawValue), \(game.shortDescription), difficulty \(game.difficulty)")
    }
}

private struct GameIcon: View {
    let game: GameOption

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                }

            Image(systemName: game.systemImage)
                .font(.system(size: 34, weight: .black))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
        .frame(width: 66, height: 66)
    }
}

private struct DifficultyBadge: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "star.fill")
            .font(.caption2.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.18), in: Capsule())
    }
}

private struct CategoryPill: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? Color.accentColor : Color.primary.opacity(0.07),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .black))

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct CategoryTitle: View {
    let category: GameCategory
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.systemImage)
                .font(.headline)
                .foregroundStyle(Color.accentColor)

            Text(category.rawValue)
                .font(.headline.weight(.heavy))

            Text("\(count)")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.07), in: Capsule())
        }
    }
}

private struct DailyChallengeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Today’s Quest", systemImage: "sun.max.fill")
                    .font(.headline.weight(.heavy))

                Spacer()

                Text("+500 XP")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.14), in: Capsule())
            }

            Text("Play one puzzle game and one reaction game.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ProgressView(value: 0.45)
                .tint(.orange)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct AchievementBadge: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let progress: Double
}

private struct AchievementCard: View {
    let achievement: AchievementBadge

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: achievement.icon)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.orange)
                .frame(width: 54, height: 54)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline.weight(.heavy))

                Text(achievement.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: achievement.progress)
                .tint(.orange)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
        }
    }
}

private struct GameDestination: View {
    let game: GameOption

    var body: some View {
        Group {
            switch game {
            case .ticTacToe:
                GameView()
            case .rockPaperScissors:
                RockPaperScissorsView()
            case .coinFlip:
                CoinFlipView()
            case .targetTap:
                TargetTapView()
            case .twentyFortyEight:
                Game2048View()
            case .memoryMatch:
                MemoryMatchView()
            case .numberGuess:
                NumberGuessView()
            case .reactionTime:
                ReactionTimeView()
            case .clicksPerSecond:
                ClicksPerSecondView()
            case .stopTimer:
                StopTimerView()
            case .colorRush:
                ColorRushView()
            case .wordle:
                WordleView()
            case .hangman:
                HangmanView()
            case .nimDuel:
                NimDuelView()
            case .codeBreaker:
                CodeBreakerView()
            }
        }
        .navigationTitle(game.rawValue)
        .inlineNavigationTitle()
    }
}

private struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.24, dampingFraction: 0.76), value: configuration.isPressed)
    }
}

private let adaptiveColumns = [
    GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 18)
]

private var hubBackground: some View {
    LinearGradient(
        colors: [
            Color(uiColorName: "systemBackground"),
            Color.cyan.opacity(0.12),
            Color.orange.opacity(0.10),
            Color(uiColorName: "secondarySystemBackground")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
}

private func gradientColors(for game: GameOption) -> [Color] {
    switch game {
    case .ticTacToe:
        return [.blue, .indigo]
    case .rockPaperScissors:
        return [.orange, .pink]
    case .coinFlip:
        return [.yellow, .orange]
    case .targetTap:
        return [.pink, .red]
    case .twentyFortyEight:
        return [.green, .teal]
    case .memoryMatch:
        return [.indigo, .purple]
    case .numberGuess:
        return [.teal, .cyan]
    case .reactionTime:
        return [.purple, .blue]
    case .clicksPerSecond:
        return [.red, .orange]
    case .stopTimer:
        return [.blue, .cyan]
    case .colorRush:
        return [.orange, .yellow]
    case .wordle:
        return [.mint, .green]
    case .hangman:
        return [.cyan, .blue]
    case .nimDuel:
        return [.purple, .indigo]
    case .codeBreaker:
        return [.red, .purple]
    }
}

private func shadowColor(for game: GameOption) -> Color {
    gradientColors(for: game).first ?? .black
}

private extension Color {
    init(uiColorName: String) {
#if os(iOS) || os(tvOS) || os(visionOS)
        switch uiColorName {
        case "secondarySystemBackground":
            self = Color(UIColor.secondarySystemBackground)
        default:
            self = Color(UIColor.systemBackground)
        }
#elseif os(macOS)
        switch uiColorName {
        case "secondarySystemBackground":
            self = Color(NSColor.windowBackgroundColor).opacity(0.92)
        default:
            self = Color(NSColor.textBackgroundColor)
        }
#else
        self = Color(.systemBackground)
#endif
    }
}

private extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    @ViewBuilder
    func hiddenNavigationTitle() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
