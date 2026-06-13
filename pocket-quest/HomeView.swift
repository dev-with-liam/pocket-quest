import SwiftUI

private enum HomeTab: Hashable {
    case home, games, achievements, settings
}

struct HomeView: View {
    @AppStorage("pocketQuestXP") private var xp = 1250
    @AppStorage("pocketQuestDailyChallengeProgress") private var dailyChallengeProgress = 0
    @AppStorage("pocketQuestDailyChallengeClaimed") private var dailyChallengeClaimed = false
    @AppStorage("pocketQuestThemeTextColor") private var themeTextColor = ThemeTextColor.gradientGreenBlue.rawValue
    @AppStorage("pocketQuestThemeBackground") private var themeBackground = ThemeBackground.retroSky.rawValue
    @State private var selectedTab: HomeTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            GameHubHomeScreen(
                xp: $xp,
                dailyChallengeProgress: $dailyChallengeProgress,
                dailyChallengeClaimed: $dailyChallengeClaimed,
                themeTextColor: $themeTextColor,
                themeBackground: $themeBackground,
                selectedTab: $selectedTab
            )
                .tag(HomeTab.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            GamesLibraryScreen(
                xp: $xp,
                dailyChallengeProgress: $dailyChallengeProgress,
                themeTextColor: themeTextColor,
                themeBackground: themeBackground
            )
                .tag(HomeTab.games)
                .tabItem {
                    Label("Games", systemImage: "gamecontroller.fill")
                }

            AchievementsScreen(
                xp: xp,
                dailyChallengeProgress: dailyChallengeProgress,
                dailyChallengeClaimed: dailyChallengeClaimed,
                themeTextColor: themeTextColor,
                themeBackground: themeBackground
            )
                .tag(HomeTab.achievements)
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }

            SettingsScreen(
                xp: $xp,
                dailyChallengeProgress: $dailyChallengeProgress,
                dailyChallengeClaimed: $dailyChallengeClaimed,
                themeTextColor: $themeTextColor,
                themeBackground: $themeBackground
            )
                .tag(HomeTab.settings)
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
    @Binding var themeTextColor: String
    @Binding var themeBackground: String
    @Binding var selectedTab: HomeTab

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
                hubBackground(themeBackground: ThemeBackground(rawValue: themeBackground) ?? .candy)

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        HeroHeader(
                            totalGames: GameOption.allCases.count,
                            xp: xp,
                            featuredGame: filteredGames.first ?? .snackStack,
                            onSettingsTap: { selectedTab = .settings }
                        )
                        LevelProgressCard(xp: xp)
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

                        GameGrid(
                            games: filteredGames,
                            xpStatus: XPStatus(xp: xp)
                        ) { game in
                            awardPlayXP(for: game)
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

    private func awardPlayXP(for game: GameOption) {
        xp += XPStatus(xp: xp).reward(for: game)
        dailyChallengeProgress = min(3, dailyChallengeProgress + 1)
    }
}

private struct GamesLibraryScreen: View {
    @Binding var xp: Int
    @Binding var dailyChallengeProgress: Int
    let themeTextColor: String
    let themeBackground: String

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
                hubBackground(themeBackground: ThemeBackground(rawValue: themeBackground) ?? .candy)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        SectionHeader(title: "Games Library", subtitle: "Browse by category")

                        ForEach(filteredCategories) { category in
                            let categoryGames = games(in: category)

                            VStack(alignment: .leading, spacing: 14) {
                                CategoryTitle(category: category, count: categoryGames.count)
                                GameGrid(
                                    games: categoryGames,
                                    xpStatus: XPStatus(xp: xp)
                                ) { game in
                                    awardPlayXP(for: game)
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

    private func awardPlayXP(for game: GameOption) {
        xp += XPStatus(xp: xp).reward(for: game)
        dailyChallengeProgress = min(3, dailyChallengeProgress + 1)
    }
}

private struct AchievementsScreen: View {
    let xp: Int
    let dailyChallengeProgress: Int
    let dailyChallengeClaimed: Bool
    let themeTextColor: String
    let themeBackground: String

    private var achievements: [AchievementBadge] {
        [
            AchievementBadge(title: "First Quest", subtitle: "Play any game", icon: "sparkles", progress: min(Double(xp) / 25, 1)),
            AchievementBadge(title: "Adventurer", subtitle: "Reach level 5", icon: "arrow.up.circle.fill", progress: min(Double(XPStatus(xp: xp).level) / 5, 1)),
            AchievementBadge(title: "Daily Hero", subtitle: "Finish today’s challenge", icon: "calendar.badge.checkmark", progress: dailyChallengeClaimed ? 1 : Double(dailyChallengeProgress) / 3),
            AchievementBadge(title: "XP Collector", subtitle: "Earn 2,000 XP", icon: "flame.fill", progress: min(Double(xp) / 2_000, 1))
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                hubBackground(themeBackground: ThemeBackground(rawValue: themeBackground) ?? .candy)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SectionHeader(title: "Achievements", subtitle: "Badges, streaks, and milestones")
                        DailyChallengeCard(
                            progress: dailyChallengeProgress,
                            isClaimed: dailyChallengeClaimed,
                            xpReward: XPStatus(xp: xp).dailyReward
                        )

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
    @Binding var themeTextColor: String
    @Binding var themeBackground: String
    @AppStorage("pocketQuestYetiSkin") private var yetiSkin = YetiSkin.artist.rawValue

    @State private var soundEnabled = true
    @State private var animationsEnabled = true
    @State private var dailyReminder = false

    private var xpStatus: XPStatus {
        XPStatus(xp: xp)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                hubBackground(themeBackground: ThemeBackground(rawValue: themeBackground) ?? .candy)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Settings", subtitle: "Tune Pocket Quest for how you play")

                        SettingsGroup {
                            Toggle("Sound Effects", isOn: $soundEnabled)
                            Toggle("Animations", isOn: $animationsEnabled)
                            Toggle("Daily Challenge Reminder", isOn: $dailyReminder)
                        }

                        SettingsGroup {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Theme 🎨")
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(BrandPalette.ink)

                                Text("Choose a font color and background style.")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandPalette.navy.opacity(0.72))

                                Picker("Font Color", selection: $themeTextColor) {
                                    ForEach(ThemeTextColor.allCases) { color in
                                        Text(color.label).tag(color.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)

                                Picker("Background", selection: $themeBackground) {
                                    ForEach(ThemeBackground.allCases) { background in
                                        Text(background.label).tag(background.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        SettingsGroup {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Battle Pass 🏆")
                                        .font(.headline.weight(.heavy))
                                        .foregroundStyle(BrandPalette.ink)

                                    Spacer()

                                    Text("Level \(xpStatus.level)")
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(BrandPalette.paperElevated)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing),
                                            in: Capsule()
                                        )
                                }

                                ProgressView(value: xpStatus.progress)
                                    .tint(.purple)

                                Text("You start at level 1. Artist Yeti is the free skin at level 1, and higher levels unlock new looks.")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandPalette.navy.opacity(0.72))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                                    ForEach(YetiSkin.allCases) { skin in
                                        YetiSkinCard(
                                            skin: skin,
                                            currentLevel: xpStatus.level,
                                            selectedRawValue: $yetiSkin
                                        )
                                    }
                                }
                            }
                        }

                        SettingsGroup {
                            SettingsInfoRow(title: "Player Level ⭐", value: "Level \(xpStatus.level)")
                            SettingsInfoRow(title: "Rank 🏆", value: xpStatus.rankTitle)
                            SettingsInfoRow(title: "XP ✨", value: "\(xp)")
                            SettingsInfoRow(title: "Next Level 🚀", value: "\(xpStatus.remainingXP) XP left")
                            SettingsInfoRow(
                                title: "XP Per Game 🎮",
                                value: "+\(xpStatus.minimumPlayReward)-\(xpStatus.maximumPlayReward)"
                            )
                            SettingsInfoRow(title: "Daily Reward 🎁", value: "+\(xpStatus.dailyReward)")
                            SettingsInfoRow(title: "Games Available 🧩", value: "\(GameOption.allCases.count)")
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
    let xp: Int
    let featuredGame: GameOption
    let onSettingsTap: () -> Void

    private var xpStatus: XPStatus {
        XPStatus(xp: xp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                YetiMascotView(tint: .cyan)
                    .frame(width: 84, height: 84)
                    .padding(8)
                    .background(
                        LinearGradient(
                            colors: [.cyan.opacity(0.28), .blue.opacity(0.20), .purple.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                    )
                    .shadow(color: .cyan.opacity(0.24), radius: 18, y: 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pocket Quest")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(BrandPalette.textGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("Welcome back, \(xpStatus.rankTitle). Pick a quest, earn XP, and keep climbing.")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(BrandPalette.navy.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BrandPalette.paperElevated)
                        .frame(width: 34, height: 34)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Settings")

                VStack(alignment: .trailing, spacing: 8) {
                    Label("Level \(xpStatus.level)", systemImage: "crown.fill")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(BrandPalette.paperElevated)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )

                    Text("\(xpStatus.remainingXP) XP to next level")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BrandPalette.navy.opacity(0.72))
                }
            }

            HStack(spacing: 12) {
                HeroMetric(title: "Games", value: "\(totalGames)", tint: .cyan, icon: "gamecontroller.fill")
                HeroMetric(title: "Level", value: "\(xpStatus.level)", tint: .orange, icon: "crown.fill")
                HeroMetric(title: "XP", value: xp.formatted(), tint: .green, icon: "sparkles")
            }

            HStack(spacing: 12) {
                NavigationLink(value: featuredGame) {
                    Label("Continue Playing", systemImage: "play.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(BrandPalette.paperElevated)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .shadow(color: .blue.opacity(0.26), radius: 10, y: 6)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Featured")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BrandPalette.navy.opacity(0.72))
                    Text(featuredGame.rawValue)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(BrandPalette.textGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)

                Image(systemName: featuredGame.systemImage)
                    .font(.title3.weight(.black))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        featuredGameIconColors(for: featuredGame)[0],
                        featuredGameIconColors(for: featuredGame)[1],
                        featuredGameIconColors(for: featuredGame)[2]
                    )
                    .frame(width: 42, height: 42)
                    .background(BrandPalette.paperElevated.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.22), .orange.opacity(0.18), .cyan.opacity(0.22), .purple.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.20))
                .frame(width: 126, height: 126)
                .offset(x: 44, y: -44)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.30), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 24, y: 12)
    }
}

private struct LevelProgressCard: View {
    let xp: Int

    private var xpStatus: XPStatus {
        XPStatus(xp: xp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(xpStatus.rankTitle, systemImage: "crown.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(BrandPalette.textGradient)

                Spacer()

                Text("Level \(xpStatus.level)")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(BrandPalette.paperElevated)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
            }

            ProgressView(value: xpStatus.progress)
                .tint(.purple)

            HStack(alignment: .firstTextBaseline) {
                Text("\(xpStatus.xpIntoLevel) / \(xpStatus.xpRequiredForNextLevel) XP")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandPalette.navy.opacity(0.72))

                Spacer()

                Text("+\(xpStatus.minimumPlayReward)-\(xpStatus.maximumPlayReward) XP per game")
                    .font(.caption.weight(.black))
                    .foregroundStyle(BrandPalette.tealInk)
            }

            if let nextPerk = xpStatus.nextPerk {
                Label(
                    "Level \(nextPerk.level) unlocks a +\(nextPerk.bonus) XP level bonus",
                    systemImage: "lock.open.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandPalette.navy.opacity(0.72))
            } else {
                Label("Maximum game XP bonus unlocked", systemImage: "star.fill")
                    .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandPalette.navy.opacity(0.72))
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.18), .orange.opacity(0.14), .yellow.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct ProgressStrip: View {
    @Binding var xp: Int
    @Binding var dailyChallengeProgress: Int
    @Binding var dailyChallengeClaimed: Bool

    private var questsRemaining: Int {
        max(0, 3 - dailyChallengeProgress)
    }

    private var xpStatus: XPStatus {
        XPStatus(xp: xp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Daily Challenge", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(BrandPalette.textGradient)

                Spacer()

                Text(dailyChallengeClaimed ? "Reward claimed" : "\(questsRemaining) quests left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandPalette.navy.opacity(0.72))
            }

            ProgressView(value: Double(dailyChallengeProgress), total: 3)
                .tint(.orange)

            HStack {
                Text("Play three quests to earn \(xpStatus.dailyReward) XP.")
                    .font(.footnote)
                    .foregroundStyle(BrandPalette.navy.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button(dailyChallengeClaimed ? "Claimed" : "Claim \(xpStatus.dailyReward) XP") {
                    xp += xpStatus.dailyReward
                    dailyChallengeClaimed = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(dailyChallengeProgress < 3 || dailyChallengeClaimed)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.cyan.opacity(0.18), .blue.opacity(0.16), .purple.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct CategoryPicker: View {
    @Binding var selectedCategory: GameCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    title: "All Games",
                    systemImage: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil,
                    colors: [.pink, .orange]
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedCategory = nil
                    }
                }

                ForEach(GameCategory.allCases) { category in
                    CategoryPill(
                        title: categoryDisplayTitle(for: category),
                        systemImage: category.systemImage,
                        isSelected: selectedCategory == category,
                        colors: categoryChipColors(for: category)
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
    let xpStatus: XPStatus
    let onSelect: (GameOption) -> Void

    var body: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: 18) {
            ForEach(games) { game in
                NavigationLink(value: game) {
                    GameCard(game: game, xpReward: xpStatus.reward(for: game))
                }
                .buttonStyle(PressableCardButtonStyle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        onSelect(game)
                    }
                )
            }
        }
    }
}

private struct GameCard: View {
    let game: GameOption
    let xpReward: Int
    @State private var isHovering = false

    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    GameIcon(game: game)

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    SpotlightBadge(text: spotlightLabel(for: game), colors: spotlightColors(for: game))
                    DifficultyBadge(text: game.difficulty)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(game.rawValue)
                    .font(.title2.weight(.black))
                    .foregroundStyle(BrandPalette.textGradient)
                    .shadow(color: BrandPalette.shadow.opacity(0.22), radius: 0.5, x: 0, y: 1)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)

                Text(game.shortDescription)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandPalette.textGradient)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                Label(game.statLabel, systemImage: "chart.bar.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandPalette.textGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack {
                    Text(categoryDisplayTitle(for: game.category))
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(BrandPalette.textGradient)

                    Spacer()

                    Label("+\(xpReward) XP", systemImage: "sparkles")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(BrandPalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandPalette.paperElevated, in: Capsule())
                }

                HStack(spacing: 10) {
                    Label("Play Now", systemImage: "play.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(BrandPalette.textGradient)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())

                    Spacer(minLength: 0)

                    Text("Tap to start")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BrandPalette.textGradient)
                }
            }
        }
        .padding(18)
        .frame(minHeight: 272)
        .background(
            LinearGradient(
                colors: gradientColors(for: game),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 124, height: 124)
                .offset(x: 42, y: -48)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: shadowColor(for: game).opacity(isHovering ? 0.36 : 0.24), radius: isHovering ? 24 : 18, y: isHovering ? 14 : 10)
        .scaleEffect(isHovering ? 1.03 : 1)
        .offset(y: isHovering ? -3 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.76), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.rawValue), \(game.shortDescription), difficulty \(game.difficulty)")
    }
}

private struct GameIcon: View {
    let game: GameOption

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.30), lineWidth: 1)
                }

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 24, height: 24)
                .offset(x: 18, y: -18)

            Image(systemName: game.systemImage)
                .font(.system(size: 36, weight: .black))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    gameIconColors(for: game)[0],
                    gameIconColors(for: game)[1],
                    gameIconColors(for: game)[2]
                )
        }
        .frame(width: 74, height: 74)
    }
}

private struct DifficultyBadge: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "star.fill")
        .font(.caption2.weight(.black))
        .foregroundStyle(BrandPalette.textGradient)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(BrandPalette.paperElevated.opacity(0.92), in: Capsule())
    }
}

private struct CategoryPill: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .foregroundStyle(isSelected ? BrandPalette.paperElevated : BrandPalette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    isSelected
                    ? LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.white.opacity(0.34), Color.white.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? .white.opacity(0.24) : .white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String
    let tint: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)

            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(BrandPalette.textGradient)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            LinearGradient(colors: [tint.opacity(0.40), .white.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
            VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(BrandPalette.textGradient)

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BrandPalette.navy.opacity(0.72))
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
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    categoryIconColors(for: category)[0],
                    categoryIconColors(for: category)[1],
                    categoryIconColors(for: category)[2]
                )

            Text(categoryDisplayTitle(for: category))
                .font(.headline.weight(.heavy))
                .foregroundStyle(BrandPalette.textGradient)

            Text("\(count)")
                .font(.caption.weight(.black))
                .foregroundStyle(BrandPalette.textGradient)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(BrandPalette.paperElevated.opacity(0.72), in: Capsule())
        }
    }
}

private struct DailyChallengeCard: View {
    let progress: Int
    let isClaimed: Bool
    let xpReward: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Today’s Quest", systemImage: "sun.max.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(BrandPalette.textGradient)

                Spacer()

                Text(isClaimed ? "Claimed" : "+\(xpReward) XP")
                    .font(.caption.weight(.black))
                    .foregroundStyle(BrandPalette.textGradient)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.14), in: Capsule())
            }

            Text("Play three quests to complete today’s challenge.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BrandPalette.navy.opacity(0.72))

            ProgressView(value: Double(progress), total: 3)
                .tint(.orange)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.20), .orange.opacity(0.16), .pink.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
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
                .foregroundStyle(BrandPalette.textGradient)
                .frame(width: 54, height: 54)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(BrandPalette.textGradient)

                Text(achievement.subtitle)
                    .font(.footnote)
                    .foregroundStyle(BrandPalette.navy.opacity(0.72))
            }

            ProgressView(value: achievement.progress)
                .tint(.orange)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.18), .purple.opacity(0.14), .blue.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
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
        .background(
            LinearGradient(
                colors: [.cyan.opacity(0.16), .blue.opacity(0.12), .purple.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(BrandPalette.ink)
            Spacer()
            Text(value)
                .foregroundStyle(BrandPalette.textGradient)
                .fontWeight(.semibold)
        }
    }
}

private struct YetiSkinCard: View {
    let skin: YetiSkin
    let currentLevel: Int
    @Binding var selectedRawValue: String

    private var isUnlocked: Bool {
        skin.isUnlocked(at: currentLevel)
    }

    private var isSelected: Bool {
        selectedRawValue == skin.rawValue
    }

    var body: some View {
        Button {
            guard isUnlocked else { return }
            selectedRawValue = skin.rawValue
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    YetiMascotView(tint: skin.hatColor, skinOverride: skin)
                        .frame(width: 58, height: 58)
                        .padding(6)
                        .background(
                            LinearGradient(colors: skin.bodyGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )

                    Spacer()

                    Image(systemName: isUnlocked ? (isSelected ? "checkmark.seal.fill" : "seal.fill") : "lock.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(
                            isUnlocked
                            ? AnyShapeStyle(BrandPalette.textGradient)
                            : AnyShapeStyle(BrandPalette.navy.opacity(0.56))
                        )
                }

                Text(skin.label)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(BrandPalette.textGradient)
                    .lineLimit(1)

                Text(skin.isFree ? "Free at Level 1" : skin.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandPalette.navy.opacity(0.72))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if isUnlocked {
                    Text(isSelected ? "Equipped" : "Tap to equip")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(BrandPalette.textGradient)
                } else {
                    Text("Unlock at Level \(skin.unlockLevel)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(BrandPalette.navy.opacity(0.72))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
            .background(
                LinearGradient(
                    colors: isUnlocked ? skin.bodyGradient.map { $0.opacity(0.42) } : [BrandPalette.paperElevated, BrandPalette.paper],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? .blue.opacity(0.55) : .white.opacity(0.20), lineWidth: isSelected ? 2 : 1)
            }
            .opacity(isUnlocked ? 1 : 0.72)
        }
        .buttonStyle(.plain)
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
            case .wormArena:
                WormArenaView()
            case .logicPop:
                LogicPopView()
            case .snackStack:
                SnackStackView()
            case .yetiKitchen:
                YetiKitchenView()
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

private func hubBackground(themeBackground: ThemeBackground) -> some View {
    ZStack {
        LinearGradient(
            colors: themeBackground.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        if themeBackground == .retroSky {
            Circle()
                .fill(themeBackground.overlayGlow.opacity(0.85))
                .frame(width: 220, height: 220)
                .blur(radius: 14)
                .offset(x: 110, y: -110)
        }
    }
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
    case .wormArena:
        return [.green, .brown]
    case .logicPop:
        return [.indigo, .cyan]
    case .snackStack:
        return [.pink, .orange]
    case .yetiKitchen:
        return [.pink, .cyan, .yellow]
    }
}

private func featuredGameIconColors(for game: GameOption) -> [Color] {
    gameIconColors(for: game)
}

private func gameIconColors(for game: GameOption) -> [Color] {
    switch game {
    case .ticTacToe:
        return [.white, .blue, .mint]
    case .rockPaperScissors:
        return [.white, .orange, .pink]
    case .coinFlip:
        return [.white, .yellow, .orange]
    case .targetTap:
        return [.white, .pink, .red]
    case .twentyFortyEight:
        return [.white, .green, .teal]
    case .memoryMatch:
        return [.white, .indigo, .purple]
    case .numberGuess:
        return [.white, .teal, .cyan]
    case .reactionTime:
        return [.white, .purple, .pink]
    case .clicksPerSecond:
        return [.white, .red, .orange]
    case .stopTimer:
        return [.white, .blue, .cyan]
    case .colorRush:
        return [.white, .orange, .yellow]
    case .wordle:
        return [.white, .mint, .green]
    case .hangman:
        return [.white, .cyan, .blue]
    case .nimDuel:
        return [.white, .purple, .indigo]
    case .codeBreaker:
        return [.white, .red, .pink]
    case .wormArena:
        return [.white, .green, .mint]
    case .logicPop:
        return [.white, .indigo, .blue]
    case .snackStack:
        return [.white, .pink, .orange]
    case .yetiKitchen:
        return [.white, .orange, .yellow]
    }
}

private func categoryIconColors(for category: GameCategory) -> [Color] {
    switch category {
    case .arcade:
        return [.white, .pink, .orange]
    case .puzzle:
        return [.white, .mint, .teal]
    case .strategy:
        return [.white, .indigo, .purple]
    case .reaction:
        return [.white, .yellow, .orange]
    }
}

private func shadowColor(for game: GameOption) -> Color {
    gradientColors(for: game).first ?? .black
}

private func categoryDisplayTitle(for category: GameCategory) -> String {
    switch category {
    case .arcade:
        return "Arcade"
    case .puzzle:
        return "Brain Games"
    case .strategy:
        return "Challenges"
    case .reaction:
        return "Fast Reflexes"
    }
}

private func categoryChipColors(for category: GameCategory) -> [Color] {
    switch category {
    case .arcade:
        return [.pink, .orange]
    case .puzzle:
        return [.mint, .green]
    case .strategy:
        return [.purple, .indigo]
    case .reaction:
        return [.cyan, .blue]
    }
}

private func spotlightLabel(for game: GameOption) -> String {
    switch game {
    case .yetiKitchen, .snackStack:
        return "NEW"
    case .reactionTime, .clicksPerSecond, .targetTap:
        return "FAST"
    case .wordle, .hangman, .logicPop, .codeBreaker:
        return "BRAIN"
    case .coinFlip:
        return "LUCK"
    default:
        return "PLAY"
    }
}

private func spotlightColors(for game: GameOption) -> [Color] {
    switch game {
    case .yetiKitchen, .snackStack:
        return [.pink, .orange]
    case .reactionTime, .clicksPerSecond, .targetTap:
        return [.cyan, .blue]
    case .wordle, .hangman, .logicPop, .codeBreaker:
        return [.purple, .indigo]
    case .coinFlip:
        return [.yellow, .orange]
    default:
        return [.green, .teal]
    }
}

private struct SpotlightBadge: View {
    let text: String
    let colors: [Color]

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(BrandPalette.paperElevated)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
    }
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
