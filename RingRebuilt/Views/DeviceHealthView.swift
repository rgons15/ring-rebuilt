import SwiftUI

@MainActor struct DeviceHealthView: View {
    @EnvironmentObject private var store: AppStore
    let deviceID: UUID

    var body: some View {
        Form {
            if let device = store.device(id: deviceID) {
                Section("Local Device Record") {
                    LabeledContent("Name", value: device.name)
                    LabeledContent("Type", value: device.kind.title)
                    LabeledContent("Demo status", value: device.isOnline ? "Online (simulated)" : "Offline (simulated)")
                    if let battery = device.battery {
                        LabeledContent("Sample battery", value: "\(battery)%")
                    } else {
                        LabeledContent("Battery", value: "Unknown")
                    }
                    Text("These values come from the local demo record. No hardware telemetry is connected.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Hardware & Network") {
                    LabeledContent("Firmware", value: "Unknown")
                    LabeledContent("Serial number", value: "Unknown")
                    LabeledContent("Wi-Fi network", value: "Not connected")
                    LabeledContent("Signal strength", value: "Unknown")
                    LabeledContent("Last hardware check", value: "Never")
                }
                Section {
                    Toggle("Simulate Online Device", isOn: Binding(
                        get: { store.device(id: deviceID)?.isOnline ?? false },
                        set: { value in
                            guard var updated = store.device(id: deviceID) else { return }
                            updated.isOnline = value
                            store.saveDevice(updated)
                        }
                    ))
                    Text("Changes the status displayed in this demo only. It does not connect, disconnect, or test a physical device.")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: { Text("Demo Controls") }
            } else {
                ContentUnavailableView("Device Unavailable", systemImage: "exclamationmark.circle", description: Text("This device is no longer in your local demo."))
            }
        }
        .navigationTitle("Device Health")
    }
}
