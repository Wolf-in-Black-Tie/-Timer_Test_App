import Foundation
import AVFoundation
import AudioToolbox
import BackgroundTasks
import SwiftUI
import UIKit

/// Centralized state for all timer related behaviour.
final class TimerViewModel: ObservableObject {
    // MARK: - Published properties
    @Published private(set) var tasks: [TaskTimer] = []
    @Published var selectedTask: TaskTimer?
    @Published var timeDisplay: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var timerMode: TimerMode = .countdown
    @Published var selectedTheme: AppTheme = .ocean
    @Published var selectedSound: SoundOption = .bell
    @Published var isDimmed: Bool = false
    @Published var pomodoroSettings: PomodoroSettings = .default
    @Published private(set) var isPomodoroActive: Bool = false
    @Published private(set) var isOnBreak: Bool = false
    @Published private(set) var currentCycle: Int = 0

    // MARK: - Private properties
    private var timer: DispatchSourceTimer?
    private var endDate: Date?
    private var startDate: Date?
    private var totalDuration: Int = 0
    private var pausedElapsed: Int = 0

    private static let backgroundRefreshIdentifier = "com.codex.TaskTimers.refresh"
    private let defaults = UserDefaults.standard
    private let persistedTaskIDKey = "com.codex.TaskTimers.persistedTaskID"
    private let persistedEndDateKey = "com.codex.TaskTimers.endDate"
    private let persistedModeKey = "com.codex.TaskTimers.timerMode"
    private let persistedPausedKey = "com.codex.TaskTimers.paused"
    private let persistedDisplayKey = "com.codex.TaskTimers.display"
    private let tasksKey = "com.codex.TaskTimers.tasks"
    private let themeKey = "com.codex.TaskTimers.theme"
    private let soundKey = "com.codex.TaskTimers.sound"
    private let pomodoroKey = "com.codex.TaskTimers.pomodoro"
    private let lastTaskNameKey = "com.codex.TaskTimers.lastTask"

    private let notificationManager = NotificationManager.shared

    // MARK: - Lifecycle
    init() {
        loadPreferences()
        loadTasks()
        notificationManager.requestAuthorization()
        registerBackgroundTasks()
        restorePersistedTimerIfNeeded()
    }

    deinit {
        timer?.cancel()
    }

    // MARK: - Public API
    func start(task: TaskTimer) {
        triggerSoftTap()
        isPomodoroActive = false
        isOnBreak = false
        currentCycle = 0
        configureTimer(with: task)
    }

    func startPomodoro() {
        triggerSoftTap()
        isPomodoroActive = true
        isOnBreak = false
        currentCycle = 1
        let workTask = TaskTimer(name: "Pomodoro • Work", duration: pomodoroSettings.workDuration)
        configureTimer(with: workTask)
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        timeDisplay = timerMode == .countdown ? currentRemainingSeconds() : elapsedSeconds()
        pausedElapsed = elapsedSeconds()
        endDate = Date().addingTimeInterval(TimeInterval(max(0, totalDuration - pausedElapsed)))
        timer?.cancel()
        timer = nil
        isPaused = true
        notificationManager.cancelPendingNotifications()
        clearBackgroundRefresh()
        persistCurrentState()
        triggerSoftTap()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        let remaining = max(0, totalDuration - pausedElapsed)
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        startDate = Date()
        isPaused = false
        persistCurrentState()
        scheduleBackgroundRefreshIfNeeded()
        notificationManager.scheduleTimerCompletionNotification(taskName: selectedTask?.name ?? "Timer", fireDate: endDate)
        startDispatchTimer()
        triggerSoftTap()
    }

    func cancel() {
        triggerSoftTap()
        resetTimerState()
    }

    func formattedTime() -> String {
        let hours = timeDisplay / 3600
        let minutes = (timeDisplay % 3600) / 60
        let seconds = timeDisplay % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            refreshRemainingTimeFromClock()
        case .background:
            scheduleBackgroundRefreshIfNeeded()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = elapsedSeconds()
        return min(1, max(0, Double(elapsed) / Double(totalDuration)))
    }

    // MARK: - Task CRUD
    func addTask(name: String, duration: Int) {
        let newTask = TaskTimer(name: name, duration: duration)
        tasks.append(newTask)
        persistTasks()
    }

    func update(task: TaskTimer) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        persistTasks()
    }

    func delete(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        persistTasks()
    }

    func move(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        persistTasks()
    }

    func toggleMode(isCountUp: Bool) {
        timerMode = isCountUp ? .countup : .countdown
        persistPreferences()
    }

    func updateTheme(_ theme: AppTheme) {
        selectedTheme = theme
        persistPreferences()
    }

    func updateSound(_ sound: SoundOption) {
        selectedSound = sound
        persistPreferences()
    }

    func updatePomodoro(work: Int, breakTime: Int, cycles: Int) {
        pomodoroSettings = PomodoroSettings(workDuration: work, breakDuration: breakTime, cycles: cycles)
        persistPreferences()
    }

    func adjustTime(by seconds: Int) {
        guard isRunning, let _ = selectedTask else { return }
        let elapsed = elapsedSeconds()
        totalDuration = max(elapsed + 1, totalDuration + seconds)
        let remaining = max(0, totalDuration - elapsed)
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        timeDisplay = timerMode == .countdown ? remaining : elapsed
        persistCurrentState()
    }

    func lastUsedTaskTitle() -> String? {
        defaults.string(forKey: lastTaskNameKey)
    }

    func startLastTaskIfAvailable() {
        guard let title = lastUsedTaskTitle(), let task = tasks.first(where: { $0.name == title }) else { return }
        start(task: task)
    }

    // MARK: - Background Tasks
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundRefreshIdentifier, using: nil) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: true)
                return
            }
            self?.handleBackgroundRefresh(task: refreshTask)
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefreshIfNeeded()
        refreshRemainingTimeFromClock()
        task.setTaskCompleted(success: true)
    }

    private func scheduleBackgroundRefreshIfNeeded() {
        guard isRunning, !isPaused, let _ = endDate else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Give the system freedom to wake us soon.
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("Background refresh scheduling failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func clearBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundRefreshIdentifier)
    }

    // MARK: - Timer helpers
    private func configureTimer(with task: TaskTimer) {
        selectedTask = task
        totalDuration = task.duration
        timeDisplay = timerMode == .countdown ? task.duration : 0
        isRunning = true
        isPaused = false
        startDate = Date()
        endDate = Date().addingTimeInterval(TimeInterval(task.duration))
        pausedElapsed = 0
        defaults.set(task.name, forKey: lastTaskNameKey)
        persistCurrentState()
        scheduleBackgroundRefreshIfNeeded()
        notificationManager.scheduleTimerCompletionNotification(taskName: task.name, fireDate: endDate)
        startDispatchTimer()
    }

    private func startDispatchTimer() {
        timer?.cancel()
        let queue = DispatchQueue(label: "com.codex.TaskTimers.timer")
        let dispatchTimer = DispatchSource.makeTimerSource(queue: queue)
        dispatchTimer.schedule(deadline: .now(), repeating: 1.0)
        dispatchTimer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        dispatchTimer.resume()
        timer = dispatchTimer
    }

    private func tick() {
        guard isRunning, !isPaused else { return }
        let seconds = currentRemainingSeconds()
        let elapsed = elapsedSeconds()
        if timerMode == .countdown {
            timeDisplay = max(0, seconds)
        } else {
            timeDisplay = elapsed
        }
        if seconds <= 0 {
            completeTimer()
        }
    }

    private func elapsedSeconds() -> Int {
        guard totalDuration > 0 else { return 0 }
        let remaining = max(0, currentRemainingSeconds())
        return max(0, totalDuration - remaining)
    }

    private func currentRemainingSeconds() -> Int {
        guard let endDate = endDate else { return 0 }
        return Int(endDate.timeIntervalSinceNow.rounded(.down))
    }

    private func completeTimer() {
        guard let taskName = selectedTask?.name else {
            resetTimerState()
            return
        }

        if isPomodoroActive {
            handlePomodoroCompletion()
            return
        }

        resetTimerState(shouldPersist: false)
        playCompletionSound()
        triggerHaptics()
        notificationManager.sendCompletionNow(taskName: taskName)
        notificationManager.checkNotificationSettings { enabled in
            if !enabled {
                self.triggerHaptics()
            }
        }
    }

    private func handlePomodoroCompletion() {
        if isOnBreak {
            if currentCycle >= pomodoroSettings.cycles {
                resetTimerState(shouldPersist: false)
            } else {
                currentCycle += 1
                isOnBreak = false
                let workTask = TaskTimer(name: "Pomodoro • Work", duration: pomodoroSettings.workDuration)
                configureTimer(with: workTask)
            }
        } else {
            isOnBreak = true
            let breakTask = TaskTimer(name: "Pomodoro • Break", duration: pomodoroSettings.breakDuration)
            configureTimer(with: breakTask)
        }
    }

    private func resetTimerState(shouldPersist: Bool = false) {
        timer?.cancel()
        timer = nil
        isRunning = false
        isPaused = false
        timeDisplay = 0
        selectedTask = nil
        endDate = nil
        startDate = nil
        totalDuration = 0
        isPomodoroActive = false
        isOnBreak = false
        currentCycle = 0
        notificationManager.cancelPendingNotifications()
        clearBackgroundRefresh()
        if !shouldPersist {
            clearPersistedState()
        }
    }

    private func refreshRemainingTimeFromClock() {
        guard isRunning, let _ = endDate else { return }
        let seconds = currentRemainingSeconds()
        if seconds <= 0 {
            completeTimer()
        } else {
            let elapsed = elapsedSeconds()
            timeDisplay = timerMode == .countdown ? seconds : elapsed
        }
    }

    // MARK: - Persistence
    private func persistCurrentState() {
        guard let task = selectedTask, let endDate else { return }
        defaults.set(task.id.uuidString, forKey: persistedTaskIDKey)
        defaults.set(endDate.timeIntervalSince1970, forKey: persistedEndDateKey)
        defaults.set(timerMode.rawValue, forKey: persistedModeKey)
        defaults.set(isPaused, forKey: persistedPausedKey)
        defaults.set(timeDisplay, forKey: persistedDisplayKey)
    }

    private func clearPersistedState() {
        defaults.removeObject(forKey: persistedTaskIDKey)
        defaults.removeObject(forKey: persistedEndDateKey)
        defaults.removeObject(forKey: persistedPausedKey)
        defaults.removeObject(forKey: persistedDisplayKey)
    }

    private func restorePersistedTimerIfNeeded() {
        guard let taskIDString = defaults.string(forKey: persistedTaskIDKey),
              let taskID = UUID(uuidString: taskIDString) else { return }
        let endTime = defaults.double(forKey: persistedEndDateKey)
        guard endTime > 0 else { return }
        timerMode = TimerMode(rawValue: defaults.string(forKey: persistedModeKey) ?? "countdown") ?? .countdown
        let wasPaused = defaults.bool(forKey: persistedPausedKey)
        let display = defaults.integer(forKey: persistedDisplayKey)
        guard let task = tasks.first(where: { $0.id == taskID }) else {
            clearPersistedState()
            return
        }
        selectedTask = task
        totalDuration = task.duration
        if wasPaused {
            isRunning = true
            isPaused = true
            timeDisplay = display > 0 ? display : (timerMode == .countdown ? totalDuration : 0)
            pausedElapsed = timerMode == .countdown ? max(0, totalDuration - timeDisplay) : timeDisplay
        } else {
            endDate = Date(timeIntervalSince1970: endTime)
            let seconds = currentRemainingSeconds()
            if seconds > 0 {
                timeDisplay = timerMode == .countdown ? seconds : elapsedSeconds()
                isRunning = true
                isPaused = false
                startDispatchTimer()
            } else {
                clearPersistedState()
                selectedTask = nil
            }
        }
    }

    private func persistTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            defaults.set(data, forKey: tasksKey)
        }
    }

    private func loadTasks() {
        if let data = defaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TaskTimer].self, from: data),
           !decoded.isEmpty {
            tasks = decoded
        } else {
            configureDefaultTasks()
        }
    }

    private func loadPreferences() {
        if let storedMode = defaults.string(forKey: persistedModeKey),
           let restoredMode = TimerMode(rawValue: storedMode) {
            timerMode = restoredMode
        }
        if let storedTheme = defaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: storedTheme) {
            selectedTheme = theme
        }
        if let storedSound = defaults.string(forKey: soundKey),
           let sound = SoundOption(rawValue: storedSound) {
            selectedSound = sound
        }
        if let data = defaults.data(forKey: pomodoroKey),
           let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
            pomodoroSettings = settings
        }
    }

    private func persistPreferences() {
        defaults.set(timerMode.rawValue, forKey: persistedModeKey)
        defaults.set(selectedTheme.rawValue, forKey: themeKey)
        defaults.set(selectedSound.rawValue, forKey: soundKey)
        if let data = try? JSONEncoder().encode(pomodoroSettings) {
            defaults.set(data, forKey: pomodoroKey)
        }
    }

    private func configureDefaultTasks() {
        tasks = [
            TaskTimer(name: "Reading Time", duration: 20 * 60),
            TaskTimer(name: "Meditation", duration: 10 * 60),
            TaskTimer(name: "Journaling", duration: 5 * 60),
            TaskTimer(name: "Stretching", duration: 8 * 60),
            TaskTimer(name: "Study Session", duration: 30 * 60)
        ]
        persistTasks()
    }

    // MARK: - Sound & Haptics
    private func playCompletionSound() {
        AudioServicesPlaySystemSound(selectedSound.systemSoundID)
    }

    private func triggerHaptics() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func triggerSoftTap() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }
}
