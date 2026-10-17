import SwiftUI

@MainActor struct DeviceDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let deviceID: UUID
    @State private var renaming = false
    @State private var name = ""
    @State private var removing = false
    var body: some View {
        Group {
            if let device = store.device(id: deviceID) {
                ScrollView {
                    VStack(spacing: 20) {
                        if device.kind == .camera || device.kind == .doorbell {
                            NavigationLink { LiveView(deviceID: deviceID) } label: {
                                PorchIllustration().frame(height: 230).overlay {
                                    Image(systemName: "play.fill").font(.title).foregroundStyle(.white).frame(width: 64, height: 64).background(.black.opacity(0.45), in: Circle())
                                }.clipShape(RoundedRectangle(cornerRadius: 18))
                            }.accessibilityLabel("Open \(device.name) demo live view")
                        }
                        HStack {
                            Label(device.isOnline ? "Online" : "Offline", systemImage: device.isOnline ? "checkmark.circle.fill" : "wifi.slash").foregroundStyle(device.isOnline ? Color.green : Color.secondary)
                            Spacer()
                            if let battery = device.battery { Label("\(battery)%", systemImage: battery > 20 ? "battery.75percent" : "battery.25percent").foregroundStyle(.secondary) }
                            DemoBadge()
                        }.font(.subheadline).ringCard()
                        VStack(spacing: 16) {
                            Toggle("Motion detection", isOn: binding(\.motionDetection)).tint(.ringBlue)
                            Divider()
                            Toggle("Motion alerts", isOn: binding(\.motionAlerts)).tint(.ringBlue)
                            if device.kind == .doorbell { Divider(); Toggle("Doorbell alerts", isOn: binding(\.ringAlerts)).tint(.ringBlue) }
                            if device.kind == .light || device.kind == .camera { Divider(); Toggle("Light", isOn: binding(\.lightOn)).tint(.ringBlue) }
                            if device.kind == .lock { Divider(); Toggle("Locked", isOn: binding(\.isLocked)).tint(.ringBlue) }
                        }.ringCard()
                        VStack(alignment: .leading, spacing: 16) {
                            NavigationLink { MotionSettingsView(deviceID: deviceID) } label: { detailRow("Motion settings", icon: "figure.walk.motion") }
                            Divider()
                            NavigationLink { VideoSettingsView(deviceID: deviceID) } label: { detailRow("Video settings", icon: "video") }
                            Divider()
                            NavigationLink { DeviceHealthView(deviceID: deviceID) } label: { detailRow("Device health", icon: "heart.text.square") }
                            Divider()
                            VStack(alignment: .leading) {
                                HStack { Label("Device volume", systemImage: "speaker.wave.2"); Spacer(); Text("\(Int(device.volume * 100))%").foregroundStyle(.secondary) }
                                Slider(value: binding(\.volume), in: 0...1).tint(.ringBlue).accessibilityLabel("Device volume")
                            }
                            Divider()
                            Button { name = device.name; renaming = true } label: { detailRow("Device name", icon: "pencil", value: device.name) }
                        }.ringCard()
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Try a demo event").font(.headline)
                            Text("Generate activity to test alerts and history locally.").font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button { store.simulateEvent(deviceID: deviceID, kind: .motion) } label: { Label("Motion", systemImage: "figure.walk") }
                                Spacer()
                                if device.kind == .doorbell { Button { store.simulateEvent(deviceID: deviceID, kind: .ding) } label: { Label("Doorbell", systemImage: "bell") } }
                                Button { store.snapshot(deviceID: deviceID) } label: { Image(systemName: "camera") }.accessibilityLabel("Create demo snapshot")
                            }.buttonStyle(.bordered).tint(.ringBlue)
                        }.ringCard()
                        Text("These controls affect this demo only. They do not arm an alarm, lock a door, or operate a physical device.").font(.caption).foregroundStyle(.secondary)
                        Button("Remove demo device", role: .destructive) { removing = true }.padding(.vertical)
                    }.padding(20)
                }.background(Color.ringBackground).navigationTitle(device.name).navigationBarTitleDisplayMode(.inline)
            } else { ContentUnavailableView("Device unavailable", systemImage: "video.slash") }
        }
        .alert("Rename device", isPresented: $renaming) {
            TextField("Device name", text: $name)
            Button("Cancel", role: .cancel) {}
            Button("Save") { if var device = store.device(id: deviceID), !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { device.name = name.trimmingCharacters(in: .whitespacesAndNewlines); store.saveDevice(device) } }
        }
        .confirmationDialog("Remove this demo device?", isPresented: $removing, titleVisibility: .visible) {
            Button("Remove device", role: .destructive) { store.removeDevice(id: deviceID); dismiss() }
        }
    }
    private func binding<Value>(_ keyPath: WritableKeyPath<RingDevice, Value>) -> Binding<Value> {
        let initial = store.device(id: deviceID)![keyPath: keyPath]
        return Binding(get: { store.device(id: deviceID)?[keyPath: keyPath] ?? initial }, set: { value in
            guard var device = store.device(id: deviceID) else { return }; device[keyPath: keyPath] = value; store.saveDevice(device)
        })
    }
    private func detailRow(_ title: String, icon: String, value: String? = nil) -> some View {
        HStack { Label(title, systemImage: icon); Spacer(); if let value { Text(value).font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary) }.foregroundStyle(Color.ringInk)
    }
}

