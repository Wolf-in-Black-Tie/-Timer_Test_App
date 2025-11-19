import Foundation
import AVFoundation
import BackgroundTasks
import SwiftUI
import UIKit

/// Centralized state for all timer related behaviour.
final class TimerViewModel: ObservableObject {
    // MARK: - Published properties
    @Published private(set) var tasks: [TaskTimer] = []
    @Published var selectedTask: TaskTimer?
    @Published var remainingTime: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false

    // MARK: - Private properties
    private var timer: DispatchSourceTimer?
    private var endDate: Date?
    private var audioPlayer: AVAudioPlayer?

    private static let backgroundRefreshIdentifier = "com.codex.TaskTimers.refresh"
    private let defaults = UserDefaults.standard
    private let persistedTaskKey = "com.codex.TaskTimers.persistedTask"
    private let persistedEndDateKey = "com.codex.TaskTimers.endDate"

    private let notificationManager = NotificationManager.shared

    // MARK: - Lifecycle
    init() {
        configureTasks()
        notificationManager.requestAuthorization()
        registerBackgroundTasks()
        restorePersistedTimerIfNeeded()
    }

    deinit {
        timer?.cancel()
    }

    // MARK: - Public API
    func start(task: TaskTimer) {
        selectedTask = task
        remainingTime = task.duration
        isRunning = true
        isPaused = false
        endDate = Date().addingTimeInterval(TimeInterval(task.duration))
        persistCurrentState()
        scheduleBackgroundRefreshIfNeeded()
        notificationManager.scheduleTimerCompletionNotification(taskName: task.name, fireDate: endDate)
        startDispatchTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        remainingTime = currentRemainingSeconds()
        timer?.cancel()
        timer = nil
        isPaused = true
        notificationManager.cancelPendingNotifications()
        clearBackgroundRefresh()
        persistCurrentState()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        endDate = Date().addingTimeInterval(TimeInterval(remainingTime))
        isPaused = false
        persistCurrentState()
        scheduleBackgroundRefreshIfNeeded()
        notificationManager.scheduleTimerCompletionNotification(taskName: selectedTask?.name ?? "Timer", fireDate: endDate)
        startDispatchTimer()
    }

    func cancel() {
        resetTimerState()
    }

    func formattedRemainingTime() -> String {
        let hours = remainingTime / 3600
        let minutes = (remainingTime % 3600) / 60
        let seconds = remainingTime % 60

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
        remainingTime = max(0, seconds)
        if seconds <= 0 {
            completeTimer()
        }
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

    private func resetTimerState(shouldPersist: Bool = false) {
        timer?.cancel()
        timer = nil
        isRunning = false
        isPaused = false
        remainingTime = 0
        selectedTask = nil
        endDate = nil
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
            remainingTime = seconds
        }
    }

    // MARK: - Persistence
    private func persistCurrentState() {
        guard let task = selectedTask, let endDate else { return }
        defaults.set(task.name, forKey: persistedTaskKey)
        defaults.set(endDate.timeIntervalSince1970, forKey: persistedEndDateKey)
    }

    private func clearPersistedState() {
        defaults.removeObject(forKey: persistedTaskKey)
        defaults.removeObject(forKey: persistedEndDateKey)
    }

    private func restorePersistedTimerIfNeeded() {
        guard let taskName = defaults.string(forKey: persistedTaskKey) else { return }
        let endTime = defaults.double(forKey: persistedEndDateKey)
        guard endTime > 0 else { return }
        guard let task = tasks.first(where: { $0.name == taskName }) else {
            clearPersistedState()
            return
        }
        selectedTask = task
        endDate = Date(timeIntervalSince1970: endTime)
        let seconds = currentRemainingSeconds()
        if seconds > 0 {
            remainingTime = seconds
            isRunning = true
            isPaused = false
            startDispatchTimer()
        } else {
            clearPersistedState()
            selectedTask = nil
        }
    }

    // MARK: - Sound & Haptics
    private func playCompletionSound() {
        guard let url = Bundle.main.url(forResource: "timer_end", withExtension: "mp3") else {
            #if DEBUG
            print("Missing bundled sound file named timer_end.mp3")
            #endif
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            #if DEBUG
            print("Failed to play sound: \(error.localizedDescription)")
            #endif
        }
    }

    private func triggerHaptics() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Sample data
    private func configureTasks() {
        tasks = [
            TaskTimer(name: "Reading Time", duration: 20 * 60),
            TaskTimer(name: "Meditation", duration: 10 * 60),
            TaskTimer(name: "Journaling", duration: 5 * 60),
            TaskTimer(name: "Stretching", duration: 8 * 60),
            TaskTimer(name: "Study Session", duration: 30 * 60)
        ]
    }
}
