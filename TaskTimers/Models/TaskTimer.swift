import Foundation

/// Representation of a task with a preset timer.
struct TaskTimer: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    /// Duration in seconds.
    var duration: Int

    init(id: UUID = UUID(), name: String, duration: Int) {
        self.id = id
        self.name = name
        self.duration = duration
    }
}
