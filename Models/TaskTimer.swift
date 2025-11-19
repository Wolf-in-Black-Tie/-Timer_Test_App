import Foundation

/// Immutable representation of a task with a preset timer.
struct TaskTimer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    /// Duration in seconds.
    let duration: Int
}
