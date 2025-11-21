import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @State private var useLargeDisplay = true

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                timerCard
                controlButtons
                adjustmentRow
            }
            .padding()
            .overlay(alignment: .topTrailing) {
                dimToggle
            }
            .overlay(alignment: .bottomTrailing) {
                modeBadge
                    .padding(.trailing, 4)
            }
            .opacity(viewModel.isDimmed ? 0.7 : 1)
        }
        .navigationTitle("Timer")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .cancel) {
                    viewModel.cancel()
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Label(viewModel.selectedTask?.name ?? "Active Timer", systemImage: "hourglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            if viewModel.isPomodoroActive {
                Text(viewModel.isOnBreak ? "Break" : "Work")
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
            }
        }
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(viewModel.selectedTheme.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.progress)
                Text(viewModel.formattedTime())
                    .font(.system(size: useLargeDisplay ? 80 : 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(width: useLargeDisplay ? 280 : 220, height: useLargeDisplay ? 280 : 220)

            HStack(spacing: 12) {
                Button {
                    useLargeDisplay.toggle()
                } label: {
                    Label(useLargeDisplay ? "Standard" : "Large", systemImage: "textformat.size")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }

                if viewModel.isPomodoroActive {
                    Text("Cycle \(viewModel.currentCycle) of \(viewModel.pomodoroSettings.cycles)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button {
                if viewModel.isPaused {
                    viewModel.resume()
                } else {
                    viewModel.pause()
                }
            } label: {
                Label(viewModel.isPaused ? "Resume" : "Pause", systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button(role: .destructive) {
                viewModel.cancel()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private var adjustmentRow: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.adjustTime(by: -60)
            } label: {
                Label("-1 min", systemImage: "minus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button {
                viewModel.adjustTime(by: 60)
            } label: {
                Label("+1 min", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.selectedTheme.accentColor)
        }
        .foregroundStyle(.white)
    }

    private var dimToggle: some View {
        Button {
            viewModel.isDimmed.toggle()
        } label: {
            Image(systemName: viewModel.isDimmed ? "moon.zzz.fill" : "moon.stars.fill")
                .font(.title3)
                .padding(12)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
        .padding()
    }

    private var modeBadge: some View {
        Text(viewModel.timerMode == .countdown ? "Countdown" : "Count Up")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding()
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                viewModel.selectedTheme.accentColor.opacity(0.7),
                viewModel.selectedTheme.accentColor.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    TimerView()
        .environmentObject(TimerViewModel())
}
