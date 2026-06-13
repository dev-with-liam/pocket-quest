import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @FocusState private var isBoardFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.98, blue: 0.94)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    GameMascotCard(hint: GameOption.ticTacToe.mascotHint, tint: .blue)
                    scoreboard
                    difficultyPicker
                    board
                    controls
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.isShowingGameOverAlert) {
            Button("New Game") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.startNewGame()
                }
            }
            Button("Keep Score", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .focusable()
        .focused($isBoardFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isBoardFocused = true
        }
        .onAppear {
            isBoardFocused = true
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "123456789")) { keyPress in
            handleNumberKeyPress(keyPress)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Tic-Tac-Toe")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(BrandPalette.textGradient)

            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)
        }
        .multilineTextAlignment(.center)
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            ScoreTile(title: "Player", value: viewModel.score.playerWins, tint: .blue)
            ScoreTile(title: "Computer", value: viewModel.score.computerWins, tint: .orange)
            ScoreTile(title: "Draws", value: viewModel.score.draws, tint: .green)
        }
        .frame(maxWidth: 520)
    }

    private var difficultyPicker: some View {
        VStack(spacing: 8) {
            Picker("Difficulty", selection: $viewModel.difficulty) {
                ForEach(GameDifficulty.allCases) { difficulty in
                    Text(difficulty.rawValue).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isComputerThinking)

            Text(viewModel.difficulty.description)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.textGradient)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.difficulty)
        }
        .frame(maxWidth: 360)
        .accessibilityElement(children: .combine)
    }

    private var board: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<9) { index in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        viewModel.playHumanMove(at: index)
                    }
                } label: {
                    BoardSquare(
                        move: viewModel.board[index],
                        isWinningSquare: viewModel.winningLine.contains(index)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.board[index] != nil || viewModel.gameState.isFinished || viewModel.isComputerThinking)
                .accessibilityLabel(accessibilityLabel(for: index))
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(red: 0.96, green: 1.0, blue: 0.96), Color(red: 0.86, green: 0.98, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .frame(maxWidth: 520)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    viewModel.startNewGame()
                }
            } label: {
                Label("New Game", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.resetScores()
                }
            } label: {
                Label("Reset Scores", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: 320)
    }

    private func accessibilityLabel(for index: Int) -> String {
        if let move = viewModel.board[index] {
            return "Square \(index + 1), \(move.player.accessibilityLabel)"
        }

        return "Square \(index + 1), empty"
    }

    private func handleNumberKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard let number = Int(keyPress.characters), (1...9).contains(number) else {
            return .ignored
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
            viewModel.playHumanMove(at: number - 1)
        }

        return .handled
    }
}

private struct BoardSquare: View {
    let move: Move?
    let isWinningSquare: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isWinningSquare ? Color.green.opacity(0.2) : Color.primary.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isWinningSquare ? Color.green : Color.secondary.opacity(0.25), lineWidth: isWinningSquare ? 3 : 1)
                }

            if let move {
                Text(move.player.rawValue)
                    .font(.system(size: 68, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.55)
                    .foregroundStyle(move.player == .human ? Color.green : Color.green.opacity(0.72))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ScoreTile: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.textGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.95, green: 1.0, blue: 0.95), Color(red: 0.87, green: 0.98, blue: 0.89)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
