import SwiftUI

/// Simple color themes for the timer UI.
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case sunrise
    case ocean
    case forest
    case dusk
    case charcoal

    var id: String { rawValue }

    var name: String {
        switch self {
        case .sunrise: return "Sunrise"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .dusk: return "Dusk"
        case .charcoal: return "Charcoal"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .sunrise:
            return LinearGradient(colors: [.orange.opacity(0.6), .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:
            return LinearGradient(colors: [.teal.opacity(0.7), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(colors: [.green.opacity(0.7), .mint.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dusk:
            return LinearGradient(colors: [.purple.opacity(0.7), .indigo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .charcoal:
            return LinearGradient(colors: [.gray.opacity(0.7), .black.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var accent: Color {
        switch self {
        case .sunrise: return .orange
        case .ocean: return .blue
        case .forest: return .green
        case .dusk: return .purple
        case .charcoal: return .gray
        }
    }
}
