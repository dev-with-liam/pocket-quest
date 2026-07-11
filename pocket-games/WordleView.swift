import SwiftUI
#if os(macOS)
import AppKit
#endif

struct WordleView: View {
    @StateObject private var viewModel = WordleViewModel()
    @FocusState private var isKeyboardFocused: Bool

    private let keyboardRows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    private let boardColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.58, green: 0.90, blue: 0.76),
                    Color(red: 0.39, green: 0.72, blue: 0.98),
                    Color(red: 0.98, green: 0.64, blue: 0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    GameMascotCard(hint: GameOption.wordle.mascotHint, tint: .mint)
                    scoreRow
                    board
                    answerReveal
                    keyboard
                    newGameButton
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .wordleMacKeyCapture { input in
            handleKeyboardInput(input)
        }
        .focusable()
        .focused($isKeyboardFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isKeyboardFocused = true
        }
        .onAppear {
            isKeyboardFocused = true
            wordleDebugLog("WordleView appeared; keyboard focus requested")
        }
#if !os(macOS)
        .onKeyPress(phases: .down) { keyPress in
            wordleDebugLog("SwiftUI onKeyPress key=\(keyPress.key), characters='\(keyPress.characters)'")
            handleKeyPress(keyPress)
        }
#endif
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Guess the Word")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text(viewModel.message)
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.message)
        }
    }

    private var scoreRow: some View {
        HStack(spacing: 10) {
            WordGameStatTile(title: "Wins", value: viewModel.wins, tint: .green)
            WordGameStatTile(title: "Losses", value: viewModel.losses, tint: .red)
        }
        .frame(maxWidth: 420)
    }

    private var board: some View {
        VStack(spacing: 8) {
            ForEach(Array(viewModel.rows.enumerated()), id: \.offset) { rowIndex, guess in
                LazyVGrid(columns: boardColumns, spacing: 8) {
                    ForEach(0..<viewModel.wordLength, id: \.self) { column in
                        WordleCell(
                            letter: letter(in: guess, at: column),
                            evaluation: evaluation(for: guess, rowIndex: rowIndex, column: column),
                            isSubmitted: rowIndex < viewModel.guesses.count
                        )
                    }
                }
            }
        }
        .frame(maxWidth: 360)
    }

    @ViewBuilder
    private var answerReveal: some View {
        if viewModel.isShowingAnswer {
            HStack(spacing: 8) {
                Text("Word")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandPalette.textGradient)

                Text(viewModel.answerText)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(BrandPalette.textGradient)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.mint.opacity(0.20), .cyan.opacity(0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var keyboard: some View {
        VStack(spacing: 8) {
            ForEach(keyboardRows, id: \.self) { row in
                HStack(spacing: 6) {
                    if row == "ZXCVBNM" {
                        keyboardActionButton("Enter", width: 64) {
                            submitGuess()
                        }
                        .keyboardShortcut(.return, modifiers: [])
                    }

                    ForEach(Array(row), id: \.self) { letter in
                        letterButton(letter)
                    }

                    if row == "ZXCVBNM" {
                        keyboardActionButton("⌫", width: 48) {
                            deleteLetter()
                        }
                        .keyboardShortcut(.delete, modifiers: [])
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

    private func keyboardActionButton(_ title: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .frame(width: width, height: 44)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .background(
                    LinearGradient(
                        colors: [.mint.opacity(0.20), .blue.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(BrandPalette.textGradient)
        .accessibilityLabel(title == "⌫" ? "Delete" : title)
    }

    private func letterButton(_ letter: Character) -> some View {
        Button {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.82)) {
                viewModel.enter(letter)
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
        .accessibilityLabel(String(letter))
    }

    private func letter(in guess: String, at index: Int) -> String {
        let letters = Array(guess)
        guard index < letters.count else { return "" }
        return String(letters[index])
    }

    private func evaluation(for guess: String, rowIndex: Int, column: Int) -> LetterEvaluation? {
        guard rowIndex < viewModel.guesses.count else { return nil }
        let evaluations = viewModel.evaluation(for: guess)
        guard column < evaluations.count else { return nil }
        return evaluations[column]
    }

    private func keyColor(for letter: Character) -> Color {
        guard let evaluation = viewModel.keyboardEvaluation(for: letter) else {
            return Color.mint.opacity(0.18)
        }

        return color(for: evaluation)
    }

    private func keyForegroundColor(for letter: Character) -> Color {
        Color(red: 0.08, green: 0.60, blue: 0.30)
    }

    private func color(for evaluation: LetterEvaluation) -> Color {
        switch evaluation {
        case .absent:
            return .secondary
        case .present:
            return .orange
        case .correct:
            return .green
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        if isReturnCharacter(keyPress.characters) || keyPress.key == .return {
            handleKeyboardInput(.submit)
            return .handled
        }

        if keyPress.key == .delete || keyPress.key == .deleteForward || isDeleteCharacter(keyPress.characters) {
            handleKeyboardInput(.delete)
            return .handled
        }

        guard let character = keyPress.characters.uppercased().first, character.isLetter else {
            return .ignored
        }

        handleKeyboardInput(.letter(character))

        return .handled
    }

    private func handleKeyboardInput(_ input: WordleKeyboardInput) {
        wordleDebugLog("handleKeyboardInput \(input.debugDescription)")

        switch input {
        case .submit:
            submitGuess()
        case .delete:
            deleteLetter()
        case .letter(let character):
            withAnimation(.spring(response: 0.18, dampingFraction: 0.82)) {
                viewModel.enter(character)
            }
        }
    }

    private func submitGuess() {
        isKeyboardFocused = true
        wordleDebugLog("submitGuess called; currentGuess='\(viewModel.currentGuess)'")

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            viewModel.submitGuess()
        }
    }

    private func deleteLetter() {
        isKeyboardFocused = true
        wordleDebugLog("deleteLetter called; currentGuess before delete='\(viewModel.currentGuess)'")
        viewModel.deleteLetter()
    }

    private func isDeleteCharacter(_ characters: String) -> Bool {
        characters.unicodeScalars.contains { scalar in
            scalar.value == 8 || scalar.value == 127
        }
    }

    private func isReturnCharacter(_ characters: String) -> Bool {
        characters.unicodeScalars.contains { scalar in
            scalar.value == 10 || scalar.value == 13
        }
    }
}

private enum WordleKeyboardInput {
    case submit
    case delete
    case letter(Character)

    var debugDescription: String {
        switch self {
        case .submit:
            return "submit"
        case .delete:
            return "delete"
        case .letter(let character):
            return "letter(\(character))"
        }
    }
}

private func wordleDebugLog(_ message: String) {
#if DEBUG
    print("[WordleDebug] \(message)")
#endif
}

private struct WordleCell: View {
    let letter: String
    let evaluation: LetterEvaluation?
    let isSubmitted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 2)
                }

            Text(letter)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(foregroundColor)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: letter)
    }

    private var backgroundColor: Color {
        guard let evaluation else {
            return Color.primary.opacity(isSubmitted ? 0.08 : 0.03)
        }

        switch evaluation {
        case .absent:
            return .secondary
        case .present:
            return .orange
        case .correct:
            return .green
        }
    }

    private var borderColor: Color {
        letter.isEmpty ? Color.secondary.opacity(0.24) : Color.secondary.opacity(0.45)
    }

    private var foregroundColor: Color {
        Color(red: 0.08, green: 0.60, blue: 0.30)
    }
}

struct WordGameStatTile: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.textGradient)

            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.20), Color.white.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}

struct WordleView_Previews: PreviewProvider {
    static var previews: some View {
        WordleView()
    }
}

private extension View {
    @ViewBuilder
    func wordleMacKeyCapture(_ onInput: @escaping (WordleKeyboardInput) -> Void) -> some View {
#if os(macOS)
        background {
            WordleMacKeyCaptureView(onInput: onInput)
                .frame(width: 0, height: 0)
        }
#else
        self
#endif
    }
}

#if os(macOS)
private struct WordleMacKeyCaptureView: NSViewRepresentable {
    let onInput: (WordleKeyboardInput) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onInput: onInput)
    }

    func makeNSView(context: Context) -> NSView {
        wordleDebugLog("WordleMacKeyCaptureView makeNSView")
        context.coordinator.startMonitoring()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        wordleDebugLog("WordleMacKeyCaptureView updateNSView")
        context.coordinator.onInput = onInput
        context.coordinator.startMonitoring()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        wordleDebugLog("WordleMacKeyCaptureView dismantleNSView")
        coordinator.stopMonitoring()
    }

    final class Coordinator {
        var onInput: (WordleKeyboardInput) -> Void
        private var monitor: Any?

        init(onInput: @escaping (WordleKeyboardInput) -> Void) {
            self.onInput = onInput
        }

        func startMonitoring() {
            guard monitor == nil else { return }

            wordleDebugLog("Starting macOS local key monitor")
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                return self.handle(event) ? nil : event
            }
        }

        func stopMonitoring() {
            if let monitor {
                wordleDebugLog("Stopping macOS local key monitor")
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        private func handle(_ event: NSEvent) -> Bool {
            wordleDebugLog(
                "NSEvent keyDown keyCode=\(event.keyCode), characters='\(event.characters ?? "")', ignoringModifiers='\(event.charactersIgnoringModifiers ?? "")', modifiers=\(event.modifierFlags.rawValue)"
            )

            let modifiers = event.modifierFlags.intersection([.command, .control, .option])
            guard modifiers.isEmpty else {
                wordleDebugLog("Ignoring modified keyDown")
                return false
            }

            switch event.keyCode {
            case 36, 76:
                wordleDebugLog("Routing keyCode \(event.keyCode) to submit")
                onInput(.submit)
                return true
            case 51, 117:
                wordleDebugLog("Routing keyCode \(event.keyCode) to delete")
                onInput(.delete)
                return true
            default:
                break
            }

            guard let character = event.charactersIgnoringModifiers?.uppercased().first,
                  character.isLetter else {
                wordleDebugLog("Ignoring non-letter keyDown")
                return false
            }

            wordleDebugLog("Routing character \(character) to letter input")
            onInput(.letter(character))
            return true
        }

        deinit {
            stopMonitoring()
        }
    }
}
#endif
