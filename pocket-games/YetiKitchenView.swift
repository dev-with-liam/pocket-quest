import SwiftUI

struct YetiKitchenView: View {
    @StateObject private var viewModel = YetiKitchenViewModel()
    @State private var showAdvanceTask: Task<Void, Never>?

    private let rainbowColors: [Color] = [.pink, .orange, .yellow, .mint, .cyan]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: rainbowColors.map { $0.opacity(0.16) } + [.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    mascotCard
                    statsRow

                    switch viewModel.phase {
                    case .intro:
                        introCard
                    case .cookingShow:
                        showCard
                    case .recall:
                        recallCard
                    case .results:
                        resultsCard
                    }
                }
                .frame(maxWidth: 680)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
        .onDisappear {
            showAdvanceTask?.cancel()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "frying.pan.fill")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: rainbowColors, startPoint: .leading, endPoint: .trailing)
                )

            Text("Yeti's Kitchen")
                .font(.system(.largeTitle, design: .rounded, weight: .black))

            Text("Watch the cooking show, then remember the ingredients in order.")
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
        }
    }

    private var mascotCard: some View {
        HStack(alignment: .center, spacing: 14) {
            RainbowChefYetiView()
                .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 6) {
                Text("Chef Yeti says")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.pink)

                Text(viewModel.currentSpeech)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandPalette.textGradient)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.14), .cyan.opacity(0.10), Color.white.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.pink.opacity(0.22), lineWidth: 1)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            KitchenStatTile(title: "Score", value: viewModel.score, tint: .pink)
            KitchenStatTile(title: "Streak", value: viewModel.bestStreak, tint: .orange)
            KitchenStatTile(title: "Mastered", value: viewModel.recipesMastered, tint: .mint)
            KitchenStatTile(title: "Rounds", value: viewModel.rounds, tint: .cyan)
        }
    }

    private var introCard: some View {
        VStack(spacing: 18) {
            RainbowChefYetiView()
                .frame(width: 120, height: 120)

            if let recipe = viewModel.currentRecipe {
                Text(recipe.title)
                    .font(.title2.weight(.black))
            }

            Text("Chef Yeti will show you a kid-friendly recipe one ingredient at a time. When the show ends, tap each ingredient back in the same order.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)

            if !viewModel.unlockedFourIngredientRecipes {
                Label(
                    "\(viewModel.perfectRoundsToUnlockFourIngredients - viewModel.perfectRounds) perfect rounds until 4-ingredient recipes unlock",
                    systemImage: "lock.open.fill"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
            }

            Button("Start Cooking Show") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    viewModel.startShow()
                    scheduleShowAdvance()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var showCard: some View {
        VStack(spacing: 18) {
            if let recipe = viewModel.currentRecipe {
                Text(recipe.title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.pink)

                progressDots(total: recipe.ingredients.count, current: viewModel.showIndex + 1)

                if let ingredient = viewModel.currentShowIngredient {
                    ingredientCard(
                        ingredient,
                        slot: viewModel.showIndex + 1,
                        total: recipe.ingredients.count
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                Button("Next Ingredient") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        showAdvanceTask?.cancel()
                        viewModel.advanceShow()
                        if viewModel.phase == .cookingShow {
                            scheduleShowAdvance()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            scheduleShowAdvance()
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase != .cookingShow {
                showAdvanceTask?.cancel()
            }
        }
    }

    private var recallCard: some View {
        VStack(spacing: 18) {
            Text("What did we add, in order?")
                .font(.title3.weight(.black))

            if viewModel.playerSelections.isEmpty {
                Button("Replay Show") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        viewModel.replayShow()
                        scheduleShowAdvance()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
            }

            numberedSlots

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                ForEach(viewModel.pantryItems) { ingredient in
                    pantryButton(ingredient)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var resultsCard: some View {
        VStack(spacing: 18) {
            Image(systemName: viewModel.isPerfectRound ? "star.circle.fill" : "fork.knife.circle")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(viewModel.isPerfectRound ? .yellow : .pink)

            Text(viewModel.isPerfectRound ? "Perfect Recipe!" : "Keep Practicing!")
                .font(.title.weight(.black))

            if let recipe = viewModel.currentRecipe {
            Text("You got \(viewModel.score) of \(recipe.ingredients.count) in the right order.")
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Correct order:")
                        .font(.caption.weight(.black))
                        .foregroundStyle(BrandPalette.textGradient)

                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        resultRow(
                            number: index + 1,
                            ingredient: ingredient,
                            playerPick: viewModel.playerSelections.indices.contains(index)
                                ? viewModel.playerSelections[index]
                                : nil,
                            failedHere: viewModel.failedAtIndex == index
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button("Cook Again") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        viewModel.replayShow()
                        scheduleShowAdvance()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                Button("Next Recipe") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        viewModel.startNewRound()
                        scheduleShowAdvance()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var numberedSlots: some View {
        HStack(spacing: 10) {
            ForEach(0..<max(viewModel.maxScore, 1), id: \.self) { index in
                VStack(spacing: 6) {
                    Text("\(index + 1)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(BrandPalette.textGradient)

                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(slotBackground(for: index))
                            .frame(width: 64, height: 64)

                        if viewModel.playerSelections.indices.contains(index) {
                            Text(viewModel.playerSelections[index].emoji)
                                .font(.system(size: 28))
                        }
                    }
                }
            }
        }
    }

    private func slotBackground(for index: Int) -> Color {
        if viewModel.failedAtIndex == index {
            return .red.opacity(0.22)
        }
        if viewModel.playerSelections.indices.contains(index) {
            return .green.opacity(0.25)
        }
        return .primary.opacity(0.06)
    }

    private func pantryButton(_ ingredient: RecipeIngredient) -> some View {
        let isUsed = viewModel.playerSelections.contains(where: { $0.id == ingredient.id })
        let isDisabled = viewModel.failedAtIndex != nil
            || viewModel.isRecallComplete
            || isUsed

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                viewModel.selectIngredient(ingredient)
            }
        } label: {
            VStack(spacing: 6) {
                Text(ingredient.emoji)
                    .font(.system(size: 32))
                Text(ingredient.name)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(8)
            .background(
                isUsed ? Color.primary.opacity(0.05) : Color.pink.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isUsed ? Color.clear : Color.pink.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isUsed ? 0.45 : 1)
        .accessibilityLabel("\(ingredient.name), pantry item")
    }

    private func ingredientCard(_ ingredient: RecipeIngredient, slot: Int, total: Int) -> some View {
        VStack(spacing: 10) {
            Text(ingredient.emoji)
                .font(.system(size: 72))

            Text(ingredient.name)
                .font(.title2.weight(.black))
                .foregroundStyle(BrandPalette.textGradient)

            Text("Ingredient \(slot) of \(total)")
                .font(.caption.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(16)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.18), .orange.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .accessibilityLabel("\(ingredient.name), ingredient \(slot) of \(total)")
    }

    private func resultRow(
        number: Int,
        ingredient: RecipeIngredient,
        playerPick: RecipeIngredient?,
        failedHere: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Text("\(number).")
                .font(.caption.weight(.black))
                .frame(width: 20, alignment: .leading)

            Text(ingredient.emoji)
            Text(ingredient.name)
                .font(.subheadline.weight(.semibold))

            Spacer()

            if let playerPick {
                let isCorrect = playerPick.id == ingredient.id && !failedHere
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
            } else if failedHere {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func progressDots(total: Int, current: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < current ? Color.pink : Color.primary.opacity(0.15))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private func scheduleShowAdvance() {
        showAdvanceTask?.cancel()
        guard viewModel.phase == .cookingShow else { return }

        showAdvanceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(viewModel.showIngredientDuration))
            guard !Task.isCancelled, viewModel.phase == .cookingShow else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                viewModel.advanceShow()
                if viewModel.phase == .cookingShow {
                    scheduleShowAdvance()
                }
            }
        }
    }
}

struct RainbowChefYetiView: View {
    private let rainbowColors: [Color] = [.pink, .orange, .yellow, .green, .cyan, .purple]

    var body: some View {
        ZStack {
            YetiMascotView(tint: .pink)

            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 54, height: 10)
                    .offset(y: -42)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(red: 0.92, green: 0.94, blue: 0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 38, height: 22)
                    .offset(y: -52)
            }

            HStack(spacing: 22) {
                Capsule()
                    .fill(
                        LinearGradient(colors: rainbowColors, startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 18, height: 22)
                Capsule()
                    .fill(
                        LinearGradient(colors: rainbowColors.reversed(), startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 18, height: 22)
            }
            .offset(y: 35)
        }
    }
}

private struct KitchenStatTile: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)
            Text(value, format: .number)
                .font(.title3.weight(.black))
                .foregroundStyle(BrandPalette.textGradient)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
