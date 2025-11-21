import Foundation

enum TimerMode: String, Codable {
    case countdown
    case countup
}

struct PomodoroSettings: Codable {
    var workDuration: Int
    var breakDuration: Int
    var cycles: Int

    static let `default` = PomodoroSettings(workDuration: 25 * 60, breakDuration: 5 * 60, cycles: 4)
}
