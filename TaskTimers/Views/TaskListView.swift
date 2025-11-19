import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @State private var navigateToTimer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.tasks) { task in
                        taskCard(for: task)
                    }
                }
                .padding(.vertical, 24)
            }
            .padding(.horizontal)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TaskTimers")
            .toolbar { toolbarContent }
            .background(
                NavigationLink(isActive: $navigateToTimer) {
                    TimerView()
                } label: {
                    EmptyView()
                }
                .opacity(0)
            )
        }
        .onChange(of: viewModel.isRunning) { running in
            if running {
                navigateToTimer = true
            } else {
                navigateToTimer = false
            }
        }
    }

    private func taskCard(for task: TaskTimer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(durationString(for: task.duration))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            Button {
                viewModel.start(task: task)
                navigateToTimer = true
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.body.weight(.semibold))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func durationString(for seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isRunning, let task = viewModel.selectedTask {
                Label(task.name, systemImage: "bell")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(TimerViewModel())
}
