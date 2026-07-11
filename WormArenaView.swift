import SwiftUI

struct WormArenaView: View {
    @StateObject private var viewModel = WormArenaViewModel()
    @FocusState private var isArenaFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.97, blue: 0.84),
                    Color(red: 0.76, green: 0.90, blue: 0.67),
                    Color(red: 0.94, green: 0.86, blue: 0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    GameMascotCard(hint: GameOption.wormArena.mascotHint, tint: .green)
                    stats
                    difficultyPicker
                    arena
                    controls
                }
                .frame(maxWidth: 920)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
        .focusable()
        .focused($isArenaFocused)
        .onAppear {
            isArenaFocused = true
            viewModel.resumeGameLoop()
        }
        .onDisappear { viewModel.stopGameLoop() }
        .onTapGesture { isArenaFocused = true }
        .onKeyPress(.upArrow) { move(.up) }
        .onKeyPress(.downArrow) { move(.down) }
        .onKeyPress(.leftArrow) { move(.left) }
        .onKeyPress(.rightArrow) { move(.right) }
        .onKeyPress(characters: CharacterSet(charactersIn: "wWaAsSdD ")) { key in
            handleKey(key.characters)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Worm Arena")
                .font(.system(.largeTitle, design: .rounded, weight: .black))

            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            WormStatTile(title: "Food", value: viewModel.score, tint: .green)
            WormStatTile(title: "Best", value: viewModel.bestScore, tint: .blue)
            WormStatTile(title: "Wins", value: viewModel.wins, tint: .purple)
            WormStatTile(title: "Losses", value: viewModel.losses, tint: .red)
            WormStatTile(title: "Runs", value: viewModel.attempts, tint: .orange)
        }
    }

    private var difficultyPicker: some View {
        VStack(spacing: 8) {
            Picker(
                "Difficulty",
                selection: Binding(
                    get: { viewModel.difficulty },
                    set: { viewModel.setDifficulty($0) }
                )
            ) {
                ForEach(WormArenaDifficulty.allCases) { difficulty in
                    Text(difficulty.title).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.phase == .playing)

            HStack {
                Text(viewModel.difficulty.summary)
                Spacer()
                Text("\(viewModel.rivalCount) rival\(viewModel.rivalCount == 1 ? "" : "s") • \(viewModel.winningScore) food to win")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(BrandPalette.textGradient)
        }
        .frame(maxWidth: 680)
        .padding(12)
        .background(
            LinearGradient(
                colors: [.green.opacity(0.20), .yellow.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var arena: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / CGFloat(viewModel.columns)
            let cellHeight = proxy.size.height / CGFloat(viewModel.rows)

            ZStack {
                Canvas(opaque: true, rendersAsynchronously: true) { context, size in
                    drawGardenTexture(
                        context: &context,
                        size: size,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight
                    )
                }

                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: viewModel.phase != .playing)) { timeline in
                    Canvas(rendersAsynchronously: true) { context, size in
                        drawArenaObjects(
                            context: &context,
                            size: size,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            progress: interpolationProgress(at: timeline.date)
                        )
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.34, green: 0.66, blue: 0.25),
                        Color(red: 0.22, green: 0.52, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.65), .brown.opacity(0.8)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 5
                    )
            }
            .overlay {
                if viewModel.phase != .playing {
                    arenaOverlay
                }
            }
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
        }
        .aspectRatio(CGFloat(viewModel.columns) / CGFloat(viewModel.rows), contentMode: .fit)
        .frame(maxWidth: 840)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(viewModel.phase == .playing ? "Restart Run" : "Start Run") {
                    viewModel.startGame()
                    isArenaFocused = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)

                Button {
                    viewModel.activateBoost()
                    isArenaFocused = true
                } label: {
                    Label("Boost", systemImage: "hare.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!viewModel.canBoost)
            }

            Text("Arrow keys or WASD to steer. Space uses boost and costs \(viewModel.boostCost) body segment\(viewModel.boostCost == 1 ? "" : "s").")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
        }
    }

    private var arenaOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.phase == .ready ? "play.fill" : "arrow.clockwise")
                .font(.system(size: 30, weight: .black))

            Text(viewModel.phase == .ready ? "Ready to Wiggle?" : viewModel.phase == .won ? "Garden Champion!" : "Worm Down!")
                .font(.title2.weight(.black))

            Text(viewModel.phase == .ready ? "Press Start Run to begin moving." : "Start another run and beat your best.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)

            Button(viewModel.phase == .ready ? "Start Run" : "Play Again") {
                viewModel.startGame()
                isArenaFocused = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .foregroundStyle(BrandPalette.textGradient)
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(30)
    }

    private func move(_ direction: WormArenaDirection) -> KeyPress.Result {
        viewModel.changeDirection(direction)
        return .handled
    }

    private func handleKey(_ characters: String) -> KeyPress.Result {
        switch characters.lowercased() {
        case "w":
            return move(.up)
        case "s":
            return move(.down)
        case "a":
            return move(.left)
        case "d":
            return move(.right)
        case " ":
            viewModel.activateBoost()
            return .handled
        default:
            return .ignored
        }
    }

    private func drawArenaObjects(
        context: inout GraphicsContext,
        size: CGSize,
        cellWidth: CGFloat,
        cellHeight: CGFloat,
        progress: CGFloat
    ) {
        for point in viewModel.food {
            let rect = cellRect(point, cellWidth: cellWidth, cellHeight: cellHeight).insetBy(
                dx: cellWidth * 0.14,
                dy: cellHeight * 0.14
            )
            let glowRect = rect.insetBy(dx: -cellWidth * 0.18, dy: -cellHeight * 0.18)
            context.fill(Path(ellipseIn: glowRect), with: .color(.yellow.opacity(0.2)))
            context.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [.yellow, .orange, .pink]),
                center: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: 0,
                endRadius: max(rect.width, rect.height) / 2
            ))

            let shine = CGRect(
                x: rect.minX + rect.width * 0.2,
                y: rect.minY + rect.height * 0.15,
                width: rect.width * 0.24,
                height: rect.height * 0.24
            )
            context.fill(Path(ellipseIn: shine), with: .color(.white.opacity(0.85)))
        }

        let rivalColors: [Color] = [.orange, .purple, .blue]
        for (index, rival) in viewModel.rivals.enumerated() {
            let previousWorm = viewModel.previousRivals.first { $0.id == rival.id } ?? rival
            drawWorm(
                rival,
                previousWorm: previousWorm,
                color: rivalColors[index % rivalColors.count],
                context: &context,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                progress: progress
            )
        }

        drawWorm(
            viewModel.player,
            previousWorm: viewModel.previousPlayer,
            color: .green,
            context: &context,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            progress: progress
        )
    }

    private func drawWorm(
        _ worm: ArenaWorm,
        previousWorm: ArenaWorm,
        color: Color,
        context: inout GraphicsContext,
        cellWidth: CGFloat,
        cellHeight: CGFloat,
        progress: CGFloat
    ) {
        guard !worm.segments.isEmpty else { return }
        let centers = interpolatedCenters(
            for: worm,
            previousWorm: previousWorm,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            progress: progress
        )

        if centers.count > 1 {
            var bodyPath = Path()
            bodyPath.move(to: centers.last!)
            for center in centers.dropLast().reversed() {
                bodyPath.addLine(to: center)
            }
            context.stroke(
                bodyPath,
                with: .color(.black.opacity(0.2)),
                style: StrokeStyle(lineWidth: min(cellWidth, cellHeight) * 0.84, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                bodyPath,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.72), color]),
                    startPoint: centers.last!,
                    endPoint: centers[0]
                ),
                style: StrokeStyle(lineWidth: min(cellWidth, cellHeight) * 0.68, lineCap: .round, lineJoin: .round)
            )
        }

        for (index, center) in centers.enumerated().reversed() {
            let isHead = index == 0
            let rect = CGRect(
                x: center.x - cellWidth / 2,
                y: center.y - cellHeight / 2,
                width: cellWidth,
                height: cellHeight
            ).insetBy(
                dx: cellWidth * (isHead ? 0.01 : 0.16),
                dy: cellHeight * (isHead ? 0.01 : 0.16)
            )

            if isHead {
                let shadowRect = rect.offsetBy(dx: cellWidth * 0.08, dy: cellHeight * 0.12)
                context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.24)))
                context.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.42), color, color.opacity(0.72)]),
                        center: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.height * 0.2),
                        startRadius: 0,
                        endRadius: max(rect.width, rect.height) * 0.7
                    )
                )
            } else {
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.82)))
            }

            if isHead {
                drawEyes(in: rect, direction: worm.direction, context: &context)
            }
        }
    }

    private func interpolatedCenters(
        for worm: ArenaWorm,
        previousWorm: ArenaWorm,
        cellWidth: CGFloat,
        cellHeight: CGFloat,
        progress: CGFloat
    ) -> [CGPoint] {
        worm.segments.enumerated().map { index, point in
            let previousIndex = min(index, max(0, previousWorm.segments.count - 1))
            let previousPoint = previousWorm.segments.isEmpty ? point : previousWorm.segments[previousIndex]
            let start = center(for: previousPoint, cellWidth: cellWidth, cellHeight: cellHeight)
            let end = center(for: point, cellWidth: cellWidth, cellHeight: cellHeight)

            return CGPoint(
                x: start.x + (end.x - start.x) * progress,
                y: start.y + (end.y - start.y) * progress
            )
        }
    }

    private func interpolationProgress(at date: Date) -> CGFloat {
        guard viewModel.phase == .playing else { return 1 }
        let elapsed = date.timeIntervalSince(viewModel.lastTickDate)
        return min(1, max(0, elapsed / viewModel.tickInterval))
    }

    private func center(for point: WormArenaPoint, cellWidth: CGFloat, cellHeight: CGFloat) -> CGPoint {
        CGPoint(
            x: (CGFloat(point.x) + 0.5) * cellWidth,
            y: (CGFloat(point.y) + 0.5) * cellHeight
        )
    }

    private func drawGardenTexture(
        context: inout GraphicsContext,
        size: CGSize,
        cellWidth: CGFloat,
        cellHeight: CGFloat
    ) {
        context.fill(
            Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 18),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.34, green: 0.66, blue: 0.25),
                    Color(red: 0.22, green: 0.52, blue: 0.18)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )

        for row in 0..<viewModel.rows {
            for column in 0..<viewModel.columns where (row * 7 + column * 11) % 13 == 0 {
                let center = CGPoint(
                    x: (CGFloat(column) + 0.5) * cellWidth,
                    y: (CGFloat(row) + 0.5) * cellHeight
                )
                let blade = Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y + cellHeight * 0.2))
                    path.addLine(to: CGPoint(x: center.x - cellWidth * 0.12, y: center.y - cellHeight * 0.18))
                    path.move(to: CGPoint(x: center.x, y: center.y + cellHeight * 0.2))
                    path.addLine(to: CGPoint(x: center.x + cellWidth * 0.13, y: center.y - cellHeight * 0.12))
                }
                context.stroke(blade, with: .color(.white.opacity(0.13)), lineWidth: 1)
            }
        }

        let vignette = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 18)
        context.stroke(vignette, with: .color(.black.opacity(0.14)), lineWidth: 12)
    }

    private func drawEyes(in rect: CGRect, direction: WormArenaDirection, context: inout GraphicsContext) {
        let eyeSize = min(rect.width, rect.height) * 0.18
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let spread = min(rect.width, rect.height) * 0.19
        let forward = min(rect.width, rect.height) * 0.18
        let positions: [CGPoint]

        switch direction {
        case .up:
            positions = [
                CGPoint(x: center.x - spread, y: center.y - forward),
                CGPoint(x: center.x + spread, y: center.y - forward)
            ]
        case .down:
            positions = [
                CGPoint(x: center.x - spread, y: center.y + forward),
                CGPoint(x: center.x + spread, y: center.y + forward)
            ]
        case .left:
            positions = [
                CGPoint(x: center.x - forward, y: center.y - spread),
                CGPoint(x: center.x - forward, y: center.y + spread)
            ]
        case .right:
            positions = [
                CGPoint(x: center.x + forward, y: center.y - spread),
                CGPoint(x: center.x + forward, y: center.y + spread)
            ]
        }

        for position in positions {
            let eyeRect = CGRect(
                x: position.x - eyeSize / 2,
                y: position.y - eyeSize / 2,
                width: eyeSize,
                height: eyeSize
            )
            context.fill(Path(ellipseIn: eyeRect), with: .color(.white))
            context.fill(Path(ellipseIn: eyeRect.insetBy(dx: eyeSize * 0.28, dy: eyeSize * 0.28)), with: .color(.black))
        }
    }

    private func cellRect(_ point: WormArenaPoint, cellWidth: CGFloat, cellHeight: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(point.x) * cellWidth,
            y: CGFloat(point.y) * cellHeight,
            width: cellWidth,
            height: cellHeight
        )
    }
}

private struct WormStatTile: View {
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
