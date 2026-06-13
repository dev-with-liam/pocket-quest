import SwiftUI

struct LogicPopView: View {
    @StateObject private var viewModel = LogicPopViewModel()
    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.68, green: 0.65, blue: 1.00),
                    Color(red: 0.44, green: 0.88, blue: 0.88),
                    Color(red: 1.00, green: 0.77, blue: 0.39)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    GameMascotCard(hint: GameOption.logicPop.mascotHint, tint: .indigo)
                    stats

                    if viewModel.isRoundComplete {
                        roundCompleteCard
                    } else {
                        questionCard
                    }
                }
                .frame(maxWidth: 680)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(.yellow)

            Text("Logic Pop")
                .font(.system(.largeTitle, design: .rounded, weight: .black))

            Text("Pick the answer that makes the most sense.")
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)
        }
        .multilineTextAlignment(.center)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            LogicStatTile(title: "Score", value: viewModel.score, tint: .indigo)
            LogicStatTile(title: "Best", value: viewModel.bestScore, tint: .blue)
            LogicStatTile(title: "Correct", value: viewModel.totalCorrect, tint: .green)
            LogicStatTile(title: "Rounds", value: viewModel.rounds, tint: .orange)
        }
    }

    private var questionCard: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Question \(viewModel.progressText)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.indigo)

                Spacer()

                ProgressView(
                    value: Double(viewModel.questionIndex + 1),
                    total: Double(viewModel.questionsPerRound)
                )
                .frame(maxWidth: 180)
                .tint(.indigo)
            }

            Text(viewModel.currentQuestion.prompt)
                .font(.system(.title2, design: .rounded, weight: .black))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 90)

            VStack(spacing: 10) {
                ForEach(viewModel.currentQuestion.choices.indices, id: \.self) { index in
                    answerButton(index)
                }
            }

            if let isCorrect = viewModel.isAnswerCorrect {
                VStack(spacing: 8) {
                    Label(
                        isCorrect ? "Correct!" : "Not quite",
                        systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(.headline.weight(.black))
                    .foregroundStyle(isCorrect ? .green : .red)

                    Text(viewModel.currentQuestion.explanation)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrandPalette.textGradient)
                        .multilineTextAlignment(.center)

                    if !isCorrect {
                        Button(
                            viewModel.questionIndex + 1 == viewModel.questionsPerRound ? "Finish Round" : "Continue"
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                autoAdvanceTask?.cancel()
                                viewModel.continueRound()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .controlSize(.large)
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.indigo.opacity(0.18), .white.opacity(0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .indigo.opacity(0.16), radius: 18, y: 10)
        .onChange(of: viewModel.isAnswerCorrect) { _, newValue in
            autoAdvanceTask?.cancel()

            guard newValue == true else { return }

            autoAdvanceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    viewModel.continueRound()
                }
            }
        }
    }

    private var roundCompleteCard: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.score >= 4 ? "star.circle.fill" : "brain.head.profile")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(viewModel.score >= 4 ? .yellow : .indigo)

            Text(viewModel.score >= 4 ? "Sharp Thinking!" : "Round Complete")
                .font(.title.weight(.black))

            Text("You solved \(viewModel.score) of \(viewModel.questionsPerRound) questions.")
                .font(.headline)
                .foregroundStyle(BrandPalette.textGradient)

            Button("Play Another Round") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    viewModel.startNewRound()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.18), .white.opacity(0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .indigo.opacity(0.16), radius: 18, y: 10)
    }

    private func answerButton(_ index: Int) -> some View {
        let isSelected = viewModel.selectedIndex == index
        let isCorrectAnswer = viewModel.currentQuestion.correctIndex == index
        let hasAnswered = viewModel.selectedIndex != nil

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                viewModel.chooseAnswer(at: index)
            }
        } label: {
            HStack(spacing: 12) {
                Text(["A", "B", "C", "D"][index])
                    .font(.headline.weight(.black))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.72), in: Circle())

                Text(viewModel.currentQuestion.choices[index])
                    .font(.headline.weight(.semibold))

                Spacer()

                if hasAnswered && (isSelected || isCorrectAnswer) {
                    Image(systemName: isCorrectAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                }
            }
            .foregroundStyle(answerForeground(isSelected: isSelected, isCorrect: isCorrectAnswer, hasAnswered: hasAnswered))
            .padding(14)
            .background(
                answerBackground(isSelected: isSelected, isCorrect: isCorrectAnswer, hasAnswered: hasAnswered),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }

    private func answerBackground(isSelected: Bool, isCorrect: Bool, hasAnswered: Bool) -> Color {
        if hasAnswered && isCorrect { return .green.opacity(0.8) }
        if hasAnswered && isSelected { return .red.opacity(0.8) }
        return .orange.opacity(0.14)
    }

    private func answerForeground(isSelected: Bool, isCorrect: Bool, hasAnswered: Bool) -> Color {
        hasAnswered && (isSelected || isCorrect) ? .white : .primary
    }
}

private struct LogicStatTile: View {
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
