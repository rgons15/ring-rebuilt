import SwiftUI

@main @MainActor struct RingRebuiltApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(.ringBlue)
                .preferredColorScheme(store.settings.appearance == "dark" ? .dark : store.settings.appearance == "light" ? .light : nil)
        }
    }
}
@MainActor struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection = 0
    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }.tag(0)
            NavigationStack { DevicesListView() }
                .tabItem { Label("Devices", systemImage: "video") }.tag(1)
            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .badge(store.unreadCount).tag(2)
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }.tag(3)
        }
        .safeAreaInset(edge: .bottom) {
            if store.persistenceError != nil {
                HStack {
                    Label("Changes are not saved", systemImage: "externaldrive.badge.exclamationmark")
                        .font(.caption)
                    Spacer()
                    Button("Retry") { store.retrySave() }.font(.caption.bold())
                }.padding(12).background(.regularMaterial)
            }
        }
        .overlay(alignment: .top) {
            if let message = store.operationMessage {
                HStack(alignment: .top) {
                    Image(systemName: "info.circle")
                    Text(message).font(.callout)
                    Button { store.operationMessage = nil } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("Dismiss message")
                }
                .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding().onTapGesture { store.operationMessage = nil }
            }
        }
    }
}

@MainActor struct DevicesListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var filter: DeviceKind?
    @State private var adding = false
    private var filtered: [RingDevice] {
        store.visibleDevices.filter { (filter == nil || $0.kind == filter) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(store.currentLocation.name).font(.subheadline).foregroundStyle(.secondary)
                    Spacer(); DemoBadge()
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterButton("All", kind: nil)
                        ForEach(DeviceKind.allCases) { kind in filterButton(kind.title, kind: kind) }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView(search.isEmpty ? "No devices here" : "No matching devices",
                                           systemImage: "video.slash",
                                           description: Text(search.isEmpty ? "Add a demo device to start exploring." : "Try another name or category."))
                    if search.isEmpty { Button("Set Up a Device") { adding = true }.buttonStyle(.borderedProminent) }
                }
                ForEach(filtered) { device in
                    NavigationLink {
                        DeviceDetailView(deviceID: device.id)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: device.kind.icon).font(.title2).foregroundStyle(Color.ringBlue)
                                .frame(width: 50, height: 54).background(Color.ringBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(device.name).font(.headline).foregroundStyle(Color.ringInk)
                                Text(device.kind.title).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 5) {
                                Text(device.isOnline ? "Online" : "Offline")
                                    .font(.caption).foregroundStyle(device.isOnline ? .green : .secondary)
                                if let battery = device.battery {
                                    Label("\(battery)%", systemImage: battery < 25 ? "battery.25percent" : "battery.75percent")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }.padding().ringCard()
                    }.buttonStyle(.plain)
                }
                Text("Demo devices stay on this iPhone. Hardware pairing and Ring account access are not connected.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
        .background(Color.ringBackground)
        .navigationTitle("Devices")
        .searchable(text: $search, prompt: "Find a device")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add device") } }
        .sheet(isPresented: $adding) { DeviceSetupView().environmentObject(store) }
    }
    private func filterButton(_ title: String, kind: DeviceKind?) -> some View {
        Button { filter = kind } label: {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 16).padding(.vertical, 10)
                .background(filter == kind ? Color.ringBlue : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                .foregroundStyle(filter == kind ? .white : Color.ringInk)
        }.buttonStyle(.plain).accessibilityAddTraits(filter == kind ? .isSelected : [])
    }
}

