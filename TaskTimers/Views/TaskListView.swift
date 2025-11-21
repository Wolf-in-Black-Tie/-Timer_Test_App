import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @State private var navigateToTimer = false
    @State private var showingEditor = false
    @State private var editingTask: TaskTimer?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section("Presets") {
                    ForEach(viewModel.tasks) { task in
                        taskRow(for: task)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(task: task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingTask = task
                                    showingEditor = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                    .onMove(perform: viewModel.move)
                    .onDelete(perform: viewModel.delete)
                }

                Section("Focus") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Pomodoro")
                                .font(.headline)
                            Text("Work \(viewModel.pomodoroSettings.workMinutes)m · Break \(viewModel.pomodoroSettings.breakMinutes)m · \(viewModel.pomodoroSettings.cycles)x")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.startPomodoro()
                            navigateToTimer = true
                        } label: {
                            Label("Start", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }

                Section("Widget") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Last timer")
                                .font(.headline)
                            Text(viewModel.lastUsedTaskTitle() ?? "No timer yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.startLastTaskIfAvailable()
                            navigateToTimer = viewModel.isRunning
                        } label: {
                            Label("Start", systemImage: "play.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("TaskTimers")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingEditor) {
                AddEditTimerView(task: $editingTask) { name, minutes in
                    if var task = editingTask {
                        task.name = name
                        task.duration = minutes * 60
                        viewModel.update(task: task)
                    } else {
                        viewModel.addTask(name: name, duration: minutes * 60)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(viewModel)
            }
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
            navigateToTimer = running
        }
    }

    private func taskRow(for task: TaskTimer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                    Text(durationString(for: task.duration))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    viewModel.start(task: task)
                    navigateToTimer = true
                } label: {
                    Image(systemName: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(viewModel.selectedTheme.accentColor))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private func durationString(for seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                editingTask = nil
                showingEditor = true
            } label: {
                Label("Add", systemImage: "plus")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "paintbrush")
            }
        }
    }

    private func delete(task: TaskTimer) {
        if let index = viewModel.tasks.firstIndex(of: task) {
            viewModel.delete(at: IndexSet(integer: index))
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(TimerViewModel())
}
