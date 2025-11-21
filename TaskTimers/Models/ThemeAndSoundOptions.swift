import SwiftUI

enum AppTheme: String, Codable, CaseIterable {
    case system
    case blue
    case green
    case purple
    case orange

    var accentColor: Color {
        switch self {
        case .system: return Color.accentColor
        case .blue: return Color.blue
        case .green: return Color.green
        case .purple: return Color.purple
        case .orange: return Color.orange
        }
    }
}

enum SoundOption: String, Codable, CaseIterable {
    case systemDefault
    case chime
    case bell
    case tick
    case silent
}
