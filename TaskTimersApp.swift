import SwiftUI

@main
struct TaskTimersApp: App {
    @StateObject private var timerViewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(timerViewModel)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TaskListView()
            .environmentObject(viewModel)
            .onChange(of: scenePhase) { newPhase in
                viewModel.handleScenePhaseChange(newPhase)
            }
    }
}
