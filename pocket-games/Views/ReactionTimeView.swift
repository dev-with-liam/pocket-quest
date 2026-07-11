import SwiftUI

struct ReactionTimeView: View {
    @StateObject private var viewModel = ReactionTimeViewModel()
    @FocusState private var isTargetFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.secondary.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                target
                stats
                resetButton
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .focused($isTargetFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isTargetFocused = true
        }
        .onAppear {
            isTargetFocused = true
        }
        .onKeyPress(.space) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                viewModel.tapTarget()
            }
            return .handled
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(viewModel.titleText)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            Text(viewModel.instructionText)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.instructionText)
        }
    }

    private var target: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                viewModel.tapTarget()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(targetColor)

                VStack(spacing: 12) {
                    Image(systemName: targetIcon)
                        .font(.system(size: 44, weight: .bold))

                    Text(targetText)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .frame(maxWidth: 420)
            .frame(height: 240)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(targetText)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            ReactionStatTile(
                title: "Last",
                value: formattedMilliseconds(viewModel.lastReactionMilliseconds),
                tint: .purple
            )
            ReactionStatTile(
                title: "Best",
                value: formattedMilliseconds(viewModel.bestReactionMilliseconds),
                tint: .blue
            )
        }
        .frame(maxWidth: 420)
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            viewModel.resetBest()
        } label: {
            Label("Reset Best", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: 320)
    }

    private var targetColor: Color {
        switch viewModel.phase {
        case .ready, .result:
            return .purple
        case .waiting:
            return .orange
        case .tapNow:
            return .green
        case .early:
            return .red
        }
    }

    private var targetIcon: String {
        switch viewModel.phase {
        case .ready, .result:
            return "play.fill"
        case .waiting:
            return "hourglass"
        case .tapNow:
            return "hand.tap.fill"
        case .early:
            return "exclamationmark.triangle.fill"
        }
    }

    private var targetText: String {
        switch viewModel.phase {
        case .ready:
            return "Start"
        case .waiting:
            return "Wait"
        case .tapNow:
            return "Tap"
        case .result:
            return formattedMilliseconds(viewModel.lastReactionMilliseconds)
        case .early:
            return "Too Soon"
        }
    }

    private func formattedMilliseconds(_ milliseconds: Int?) -> String {
        guard let milliseconds else { return "--" }
        return "\(milliseconds) ms"
    }
}

private struct ReactionStatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ReactionTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionTimeView()
    }
}
