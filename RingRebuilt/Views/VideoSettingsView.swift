import SwiftUI

@MainActor struct VideoSettingsView: View {
    @EnvironmentObject private var store: AppStore
    let deviceID: UUID

    private func preference(_ keyPath: WritableKeyPath<RingDevice, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.device(id: deviceID)?[keyPath: keyPath] ?? false },
            set: { value in
                guard var device = store.device(id: deviceID) else { return }
                device[keyPath: keyPath] = value
                store.saveDevice(device)
            }
        )
    }

    var body: some View {
        Form {
            if store.device(id: deviceID) != nil {
                Section("Video Preferences") {
                    Toggle("Live View", isOn: preference(\.liveViewEnabled))
                    Toggle("HDR", isOn: preference(\.hdrEnabled))
                    Toggle("Night Vision", isOn: preference(\.nightVision))
                    Picker("Bandwidth", selection: Binding(
                        get: { store.device(id: deviceID)?.bandwidth ?? .balanced },
                        set: { value in
                            guard var device = store.device(id: deviceID) else { return }
                            device.bandwidth = value
                            store.saveDevice(device)
                        }
                    )) {
                        Text(VideoBandwidth.minimal.title).tag(VideoBandwidth.minimal)
                        Text(VideoBandwidth.balanced.title).tag(VideoBandwidth.balanced)
                        Text(VideoBandwidth.maximum.title).tag(VideoBandwidth.maximum)
                    }
                }
                Section {
                    Text("These per-device preferences are saved locally. HDR, night vision and bandwidth do not alter a supplied video stream or configure camera hardware.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Your Video Source") {
                    NavigationLink { StreamConnectionView(deviceID: deviceID) } label: {
                        Label("Configure Video URL", systemImage: "link")
                    }
                    Text("Use a compatible HTTPS video source you are authorized to access. No Ring account or Ring live-video service is connected.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView("Device Unavailable", systemImage: "exclamationmark.circle", description: Text("This device is no longer in your local demo."))
            }
        }
        .navigationTitle("Video Settings")
    }
}
