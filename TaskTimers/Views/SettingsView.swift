import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Toggle("Count Up", isOn: Binding(
                        get: { viewModel.timerMode == .countup },
                        set: { viewModel.toggleMode(isCountUp: $0) }
                    ))
                    Text("Default is countdown. Count up is useful for open-ended sessions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Theme") {
                    Picker("Accent", selection: Binding(
                        get: { viewModel.selectedTheme },
                        set: { viewModel.updateTheme($0) }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 16, height: 16)
                                Text(theme.rawValue.capitalized)
                            }
                            .tag(theme)
                        }
                    }
                }

                Section("Sound") {
                    Picker("Completion", selection: Binding(
                        get: { viewModel.selectedSound },
                        set: { viewModel.updateSound($0) }
                    )) {
                        ForEach(SoundOption.allCases, id: \.self) { sound in
                            Text(sound.rawValue.replacingOccurrences(of: "systemDefault", with: "System Default").capitalized)
                                .tag(sound)
                        }
                    }
                }

                Section("Pomodoro") {
                    Stepper(value: Binding(
                        get: { viewModel.pomodoroSettings.workMinutes },
                        set: { viewModel.updatePomodoro(work: $0, breakTime: viewModel.pomodoroSettings.breakMinutes, cycles: viewModel.pomodoroSettings.cycles) }
                    ), in: 5...90) {
                        Text("Work: \(viewModel.pomodoroSettings.workMinutes) min")
                    }

                    Stepper(value: Binding(
                        get: { viewModel.pomodoroSettings.breakMinutes },
                        set: { viewModel.updatePomodoro(work: viewModel.pomodoroSettings.workMinutes, breakTime: $0, cycles: viewModel.pomodoroSettings.cycles) }
                    ), in: 1...30) {
                        Text("Break: \(viewModel.pomodoroSettings.breakMinutes) min")
                    }

                    Stepper(value: Binding(
                        get: { viewModel.pomodoroSettings.cycles },
                        set: { viewModel.updatePomodoro(work: viewModel.pomodoroSettings.workMinutes, breakTime: viewModel.pomodoroSettings.breakMinutes, cycles: $0) }
                    ), in: 1...8) {
                        Text("Cycles: \(viewModel.pomodoroSettings.cycles)")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TimerViewModel())
}
