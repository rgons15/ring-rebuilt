import SwiftUI

@MainActor struct MotionSettingsView: View {
    @EnvironmentObject private var store: AppStore
    let deviceID: UUID
    private func flag(_ keyPath: WritableKeyPath<RingDevice, Bool>) -> Binding<Bool> {
        Binding(get: { store.device(id: deviceID)?[keyPath: keyPath] ?? false }, set: { value in guard var device = store.device(id: deviceID) else { return }; device[keyPath: keyPath] = value; store.saveDevice(device) })
    }
    var body: some View {
        Form {
            if let device = store.device(id: deviceID) {
                Section {
                    Toggle("Motion Detection", isOn: flag(\.motionDetection))
                    Toggle("Motion Alerts", isOn: flag(\.motionAlerts)).disabled(!device.motionDetection)
                }
                Section("Motion Sensitivity") {
                    Slider(value: Binding(get: { store.device(id: deviceID)?.sensitivity ?? 0.5 }, set: { value in guard var updated = store.device(id: deviceID) else { return }; updated.sensitivity = value; store.saveDevice(updated) }), in: 0...1)
                        .accessibilityLabel("Motion sensitivity").accessibilityValue("\(Int(device.sensitivity * 100)) percent")
                    HStack { Text("Low"); Spacer(); Text("\(Int(device.sensitivity * 100))%"); Spacer(); Text("High") }.font(.caption).foregroundStyle(.secondary)
                }.disabled(!device.motionDetection)
                Section("Detection Areas") {
                    NavigationLink { MotionZoneEditor(deviceID: deviceID) } label: {
                        LabeledContent("Motion Zones", value: "\(device.zones.count)")
                    }
                }
                Section {
                    Text("These controls are saved locally for demonstration. They do not change Ring hardware or run video motion detection.").font(.footnote).foregroundStyle(.secondary)
                }
            } else { Text("This device is no longer available.") }
        }.navigationTitle("Motion Settings")
    }
}

private struct MotionZoneEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let deviceID: UUID
    @State private var zones: [MotionZone] = []
    @State private var selectedID: UUID?
    @State private var loaded = false
    private var selected: MotionZone? { zones.first { $0.id == selectedID } }
    private func coordinate(_ keyPath: WritableKeyPath<MotionZone, Double>) -> Binding<Double> {
        Binding(get: { selected?[keyPath: keyPath] ?? 0 }, set: { value in
            guard let index = zones.firstIndex(where: { $0.id == selectedID }) else { return }
            zones[index][keyPath: keyPath] = value
            zones[index].x = min(max(zones[index].x, 0), 1 - zones[index].width)
            zones[index].y = min(max(zones[index].y, 0), 1 - zones[index].height)
        })
    }
    var body: some View {
        Form {
            Section {
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        Rectangle().fill(Color.secondary.opacity(0.15))
                        VStack { Image(systemName: "camera.viewfinder").font(.largeTitle); Text("Illustrative preview").font(.caption) }.frame(maxWidth: .infinity, maxHeight: .infinity).foregroundStyle(.secondary)
                        ForEach(zones) { zone in
                            RoundedRectangle(cornerRadius: 4).fill(Color.ringBlue.opacity(zone.id == selectedID ? 0.35 : 0.15))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.ringBlue, lineWidth: zone.id == selectedID ? 3 : 1))
                                .frame(width: geometry.size.width * zone.width, height: geometry.size.height * zone.height)
                                .offset(x: geometry.size.width * zone.x, y: geometry.size.height * zone.y)
                                .onTapGesture { selectedID = zone.id }
                                .accessibilityLabel("Detection zone").accessibilityAddTraits(.isButton)
                        }
                    }.clipped()
                }.frame(height: 200)
                Text("Select a zone, then adjust its position and size below. Coordinates are relative to the full frame.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Zones") {
                ForEach(Array(zones.enumerated()), id: \.element.id) { index, zone in
                    Button { selectedID = zone.id } label: {
                        HStack { Text("Zone \(index + 1)"); Spacer(); if selectedID == zone.id { Image(systemName: "checkmark") } }
                    }.accessibilityAddTraits(selectedID == zone.id ? [.isSelected] : [])
                }
                .onDelete { indices in zones.remove(atOffsets: indices); if !zones.contains(where: { $0.id == selectedID }) { selectedID = zones.first?.id } }
                Button("Add Zone", systemImage: "plus") {
                    let zone = MotionZone(x: 0.2, y: 0.2, width: 0.5, height: 0.5)
                    zones.append(zone); selectedID = zone.id
                }.disabled(zones.count >= 3)
            }
            if let zone = selected {
                Section("Selected Zone") {
                    Text("Horizontal position"); Slider(value: coordinate(\.x), in: 0...max(0.001, 1 - zone.width)).accessibilityLabel("Horizontal position")
                    Text("Vertical position"); Slider(value: coordinate(\.y), in: 0...max(0.001, 1 - zone.height)).accessibilityLabel("Vertical position")
                    Text("Width"); Slider(value: coordinate(\.width), in: 0.1...1).accessibilityLabel("Zone width")
                    Text("Height"); Slider(value: coordinate(\.height), in: 0.1...1).accessibilityLabel("Zone height")
                    Button("Delete Selected Zone", role: .destructive) { zones.removeAll { $0.id == selectedID }; selectedID = zones.first?.id }
                }
            }
            Section { Text("Zones are local demo settings and do not configure hardware.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Motion Zones")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { guard var device = store.device(id: deviceID) else { return }; device.zones = zones; store.saveDevice(device); dismiss() }.disabled(store.device(id: deviceID) == nil) } }
        .onAppear { if !loaded { zones = store.device(id: deviceID)?.zones ?? []; selectedID = zones.first?.id; loaded = true } }
    }
}
