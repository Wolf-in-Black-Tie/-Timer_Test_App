import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var viewModel: TimerViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 12) {
                Label(viewModel.selectedTask?.name ?? "Active Timer", systemImage: "hourglass")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.formattedRemainingTime())
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 10)
            )
            .padding(.horizontal)

            controlButtons
            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea())
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
}

#Preview {
    TimerView()
        .environmentObject(TimerViewModel())
}
