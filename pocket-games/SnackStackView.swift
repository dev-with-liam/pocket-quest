import SwiftUI

struct SnackStackView: View {
    @StateObject private var viewModel = SnackStackViewModel()
    @State private var isShowingInstructions = false

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: viewModel.columns)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pink.opacity(0.2), .orange.opacity(0.17), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    GameMascotCard(hint: GameOption.snackStack.mascotHint, tint: .pink)
                    stats
                    progress
                    board
                    controls
                }
                .frame(maxWidth: 720)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $isShowingInstructions) {
            SnackStackInstructionsView(
                targetScore: viewModel.targetScore,
                startingMoves: viewModel.startingMoves
            )
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("🍿 Snack Stack 🥨")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
            Text(viewModel.message)
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            SnackStatTile(title: "Score", value: viewModel.score, tint: .pink)
            SnackStatTile(title: "Best", value: viewModel.bestScore, tint: .purple)
            SnackStatTile(title: "Moves", value: viewModel.movesRemaining, tint: .orange)
            SnackStatTile(title: "Wins", value: viewModel.wins, tint: .green)
        }
    }

    private var progress: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Target")
                Spacer()
                Text("\(viewModel.score) / \(viewModel.targetScore)")
            }
            .font(.caption.weight(.black))

            ProgressView(
                value: Double(min(viewModel.score, viewModel.targetScore)),
                total: Double(viewModel.targetScore)
            )
            .tint(.pink)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.18), .orange.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var board: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.board.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                        viewModel.selectSnack(at: index)
                    }
                } label: {
                    Text(viewModel.board[index].symbol)
                        .font(.system(size: 48))
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            viewModel.selectedIndex == index
                                ? Color.yellow.opacity(0.72)
                                : Color.white.opacity(0.72),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    viewModel.selectedIndex == index ? Color.orange : Color.pink.opacity(0.22),
                                    lineWidth: viewModel.selectedIndex == index ? 4 : 1
                                )
                        }
                        .shadow(color: .pink.opacity(0.12), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.phase != .playing)
                .accessibilityLabel(
                    "\(viewModel.board[index].rawValue), row \(index / viewModel.columns + 1), column \(index % viewModel.columns + 1)"
                )
            }
        }
        .padding(12)
        .frame(maxWidth: 440)
        .background(
            LinearGradient(
                colors: [.pink.opacity(0.16), .orange.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            if viewModel.phase != .playing {
                endOverlay
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                isShowingInstructions = true
            } label: {
                Label("Instruction Book", systemImage: "book.closed.fill")
            }
            .buttonStyle(.bordered)

            Button("New Snack Stack") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    viewModel.startNewRound()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .controlSize(.large)
    }

    private var endOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.phase == .won ? "star.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 48, weight: .black))
            Text(viewModel.phase == .won ? "Stack Cleared!" : "Out of Moves")
                .font(.title2.weight(.black))
            Text("Final score: \(viewModel.score)")
                .font(.headline)
            Button("Play Again") {
                viewModel.startNewRound()
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .foregroundStyle(BrandPalette.textGradient)
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(30)
    }
}

private struct SnackStackInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    let targetScore: Int
    let startingMoves: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    instruction(
                        title: "Goal",
                        icon: "flag.checkered",
                        text: "Score \(targetScore.formatted()) points before your \(startingMoves) moves run out."
                    )
                    instruction(
                        title: "Swap Snacks",
                        icon: "arrow.left.arrow.right",
                        text: "Tap a snack, then tap one directly above, below, left, or right. A swap that makes no match is undone and does not use a move."
                    )
                    instruction(
                        title: "Make Matches",
                        icon: "square.grid.3x3.fill",
                        text: "Line up three or more identical snacks horizontally or vertically. Matching snacks disappear and new snacks fall into place."
                    )
                    instruction(
                        title: "Build Cascades",
                        icon: "sparkles",
                        text: "Falling snacks can make automatic follow-up matches. Each cascade increases the score multiplier."
                    )
                    instruction(
                        title: "Scoring",
                        icon: "star.fill",
                        text: "Each cleared snack is worth 50 points multiplied by the cascade number."
                    )
                    instruction(
                        title: "Winning",
                        icon: "trophy.fill",
                        text: "Reach the target score to win. The round is lost if your moves reach zero first."
                    )
                }
                .padding(24)
            }
            .navigationTitle("How to Play")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 520)
    }

    private func instruction(title: String, icon: String, text: String) -> some View {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .foregroundStyle(BrandPalette.textGradient)
            }
        }
    }
}

private struct SnackStatTile: View {
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
        .background(
            LinearGradient(
                colors: [tint.opacity(0.18), Color.white.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}
