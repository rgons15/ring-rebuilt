import Foundation
import SwiftUI

enum DeviceKind: String, Codable, CaseIterable, Identifiable {
    case doorbell, camera, alarm, chime, light, lock, sensor
    var id: String { rawValue }
    var title: String {
        switch self { case .doorbell: return "Video Doorbell"; case .camera: return "Security Camera"
        case .alarm: return "Alarm Base Station"; case .chime: return "Chime"; case .light: return "Smart Light"
        case .lock: return "Door Lock"; case .sensor: return "Contact Sensor" }
    }
    var icon: String {
        switch self { case .doorbell: return "doorbell.video"; case .camera: return "web.camera"
        case .alarm: return "shield.lefthalf.filled"; case .chime: return "speaker.wave.2"
        case .light: return "lightbulb"; case .lock: return "lock"; case .sensor: return "sensor" }
    }
    var supportsVideo: Bool { self == .doorbell || self == .camera }
}
enum ProtectionMode: String, Codable, CaseIterable, Identifiable {
    case disarmed, home, away
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String { switch self { case .disarmed: return "shield.slash"; case .home: return "house"; case .away: return "shield.checkered" } }
}
enum EventKind: String, Codable, CaseIterable, Identifiable {
    case motion, ding, person, alarm, modeChange, deviceAdded, deviceUpdated, snapshot
    var id: String { rawValue }
    var title: String {
        switch self { case .motion: return "Motion"; case .ding: return "Doorbell"; case .person: return "Person"
        case .alarm: return "Alarm"; case .modeChange: return "Mode change"; case .deviceAdded: return "Device added"
        case .deviceUpdated: return "Device updated"; case .snapshot: return "Snapshot" }
    }
    var icon: String {
        switch self { case .motion: return "figure.walk"; case .ding: return "bell"; case .person: return "person.crop.rectangle"
        case .alarm: return "exclamationmark.shield"; case .modeChange: return "shield"; case .deviceAdded: return "plus.circle"
        case .deviceUpdated: return "gearshape"; case .snapshot: return "camera" }
    }
}
struct HomeLocation: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var address: String
}
struct MotionZone: Identifiable, Codable, Equatable {
    var id = UUID()
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
enum VideoBandwidth: String, Codable, CaseIterable, Identifiable {
    case minimal, balanced, maximum
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
struct RingDevice: Identifiable, Codable, Equatable {
    var id = UUID()
    var locationID: UUID
    var name: String
    var kind: DeviceKind
    var isOnline = true
    var motionDetection = true
    var motionAlerts = true
    var ringAlerts = true
    var volume: Double = 0.7
    var battery: Int? = 87
    var streamURL = ""
    var liveViewEnabled = true
    var hdrEnabled = false
    var nightVision = true
    var bandwidth: VideoBandwidth = .balanced
    var lightOn = false
    var isLocked = true
    var sensitivity: Double = 0.5
    var zones: [MotionZone] = [MotionZone(x: 0.12, y: 0.25, width: 0.76, height: 0.6)]
}
struct ActivityEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var deviceID: UUID?
    var locationID: UUID
    var kind: EventKind
    var title: String
    var timestamp = Date()
    var isFavorite = false
    var isRead = false
    var recordingURL = ""
}
struct AppSettings: Codable, Equatable {
    var notificationsEnabled = true
    var motionNotifications = true
    var doorbellNotifications = true
    var hapticsEnabled = true
    var appearance = "system"
}
struct HomeSnapshot: Codable {
    var schemaVersion = 1
    var locations: [HomeLocation]
    var devices: [RingDevice]
    var events: [ActivityEvent]
    var selectedLocationID: UUID
    var mode: ProtectionMode
    var modes: [String: ProtectionMode]? = nil
    var settings: AppSettings
}
enum StreamValidation {
    static func url(from value: String) -> URL? {
        guard let components = URLComponents(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "https", components.host != nil,
              components.user == nil, components.password == nil,
              let url = components.url else { return nil }
        return url
    }
}

