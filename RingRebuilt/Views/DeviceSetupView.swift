import SwiftUI

@MainActor struct DeviceSetupView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var scanning = false
    @State private var step = 0
    @State private var kind: DeviceKind = .doorbell
    @State private var code = ""
    @State private var name = ""
    @State private var locationID: UUID?

    private var validCode: Bool { code.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4 }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Local demonstration", systemImage: "info.circle")
                    Text("This creates a device in this app only. It does not pair Ring hardware or connect to Ring services.").font(.footnote).foregroundStyle(.secondary)
                }
                if step == 0 {
                    Section("Choose a device") {
                        ForEach(DeviceKind.allCases) { item in
                            Button { kind = item } label: {
                                HStack { Label(item.title, systemImage: item.icon); Spacer(); if kind == item { Image(systemName: "checkmark.circle.fill") } }
                            }.foregroundStyle(kind == item ? Color.ringBlue : Color.primary)
                            .accessibilityAddTraits(kind == item ? [.isSelected] : [])
                        }
                    }
                } else if step == 1 {
                    Section("Setup code") {
                        Button("Scan a QR Code", systemImage: "qrcode.viewfinder") { scanning = true }
                        TextField("Enter at least 4 characters", text: $code).textInputAutocapitalization(.characters).autocorrectionDisabled().privacySensitive()
                        Text("Use a made-up code for this demo. The code is not retained. This does not validate or activate a physical device.").font(.footnote).foregroundStyle(.secondary)
                    }
                } else {
                    Section("Device details") {
                        TextField("Device name", text: $name)
                        Picker("Location", selection: $locationID) {
                            ForEach(store.locations) { location in Text(location.name).tag(Optional(location.id)) }
                        }
                        LabeledContent("Device type", value: kind.title)
                    }
                    Section { Text("You can explore local controls after adding the device. Live video requires your own compatible stream URL in device settings.").font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle(step == 0 ? "Set Up a Device" : step == 1 ? "Setup Code" : "Name Your Device")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(step == 2 ? "Add" : "Next") {
                        if step < 2 { step += 1; if name.isEmpty { name = kind.title } }
                        else if let id = locationID { store.addDevice(name: name.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, locationID: id, setupCode: code.trimmingCharacters(in: .whitespacesAndNewlines)); dismiss() }
                    }.disabled(step == 1 ? !validCode : step == 2 && (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locationID == nil))
                }
                ToolbarItem(placement: .bottomBar) { if step > 0 { Button("Back") { step -= 1 } } }
            }
            .sheet(isPresented: $scanning) { QRScannerView { code = $0 } }
            .onAppear { locationID = store.currentLocation.id }
        }
    }
}
