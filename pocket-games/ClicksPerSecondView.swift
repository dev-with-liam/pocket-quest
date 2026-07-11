import SwiftUI

struct ClicksPerSecondView: View {
    @StateObject private var viewModel = ClicksPerSecondViewModel()
    @State private var tapScale = 1.0
    @FocusState private var isTargetFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.69, blue: 0.39),
                    Color(red: 0.72, green: 0.46, blue: 1.00),
                    Color(red: 0.38, green: 0.85, blue: 0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                stats
                tapTarget
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
            handleTap()
            return .handled
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Clicks Per Second")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            Text(viewModel.statusText)
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            CPSStatTile(title: "Clicks", value: "\(viewModel.clickCount)", tint: .red)
            CPSStatTile(title: "Time", value: String(format: "%.1fs", viewModel.remainingSeconds), tint: .orange)
            CPSStatTile(title: "Best", value: String(format: "%.1f", viewModel.bestClicksPerSecond), tint: .blue)
            CPSStatTile(title: "Tries", value: "\(viewModel.attempts)", tint: .purple)
        }
        .frame(maxWidth: 580)
    }

    private var tapTarget: some View {
        Button {
            handleTap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(targetColor)

                VStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 48, weight: .bold))

                    Text(targetText)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(BrandPalette.textGradient)

                    Text(String(format: "%.2f CPS", viewModel.clicksPerSecond))
                        .font(.headline)
                        .opacity(viewModel.phase == .ready ? 0 : 1)
                }
                .foregroundStyle(BrandPalette.textGradient)
                .padding(20)
            }
            .scaleEffect(tapScale)
            .frame(maxWidth: 420)
            .frame(height: 260)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(targetText)
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
        case .ready:
            return .red
        case .running:
            return .green
        case .finished:
            return .blue
        }
    }

    private var targetText: String {
        switch viewModel.phase {
        case .ready:
            return "Start"
        case .running:
            return "Tap"
        case .finished:
            return "Try Again"
        }
    }

    private func handleTap() {
        withAnimation(.spring(response: 0.12, dampingFraction: 0.55)) {
            tapScale = 0.96
            viewModel.tapTarget()
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                tapScale = 1.0
            }
        }
    }
}

private struct CPSStatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.textGradient)
                .lineLimit(1)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(BrandPalette.textGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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

struct ClicksPerSecondView_Previews: PreviewProvider {
    static var previews: some View {
        ClicksPerSecondView()
    }
}
