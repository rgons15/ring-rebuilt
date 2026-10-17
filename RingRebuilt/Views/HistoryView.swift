import SwiftUI

@MainActor struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var filter: HistoryFilter = .all
    @State private var pendingDeletion: UUID?
    @State private var confirmingDeletion = false
    private enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All", motion = "Motion", doorbell = "Doorbell", favorites = "Favorites"
        var id: String { rawValue }
    }
    private var filteredEvents: [ActivityEvent] {
        store.visibleEvents.filter { event in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .motion: matchesFilter = event.kind == .motion || event.kind == .person
            case .doorbell: matchesFilter = event.kind == .ding
            case .favorites: matchesFilter = event.isFavorite
            }
            return matchesFilter && (search.isEmpty || event.title.localizedCaseInsensitiveContains(search) || deviceName(for: event).localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HistoryFilter.allCases) { value in
                        Button { filter = value } label: {
                            Text(value.rawValue).font(.subheadline.weight(.semibold)).padding(.horizontal, 17).padding(.vertical, 10)
                                .foregroundStyle(filter == value ? .white : Color.ringInk)
                                .background(filter == value ? Color.ringBlue : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                        }
                    }
                }.padding(.horizontal, 20).padding(.vertical, 12)
            }
            if filteredEvents.isEmpty {
                ContentUnavailableView("No activity yet", systemImage: "clock.badge.checkmark", description: Text("Try another filter or generate an event from a demo device."))
            } else {
                List {
                    ForEach(filteredEvents) { event in
                        NavigationLink {
                            EventPlaybackView(eventID: event.id).onAppear { store.markRead(id: event.id) }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack(alignment: .bottomTrailing) {
                                    RoundedRectangle(cornerRadius: 13).fill(Color.ringBlue.opacity(0.08)).frame(width: 56, height: 56)
                                    Image(systemName: event.kind.icon).font(.title2).foregroundStyle(Color.ringBlue).frame(width: 56, height: 56)
                                    if !event.isRead { Circle().fill(Color.ringBlue).frame(width: 9, height: 9).overlay(Circle().stroke(.white, lineWidth: 2)).offset(x: 2, y: 2) }
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(event.title).font(.subheadline.weight(event.isRead ? .medium : .bold)).foregroundStyle(Color.ringInk)
                                    Text(deviceName(for: event)).font(.caption).foregroundStyle(.secondary)
                                    HStack(spacing: 5) { Text(event.timestamp, style: .date); Text("·"); Text(event.timestamp, style: .time) }.font(.caption2).foregroundStyle(.secondary)
                                }.padding(.vertical, 2)
                                Spacer(minLength: 0)
                                if event.isFavorite { Image(systemName: "star.fill").font(.caption).foregroundStyle(.orange).padding(.top, 4) }
                            }.padding(.vertical, 6)
                        }
                        .swipeActions(edge: .leading) {
                            Button { store.toggleFavorite(id: event.id) } label: { Label(event.isFavorite ? "Unfavorite" : "Favorite", systemImage: event.isFavorite ? "star.slash" : "star") }.tint(.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !event.isFavorite {
                                Button(role: .destructive) { pendingDeletion = event.id; confirmingDeletion = true } label: { Label("Delete", systemImage: "trash") }
                            }
                            if !event.isRead { Button { store.markRead(id: event.id) } label: { Label("Read", systemImage: "envelope.open") }.tint(.ringBlue) }
                        }
                        .contextMenu {
                            Button(event.isFavorite ? "Remove favorite" : "Add favorite", systemImage: "star") { store.toggleFavorite(id: event.id) }
                            if !event.isFavorite { Button("Delete event", systemImage: "trash", role: .destructive) { pendingDeletion = event.id; confirmingDeletion = true } }
                        }
                    }
                }.listStyle(.plain).scrollContentBackground(.hidden)
            }
        }.background(Color.ringBackground).navigationTitle("History")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { DemoBadge() } }
        .searchable(text: $search, prompt: "Search events or devices")
        .confirmationDialog("Delete this demo event?", isPresented: $confirmingDeletion, titleVisibility: .visible) {
            Button("Delete event", role: .destructive) { if let id = pendingDeletion { store.deleteEvent(id: id) }; pendingDeletion = nil }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { Text("This removes the event from local history. Favorited events are protected from deletion.") }
    }
    private func deviceName(for event: ActivityEvent) -> String {
        if let id = event.deviceID, let device = store.device(id: id) { return device.name }
        return store.currentLocation.name
    }
}
