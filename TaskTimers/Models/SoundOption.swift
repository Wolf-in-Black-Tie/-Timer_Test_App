import AVFoundation
import Foundation

/// Built-in system sounds to choose from.
enum SoundOption: String, CaseIterable, Identifiable, Codable {
    case bell
    case chord
    case alert
    case glass
    case tick

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bell: return "Bell"
        case .chord: return "Chord"
        case .alert: return "Alert"
        case .glass: return "Glass"
        case .tick: return "Tick"
        }
    }

    var systemSoundID: SystemSoundID {
        switch self {
        case .bell: return 1013
        case .chord: return 1315
        case .alert: return 1005
        case .glass: return 1100
        case .tick: return 1111
        }
    }
}
