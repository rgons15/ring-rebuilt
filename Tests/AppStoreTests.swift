import XCTest
@testable import RingRebuilt

@MainActor final class AppStoreTests: XCTestCase {
    private func path() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appending(path: "home.json")
    }
    func testChangesSurviveReloadAndLocationsRemainIsolated() throws {
        let url = try path()
        let store = AppStore(storageURL: url)
        let firstLocation = store.currentLocation.id
        store.setMode(.away)
        store.addLocation(name: "Second Home", address: "")
        XCTAssertEqual(store.mode, .disarmed)
        XCTAssertTrue(store.visibleDevices.isEmpty)
        store.setMode(.home)
        store.selectedLocationID = firstLocation
        XCTAssertEqual(store.mode, .away)
        var device = try XCTUnwrap(store.visibleDevices.first)
        device.name = "Updated door"
        store.saveDevice(device)
        let restored = AppStore(storageURL: url)
        XCTAssertEqual(restored.device(id: device.id)?.name, "Updated door")
        XCTAssertEqual(restored.mode, .away)
        XCTAssertNil(restored.persistenceError)
    }
    func testStarredEventCannotBeDeletedUntilUnstarred() throws {
        let store = AppStore(storageURL: try path())
        let event = try XCTUnwrap(store.visibleEvents.first)
        store.toggleFavorite(id: event.id)
        store.deleteEvent(id: event.id)
        XCTAssertNotNil(store.event(id: event.id))
        store.toggleFavorite(id: event.id)
        store.deleteEvent(id: event.id)
        XCTAssertNil(store.event(id: event.id))
    }
    func testExportsOmitVideoURLsAndRawSetupCodes() throws {
        let store = AppStore(storageURL: try path())
        var device = try XCTUnwrap(store.visibleDevices.first)
        let secret = "https://example.invalid/live.m3u8?token=private-token"
        device.streamURL = secret
        store.saveDevice(device)
        let event = try XCTUnwrap(store.visibleEvents.first)
        XCTAssertTrue(store.saveRecordingURL(eventID: event.id, value: secret))
        store.addDevice(name: "Demo lock", kind: .lock, locationID: store.currentLocation.id, setupCode: "SECRET-SETUP-CODE")
        let export = String(decoding: store.exportData(), as: UTF8.self)
        XCTAssertFalse(export.contains("private-token"))
        XCTAssertFalse(export.contains("SECRET-SETUP-CODE"))
        XCTAssertTrue(export.contains("Demo lock"))
    }
    func testMotionAndAlertPreferencesAffectSimulation() throws {
        let store = AppStore(storageURL: try path())
        var device = try XCTUnwrap(store.visibleDevices.first)
        device.motionDetection = false
        store.saveDevice(device)
        let count = store.events.count
        store.simulateEvent(deviceID: device.id, kind: .motion)
        XCTAssertEqual(store.events.count, count)
        device.motionDetection = true
        device.motionAlerts = false
        store.saveDevice(device)
        store.operationMessage = nil
        store.simulateEvent(deviceID: device.id, kind: .motion)
        XCTAssertEqual(store.events.count, count + 1)
        XCTAssertNil(store.operationMessage)
    }
    func testZonesAndVolumeAreClamped() throws {
        let store = AppStore(storageURL: try path())
        var device = try XCTUnwrap(store.visibleDevices.first)
        device.volume = 50
        device.sensitivity = -10
        device.zones = [MotionZone(x: -1, y: 4, width: 9, height: 2)]
        store.saveDevice(device)
        let saved = try XCTUnwrap(store.device(id: device.id))
        XCTAssertEqual(saved.volume, 1)
        XCTAssertEqual(saved.sensitivity, 0)
        let zone = try XCTUnwrap(saved.zones.first)
        XCTAssertGreaterThanOrEqual(zone.x, 0)
        XCTAssertLessThanOrEqual(zone.x + zone.width, 1)
        XCTAssertLessThanOrEqual(zone.y + zone.height, 1)
    }
    func testUnreadableFileIsNotOverwrittenAutomatically() throws {
        let url = try path()
        let original = Data("invalid snapshot".utf8)
        try original.write(to: url)
        let store = AppStore(storageURL: url)
        XCTAssertNotNil(store.persistenceError)
        store.setMode(.away)
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
    func testStreamValidationRejectsUnsafeOrMalformedInputs() {
        XCTAssertNil(StreamValidation.url(from: "http://example.com/a.m3u8"))
        XCTAssertNil(StreamValidation.url(from: "https://user:secret@example.com/a.m3u8"))
        XCTAssertNil(StreamValidation.url(from: "file:///private/data"))
        XCTAssertNotNil(StreamValidation.url(from: "https://example.com/a.m3u8"))
    }
}

