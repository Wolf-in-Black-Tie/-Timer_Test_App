import SwiftUI

// MARK: - Timer Mode (countdown or countup)
enum TimerMode: String, Codable, CaseIterable {
    case countdown
    case countup
}


// MARK: - App Theme (simple local themes)
enum AppTheme: String, Codable, CaseIterable {
    case system
    case blue
    case green
    case purple
    case orange

    var accentColor: Color {
        switch self {
        case .system: return Color.accentColor
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}


// MARK: - Sound Options (built-in, no custom files)
enum SoundOption: String, Codable, CaseIterable {
    case systemDefault
    case chime
    case bell
    case tick
    case silent
}


// MARK: - Pomodoro Settings (simple + easy only)
struct PomodoroSettings: Codable, Equatable {
    var workMinutes: Int
    var breakMinutes: Int
    var cycles: Int

    static let `default` = PomodoroSettings(
        workMinutes: 25,
        breakMinutes: 5,
        cycles: 4
    )
}
