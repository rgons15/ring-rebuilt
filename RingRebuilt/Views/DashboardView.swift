import SwiftUI

@MainActor struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var addingDevice = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome home").font(.largeTitle.bold())
                        Text(store.currentLocation.address).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    DemoBadge()
                }
                protectionCard
                HStack {
                    Text("Your devices").font(.title2.bold())
                    Spacer()
                    Button { addingDevice = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }.accessibilityLabel("Add device")
                }
                if store.visibleDevices.isEmpty {
                    ContentUnavailableView("Your home starts here", systemImage: "door.left.hand.open", description: Text("Add a demo device to explore your home."))
                }
                ForEach(store.visibleDevices) { device in
                    NavigationLink { DeviceDetailView(deviceID: device.id) } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            if device.kind == .camera || device.kind == .doorbell {
                                PorchIllustration(night: false).frame(height: 170)
                                    .overlay(alignment: .bottomTrailing) {
                                        Label("View camera", systemImage: "play.fill").font(.caption.bold()).padding(9).background(.ultraThinMaterial, in: Capsule()).padding(12)
                                    }
                            }
                            HStack(spacing: 12) {
                                Image(systemName: device.kind.icon).font(.title3).foregroundStyle(Color.ringBlue).frame(width: 38, height: 38).background(Color.ringBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name).font(.headline).foregroundStyle(Color.ringInk)
                                    HStack(spacing: 5) {
                                        Circle().fill(device.isOnline ? .green : .gray).frame(width: 5, height: 5)
                                        Text(device.isOnline ? "Online" : "Offline")
                                        if let battery = device.battery { Text("•  \(battery)% battery") }
                                    }.font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
                            }.padding(16)
                        }.background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18)).clipShape(RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("Recent activity").font(.headline); Spacer(); Image(systemName: "clock").foregroundStyle(Color.ringBlue) }
                    if store.visibleEvents.isEmpty { Text("All quiet. New activity will appear here.").font(.subheadline).foregroundStyle(.secondary) }
                    ForEach(Array(store.visibleEvents.prefix(3))) { event in
                        NavigationLink { EventPlaybackView(eventID: event.id) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: event.kind.icon).foregroundStyle(Color.ringBlue).frame(width: 25)
                                VStack(alignment: .leading) { Text(event.title).font(.subheadline.weight(.medium)); Text(event.timestamp, style: .relative).font(.caption).foregroundStyle(.secondary) }
                                Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }.foregroundStyle(Color.ringInk)
                        }
                    }
                }.ringCard()
                Text("Demo home · Controls update local data. No Ring account or devices are connected.").font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.background(Color.ringBackground)
        .navigationTitle(store.currentLocation.name).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu { ForEach(store.locations) { location in Button(location.name) { store.selectedLocationID = location.id } } } label: { Image(systemName: "house.fill") }.accessibilityLabel("Select home")
            }
            ToolbarItem(placement: .topBarTrailing) { NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings") }
        }
        .sheet(isPresented: $addingDevice) { DeviceSetupView() }
    }
    private var protectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.lefthalf.filled").font(.title2).foregroundStyle(Color.ringBlue)
                VStack(alignment: .leading, spacing: 3) { Text("Home protection").font(.headline); Text("Demo mode: \(store.mode.title)").font(.caption).foregroundStyle(.secondary) }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(ProtectionMode.allCases) { mode in
                    Button { store.setMode(mode) } label: {
                        VStack(spacing: 8) { Image(systemName: mode.icon).font(.title3); Text(mode.title).font(.caption.bold()) }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .foregroundStyle(store.mode == mode ? .white : Color.ringInk)
                            .background(store.mode == mode ? Color.ringBlue : Color.ringBackground, in: RoundedRectangle(cornerRadius: 12))
                    }.accessibilityLabel("Set demo protection to \(mode.title)")
                }
            }
        }.ringCard()
    }
}
