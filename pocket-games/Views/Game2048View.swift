import SwiftUI

struct Game2048View: View {
    @StateObject private var viewModel = Game2048ViewModel()
    @State private var boardOffset: CGSize = .zero
    @FocusState private var isBoardFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.secondary.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    scoreRow
                    board
                    newGameButton
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("2048")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)
        }
    }

    private var scoreRow: some View {
        HStack(spacing: 10) {
            Score2048Tile(title: "Score", value: viewModel.score, tint: .green)
            Score2048Tile(title: "Best", value: viewModel.bestScore, tint: .blue)
        }
        .frame(maxWidth: 420)
    }

    private var board: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<16) { index in
                Tile2048View(tile: viewModel.board[index])
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(maxWidth: 420)
        .offset(boardOffset)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    handleSwipe(value.translation)
                }
        )
        .focusable()
        .focused($isBoardFocused)
        .onTapGesture {
            isBoardFocused = true
        }
        .onAppear {
            isBoardFocused = true
        }
        .onKeyPress(.upArrow) {
            move(.up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            move(.down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            move(.left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            move(.right)
            return .handled
        }
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

    private func move(_ direction: MoveDirection) {
        var didMove = false

        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            didMove = viewModel.move(direction)
        }

        if didMove {
            animateBoardMove(direction)
        }
    }

    private func handleSwipe(_ translation: CGSize) {
        if abs(translation.width) > abs(translation.height) {
            move(translation.width > 0 ? .right : .left)
        } else {
            move(translation.height > 0 ? .down : .up)
        }
    }

    private func animateBoardMove(_ direction: MoveDirection) {
        let distance: CGFloat = 12

        let targetOffset: CGSize = switch direction {
        case .up:
            CGSize(width: 0, height: -distance)
        case .down:
            CGSize(width: 0, height: distance)
        case .left:
            CGSize(width: -distance, height: 0)
        case .right:
            CGSize(width: distance, height: 0)
        }

        withAnimation(.easeOut(duration: 0.08)) {
            boardOffset = targetOffset
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                boardOffset = .zero
            }
        }
    }
}

private struct Tile2048View: View {
    let tile: Tile2048?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)

            if let tile {
                Text(tile.value, format: .number)
                    .font(.system(size: fontSize(for: tile.value), weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.45)
                    .foregroundStyle(textColor(for: tile.value))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(tile.map { "Tile \($0.value)" } ?? "Empty tile")
    }

    private var backgroundColor: Color {
        guard let value = tile?.value else {
            return Color.primary.opacity(0.08)
        }

        switch value {
        case 2:
            return Color.green.opacity(0.20)
        case 4:
            return Color.green.opacity(0.30)
        case 8:
            return Color.orange.opacity(0.35)
        case 16:
            return Color.orange.opacity(0.45)
        case 32:
            return Color.red.opacity(0.40)
        case 64:
            return Color.red.opacity(0.55)
        case 128:
            return Color.blue.opacity(0.42)
        case 256:
            return Color.blue.opacity(0.55)
        case 512:
            return Color.purple.opacity(0.50)
        case 1024:
            return Color.purple.opacity(0.65)
        default:
            return Color.yellow.opacity(0.70)
        }
    }

    private func textColor(for value: Int) -> Color {
        value <= 4 ? .primary : .white
    }

    private func fontSize(for value: Int) -> CGFloat {
        value < 100 ? 34 : value < 1000 ? 28 : 22
    }
}

private struct Score2048Tile: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

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

struct Game2048View_Previews: PreviewProvider {
    static var previews: some View {
        Game2048View()
    }
}
