import SwiftUI

struct HangmanView: View {
    @StateObject private var viewModel = HangmanViewModel()
    @FocusState private var isKeyboardFocused: Bool

    private let keyboardRows = ["ABCDEFG", "HIJKLMN", "OPQRSTU", "VWXYZ"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.48, green: 0.86, blue: 0.82),
                    Color(red: 0.92, green: 0.65, blue: 0.94),
                    Color(red: 0.99, green: 0.77, blue: 0.44)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    GameMascotCard(hint: GameOption.hangman.mascotHint, tint: .cyan)
                    scoreRow
                    hangmanFigure
                    wordDisplay
                    misses
                    keyboard
                    newGameButton
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
        .onKeyPress(characters: .letters) { keyPress in
            handleLetterKeyPress(keyPress)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Hangman")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)
        }
    }

    private var scoreRow: some View {
        HStack(spacing: 10) {
            WordGameStatTile(title: "Wins", value: viewModel.wins, tint: .green)
            WordGameStatTile(title: "Losses", value: viewModel.losses, tint: .red)
        }
        .frame(maxWidth: 420)
    }

    private var hangmanFigure: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.cyan.opacity(0.22))

            VStack(spacing: 8) {
                Image(systemName: figureImage)
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(figureColor)
                    .symbolRenderingMode(.hierarchical)

                HStack(spacing: 6) {
                    ForEach(0..<viewModel.maxWrongGuesses, id: \.self) { index in
                        Capsule()
                            .fill(index < viewModel.wrongGuesses.count ? Color.red : Color.primary.opacity(0.12))
                            .frame(width: 24, height: 8)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: 360)
        .frame(height: 180)
    }

    private var wordDisplay: some View {
        Text(viewModel.displayWord)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .lineLimit(2)
            .minimumScaleFactor(0.55)
            .multilineTextAlignment(.center)
            .tracking(4)
            .frame(maxWidth: 520)
            .padding(.vertical, 6)
    }

    private var misses: some View {
            Text("Misses: \(viewModel.wrongGuesses.map(String.init).joined(separator: " "))")
                .font(.headline)
            .foregroundStyle(BrandPalette.textGradient)
            .frame(minHeight: 24)
    }

    private var keyboard: some View {
        VStack(spacing: 8) {
            ForEach(keyboardRows, id: \.self) { row in
                HStack(spacing: 7) {
                    ForEach(Array(row), id: \.self) { letter in
                        letterButton(letter)
                    }
                }
            }
        }
        .frame(maxWidth: 520)
    }

    private var newGameButton: some View {
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
        .frame(maxWidth: 320)
    }

    private var figureImage: String {
        switch viewModel.gameState {
        case .playing:
            return "figure.stand"
        case .won:
            return "checkmark.circle.fill"
        case .lost:
            return "xmark.circle.fill"
        }
    }

    private var figureColor: Color {
        switch viewModel.gameState {
        case .playing:
            return .cyan
        case .won:
            return .green
        case .lost:
            return .red
        }
    }

    private func keyColor(for letter: Character) -> Color {
        guard viewModel.guessedLetters.contains(letter) else {
            return Color.primary.opacity(0.10)
        }

        return viewModel.wordText.contains(letter) ? .green : .red
    }

    private func keyForegroundColor(for letter: Character) -> Color {
        viewModel.guessedLetters.contains(letter) ? .white : .primary
    }

    private func letterButton(_ letter: Character) -> some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                viewModel.guess(letter)
            }
        } label: {
            Text(String(letter))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .background(keyColor(for: letter), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(keyForegroundColor(for: letter))
        .disabled(viewModel.guessedLetters.contains(letter) || viewModel.gameState != .playing)
        .accessibilityLabel(String(letter))
    }

    private func handleLetterKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard let character = keyPress.characters.uppercased().first, character.isLetter else {
            return .ignored
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            viewModel.guess(character)
        }

        return .handled
    }
}

struct HangmanView_Previews: PreviewProvider {
    static var previews: some View {
        HangmanView()
    }
}
