import Foundation
import SwiftUI
import UIKit

@MainActor final class AppStore: ObservableObject {
    @Published var locations: [HomeLocation] = []
    @Published var devices: [RingDevice] = []
    @Published var events: [ActivityEvent] = []
    @Published var selectedLocationID = UUID() {
        didSet { if !isLoading { mode = modes[selectedLocationID.uuidString] ?? .disarmed; persist() } }
    }
    @Published var mode: ProtectionMode = .disarmed
    @Published var settings = AppSettings()
    @Published var persistenceError: String?
    @Published var operationMessage: String?
    private var modes: [String: ProtectionMode] = [:]
    private var isLoading = true
    private let storageURL: URL

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? URL.documentsDirectory.appending(path: "ring-rebuilt-home.json")
        defer { isLoading = false }
        if FileManager.default.fileExists(atPath: self.storageURL.path) {
            do {
                let snapshot = try JSONDecoder().decode(HomeSnapshot.self, from: Data(contentsOf: self.storageURL))
                guard snapshot.schemaVersion == 1, !snapshot.locations.isEmpty else { throw StoreError.invalidData }
                locations = snapshot.locations; devices = snapshot.devices; events = snapshot.events
                selectedLocationID = locations.contains(where: { $0.id == snapshot.selectedLocationID })
                    ? snapshot.selectedLocationID : locations[0].id
                modes = snapshot.modes ?? [selectedLocationID.uuidString: snapshot.mode]
                mode = modes[selectedLocationID.uuidString] ?? .disarmed; settings = snapshot.settings
            } catch {
                // Never overwrite an unreadable home with fresh demo data.
                seedDemo()
                persistenceError = "Saved home could not be read. Demo data is shown. Your saved file has been kept."
            }
        } else {
            seedDemo()
            isLoading = false
            persist()
        }
    }
    var currentLocation: HomeLocation {
        locations.first(where: { $0.id == selectedLocationID }) ?? locations.first
            ?? HomeLocation(name: "My Home", address: "")
    }
    var visibleDevices: [RingDevice] { devices.filter { $0.locationID == selectedLocationID } }
    var visibleEvents: [ActivityEvent] {
        events.filter { $0.locationID == selectedLocationID }.sorted { $0.timestamp > $1.timestamp }
    }
    var unreadCount: Int { visibleEvents.filter { !$0.isRead }.count }
    func device(id: UUID) -> RingDevice? { devices.first { $0.id == id } }
    func event(id: UUID) -> ActivityEvent? { events.first { $0.id == id } }

    func saveDevice(_ device: RingDevice) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        var safe = device
        safe.name = String(safe.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !safe.name.isEmpty, locations.contains(where: { $0.id == safe.locationID }) else { return }
        safe.volume = min(1, max(0, safe.volume))
        safe.sensitivity = min(1, max(0, safe.sensitivity))
        safe.zones = safe.zones.map {
            let x = min(0.9, max(0, $0.x)), y = min(0.9, max(0, $0.y))
            return MotionZone(id: $0.id, x: x, y: y, width: min(1-x, max(0.1, $0.width)), height: min(1-y, max(0.1, $0.height)))
        }
        devices[index] = safe
        persist()
    }
    func addDevice(name: String, kind: DeviceKind, locationID: UUID, setupCode: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, locations.contains(where: { $0.id == locationID }) else { return }
        let device = RingDevice(locationID: locationID, name: String(name.prefix(80)), kind: kind,
                                battery: kind == .chime || kind == .alarm ? nil : 100)
        devices.append(device)
        // This creates a local demo device. Setup secrets never leave memory or enter storage.
        appendEvent(deviceID: device.id, locationID: locationID, kind: .deviceAdded, title: "\(device.name) added to demo home")
        selectedLocationID = locationID
        persist()
    }
    func removeDevice(id: UUID) {
        devices.removeAll { $0.id == id }
        // Keep historical events; removed device references safely render using their stored titles.
        persist()
    }
    func addLocation(name: String, address: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let location = HomeLocation(name: String(name.prefix(80)), address: String(address.prefix(240)))
        locations.append(location); selectedLocationID = location.id; persist()
    }
    func saveLocation(_ location: HomeLocation) {
        guard let index = locations.firstIndex(where: { $0.id == location.id }),
              !location.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        locations[index] = HomeLocation(id: location.id, name: String(location.name.prefix(80)), address: String(location.address.prefix(240)))
        persist()
    }
    func saveSettings(_ settings: AppSettings) { self.settings = settings; persist() }
    func setMode(_ newMode: ProtectionMode) {
        guard mode != newMode else { return }
        mode = newMode
        modes[selectedLocationID.uuidString] = newMode
        appendEvent(deviceID: nil, locationID: selectedLocationID, kind: .modeChange,
                    title: "Demo mode changed to \(newMode.title)")
        feedback(); persist()
    }
    func simulateEvent(deviceID: UUID, kind: EventKind) {
        guard let device = device(id: deviceID) else { return }
        if (kind == .motion || kind == .person) && !device.motionDetection {
            operationMessage = "Motion detection is off for this demo device."; return
        }
        appendEvent(deviceID: deviceID, locationID: device.locationID, kind: kind,
                    title: "\(kind.title) at \(device.name)")
        let isMotion = kind == .motion || kind == .person
        let wantsAlert = settings.notificationsEnabled &&
            (!isMotion || (settings.motionNotifications && device.motionAlerts)) &&
            (kind != .ding || (settings.doorbellNotifications && device.ringAlerts))
        if wantsAlert { operationMessage = "Demo alert: \(kind.title) at \(device.name)"; feedback() }
        persist()
    }
    func snapshot(deviceID: UUID) {
        // A demo snapshot is an activity marker, not a captured image.
        simulateEvent(deviceID: deviceID, kind: .snapshot)
        operationMessage = "Demo snapshot marker added to History. No camera image was captured."
    }
    func toggleFavorite(id: UUID) {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return }
        events[i].isFavorite.toggle(); persist()
    }
    func markRead(id: UUID) {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return }
        events[i].isRead = true; persist()
    }
    func deleteEvent(id: UUID) {
        guard let event = event(id: id), !event.isFavorite else {
            operationMessage = "Unstar this event before deleting it."; return
        }
        events.removeAll { $0.id == id }; persist()
    }
    func saveRecordingURL(eventID: UUID, value: String) -> Bool {
        guard let i = events.firstIndex(where: { $0.id == eventID }),
              value.isEmpty || StreamValidation.url(from: value) != nil else { return false }
        events[i].recordingURL = value.trimmingCharacters(in: .whitespacesAndNewlines)
        persist(); return true
    }
    func exportData() -> Data {
        var snapshot = makeSnapshot()
        for index in snapshot.devices.indices { snapshot.devices[index].streamURL = "" }
        for index in snapshot.events.indices { snapshot.events[index].recordingURL = "" }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(snapshot)) ?? Data()
    }
    func resetDemo() { persistenceError = nil; seedDemo(); persist() }
    func retrySave() { persistenceError = nil; persist() }
    private func feedback() {
        if settings.hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }
    private func appendEvent(deviceID: UUID?, locationID: UUID, kind: EventKind, title: String) {
        events.insert(ActivityEvent(deviceID: deviceID, locationID: locationID, kind: kind, title: title), at: 0)
    }
    private func makeSnapshot() -> HomeSnapshot {
        HomeSnapshot(locations: locations, devices: devices, events: events,
                     selectedLocationID: selectedLocationID, mode: mode, modes: modes, settings: settings)
    }
    private func persist() {
        guard !isLoading, persistenceError == nil else { return }
        do {
            let data = try JSONEncoder().encode(makeSnapshot())
            try data.write(to: storageURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
            var url = storageURL
            var values = URLResourceValues(); values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
        } catch { persistenceError = "Your latest changes could not be saved. Check available storage and try again." }
    }
    private func seedDemo() {
        let home = HomeLocation(name: "My Home", address: "Demo location")
        modes = [home.id.uuidString: .disarmed]
        locations = [home]; selectedLocationID = home.id; mode = .disarmed; settings = AppSettings()
        let front = RingDevice(locationID: home.id, name: "Front Door", kind: .doorbell, battery: 87)
        let driveway = RingDevice(locationID: home.id, name: "Driveway", kind: .camera, battery: nil)
        let garden = RingDevice(locationID: home.id, name: "Back Garden", kind: .camera, isOnline: false, battery: 24)
        let alarm = RingDevice(locationID: home.id, name: "Base Station", kind: .alarm, battery: nil)
        let light = RingDevice(locationID: home.id, name: "Porch Light", kind: .light, battery: nil)
        devices = [front, driveway, garden, alarm, light]
        events = [
            ActivityEvent(deviceID: front.id, locationID: home.id, kind: .person, title: "Person at Front Door", timestamp: .now.addingTimeInterval(-180)),
            ActivityEvent(deviceID: front.id, locationID: home.id, kind: .ding, title: "Someone rang Front Door", timestamp: .now.addingTimeInterval(-1200)),
            ActivityEvent(deviceID: driveway.id, locationID: home.id, kind: .motion, title: "Motion at Driveway", timestamp: .now.addingTimeInterval(-4800), isFavorite: true),
            ActivityEvent(deviceID: front.id, locationID: home.id, kind: .motion, title: "Motion at Front Door", timestamp: .now.addingTimeInterval(-86400), isRead: true)
        ]
    }
    enum StoreError: Error { case invalidData }
}

