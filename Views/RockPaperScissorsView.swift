import SwiftUI

struct RockPaperScissorsView: View {
    @StateObject private var viewModel = RockPaperScissorsViewModel()
    @FocusState private var isKeyboardFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.secondary.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    scoreboard
                    moveChoices
                    roundSummary
                    controls
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .focusable()
        .focused($isKeyboardFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isKeyboardFocused = true
        }
        .onAppear {
            isKeyboardFocused = true
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "rRpPsS")) { keyPress in
            handleKeyPress(keyPress)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Rock Paper Scissors")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)
        }
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            RPSScoreTile(title: "Player", value: viewModel.score.playerWins, tint: .blue)
            RPSScoreTile(title: "Computer", value: viewModel.score.computerWins, tint: .orange)
            RPSScoreTile(title: "Draws", value: viewModel.score.draws, tint: .green)
        }
        .frame(maxWidth: 520)
    }

    private var moveChoices: some View {
        HStack(spacing: 10) {
            ForEach(RockPaperScissorsMove.allCases) { move in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        viewModel.play(move)
                    }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: move.symbol)
                            .font(.system(size: 34, weight: .bold))
                            .frame(height: 42)

                        Text(move.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.vertical, 16)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(move.rawValue)
            }
        }
        .frame(maxWidth: 520)
    }

    private var roundSummary: some View {
        HStack(spacing: 12) {
            RPSMoveTile(title: "You", move: viewModel.playerMove, tint: .blue)

            Image(systemName: "arrow.left.arrow.right")
                .font(.title3.weight(.bold))
                .foregroundStyle(.secondary)

            RPSMoveTile(title: "Computer", move: viewModel.computerMove, tint: .orange)
        }
        .frame(maxWidth: 520)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    viewModel.startNewRound()
                }
            } label: {
                Label("New Round", systemImage: "arrow.clockwise")
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

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        switch keyPress.characters.lowercased() {
        case "r":
            viewModel.play(.rock)
        case "p":
            viewModel.play(.paper)
        case "s":
            viewModel.play(.scissors)
        default:
            return .ignored
        }

        return .handled
    }
}

private struct RPSMoveTile: View {
    let title: String
    let move: RockPaperScissorsMove?
    let tint: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Image(systemName: move?.symbol ?? "questionmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(move == nil ? Color.secondary : tint)
                .frame(height: 42)

            Text(move?.rawValue ?? "Waiting")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RPSScoreTile: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct RockPaperScissorsView_Previews: PreviewProvider {
    static var previews: some View {
        RockPaperScissorsView()
    }
}
