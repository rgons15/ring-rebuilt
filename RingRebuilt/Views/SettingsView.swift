import SwiftUI

@MainActor struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editingLocation: HomeLocation?
    @State private var addingLocation = false
    @State private var resetRequested = false
    @State private var exportURL: URL?
    @State private var exportError: String?

    private func preference(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(get: { store.settings[keyPath: keyPath] }, set: { value in var settings = store.settings; settings[keyPath: keyPath] = value; store.saveSettings(settings) })
    }
    var body: some View {
        Form {
            Section {
                Label("Independent local demo", systemImage: "info.circle")
                Text("This app is not affiliated with Ring. Settings affect this local project only. No Ring account, subscription, cloud recording, emergency dispatch, or hardware pairing is connected.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Locations") {
                ForEach(store.locations) { location in
                    Button { editingLocation = location } label: {
                        HStack { VStack(alignment: .leading) { Text(location.name).foregroundStyle(.primary); if !location.address.isEmpty { Text(location.address).font(.caption).foregroundStyle(.secondary) } }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }
                    }.accessibilityLabel("Edit location \(location.name)")
                }
                Button("Add Location", systemImage: "plus") { addingLocation = true }
            }
            Section {
                Toggle("Notifications", isOn: preference(\.notificationsEnabled))
                Toggle("Motion alerts", isOn: preference(\.motionNotifications)).disabled(!store.settings.notificationsEnabled)
                Toggle("Doorbell alerts", isOn: preference(\.doorbellNotifications)).disabled(!store.settings.notificationsEnabled)
                Text("Preferences are saved locally. This demo does not receive remote Ring notifications.").font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Notification Preferences") }
            Section("Appearance & Feedback") {
                Picker("Appearance", selection: Binding(get: { store.settings.appearance }, set: { value in var settings = store.settings; settings.appearance = value; store.saveSettings(settings) })) {
                    Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                }
                Toggle("Haptic feedback", isOn: preference(\.hapticsEnabled))
            }
            Section("Local Data") {
                Button("Prepare Data Export", systemImage: "square.and.arrow.up") { prepareExport() }
                if let url = exportURL { ShareLink("Share Export", item: url) }
                Text("Exports local demo data with stream URLs omitted. Review the file before sharing.").font(.footnote).foregroundStyle(.secondary)
                if let exportError { Text(exportError).foregroundStyle(.red) }
                Button("Reset Demo", role: .destructive) { resetRequested = true }
            }
            if let error = store.persistenceError { Section("Storage Error") { Text(error).foregroundStyle(.red) } }
        }
        .navigationTitle("Settings")
        .sheet(item: $editingLocation) { location in LocationEditor(location: location) }
        .sheet(isPresented: $addingLocation) { LocationEditor(location: nil) }
        .confirmationDialog("Reset all local demo data?", isPresented: $resetRequested, titleVisibility: .visible) {
            Button("Reset Demo", role: .destructive) { store.resetDemo(); exportURL = nil }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Your local devices, events, locations and preferences will be replaced by the initial sample data.") }
    }
    private func prepareExport() {
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ring-demo-export-\(UUID().uuidString).json")
            try store.exportData().write(to: url, options: .atomic)
            exportURL = url; exportError = nil
        } catch { exportError = "Could not export data: \(error.localizedDescription)" }
    }
}

private struct LocationEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let location: HomeLocation?
    @State private var name: String
    @State private var address: String
    init(location: HomeLocation?) {
        self.location = location
        _name = State(initialValue: location?.name ?? "")
        _address = State(initialValue: location?.address ?? "")
    }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Location name", text: $name)
                TextField("Address (optional)", text: $address).textContentType(.fullStreetAddress)
                Text("Locations stay on this device.").font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle(location == nil ? "Add Location" : "Edit Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
                        if var existing = location { existing.name = cleanName; existing.address = cleanAddress; store.saveLocation(existing) }
                        else { store.addLocation(name: cleanName, address: cleanAddress) }
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
