import SwiftUI
import AVKit

@MainActor final class StreamPlayer: ObservableObject {
    let player: AVPlayer
    @Published var error: String?
    @Published var loading = true
    private var observation: NSKeyValueObservation?
    init(url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        observation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let status = item.status
            let description = item.error?.localizedDescription
            Task { @MainActor [weak self] in
                self?.loading = status == .unknown
                if status == .failed { self?.error = description ?? "This stream could not be opened." }
            }
        }
    }
}
@MainActor struct StreamPanel: View {
    @StateObject private var stream: StreamPlayer
    let active: Bool
    @Environment(\.scenePhase) private var scenePhase
    init(url: URL, active: Bool = true) {
        self.active = active
        _stream = StateObject(wrappedValue: StreamPlayer(url: url))
    }
    var body: some View {
        ZStack {
            Color.black
            VideoPlayer(player: stream.player)
            if stream.loading { ProgressView("Connecting...").tint(.white).foregroundStyle(.white) }
            if let error = stream.error {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.exclamationmark").font(.largeTitle)
                    Text("Unable to play video").font(.headline)
                    Text(error).font(.caption).multilineTextAlignment(.center)
                }.foregroundStyle(.white).padding().background(.black.opacity(0.8))
            }
        }
        .onAppear { if active { stream.player.play() } }
        .onChange(of: active) { _, value in if value { stream.player.play() } else { stream.player.pause() } }
        .onChange(of: scenePhase) { _, phase in if phase != .active { stream.player.pause() } }
        .onDisappear { stream.player.pause() }
    }
}
@MainActor struct LiveView: View {
    let deviceID: UUID
    @EnvironmentObject private var store: AppStore
    @State private var editingStream = false
    @State private var fullscreen = false
    @State private var showSiren = false
    @State private var sessionEnded = false

    var body: some View {
        Group {
            if let device = store.device(id: deviceID) {
                ScrollView {
                    VStack(spacing: 22) {
                        HStack {
                            Label(device.isOnline ? "Demo device online" : "Demo device offline",
                                  systemImage: device.isOnline ? "circle.fill" : "wifi.slash")
                                .font(.caption.weight(.medium)).foregroundStyle(device.isOnline ? .green : .secondary)
                            Spacer(); DemoBadge()
                        }
                        video(device, active: !fullscreen).frame(height: 250).clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(alignment: .topTrailing) {
                                Button { fullscreen = true } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .padding(12).background(.black.opacity(0.45), in: Circle()).foregroundStyle(.white)
                                }.padding(12).accessibilityLabel("Full screen video")
                            }
                        if sessionEnded {
                            Button("Start viewing") { sessionEnded = false }.buttonStyle(.borderedProminent)
                        } else {
                            HStack(spacing: 14) {
                                action("Talk", icon: "mic.slash") {
                                    store.operationMessage = "Two-way talk needs a supported camera service. Microphone audio is not being transmitted."
                                }
                                action("Snapshot", icon: "camera") { store.snapshot(deviceID: deviceID) }
                                action("End", icon: "phone.down.fill") { sessionEnded = true }
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Video connection").font(.headline)
                            Text("Connect an HTTPS HLS or video URL you are authorized to view. Ring cameras require a separate verified service integration.")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Button(device.streamURL.isEmpty ? "Connect your own stream" : "Edit stream connection") { editingStream = true }
                                .buttonStyle(.bordered)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding().ringCard()
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Demo controls").font(.headline)
                            Text("These controls change this app's local home only.").font(.caption).foregroundStyle(.secondary)
                            if device.kind == .light || device.kind == .camera {
                                Toggle("Lights", isOn: Binding(get: { store.device(id: deviceID)?.lightOn ?? false }, set: {
                                    guard var latest = store.device(id: deviceID) else { return }; latest.lightOn = $0; store.saveDevice(latest)
                                }))
                            }
                            if device.kind == .lock {
                                Toggle("Locked", isOn: Binding(get: { store.device(id: deviceID)?.isLocked ?? true }, set: {
                                    guard var latest = store.device(id: deviceID) else { return }; latest.isLocked = $0; store.saveDevice(latest)
                                }))
                            }
                            Button("Test demo siren", systemImage: "speaker.wave.3") { showSiren = true }
                        }.padding().ringCard()
                    }.padding()
                }
                .background(Color.ringBackground)
                .navigationTitle(device.name)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $editingStream) {
                    NavigationStack { StreamConnectionView(deviceID: deviceID) }.environmentObject(store)
                }
                .fullScreenCover(isPresented: $fullscreen) {
                    ZStack(alignment: .topTrailing) {
                        Color.black.ignoresSafeArea()
                        video(device).ignoresSafeArea()
                        Button("Done") { fullscreen = false }.buttonStyle(.borderedProminent).padding(24)
                    }
                }
                .confirmationDialog("Simulate a siren event?", isPresented: $showSiren, titleVisibility: .visible) {
                    Button("Add demo alarm event") { store.simulateEvent(deviceID: deviceID, kind: .alarm) }
                } message: { Text("No alarm hardware will sound.") }
            } else {
                ContentUnavailableView("Device not found", systemImage: "video.slash",
                                       description: Text("This device may have been removed."))
            }
        }
    }
    @ViewBuilder private func video(_ device: RingDevice, active: Bool = true) -> some View {
        if sessionEnded {
            ZStack { Color.black; Label("Viewing ended", systemImage: "video.slash").foregroundStyle(.white) }
        } else if !device.liveViewEnabled {
            ZStack { Color.black; Label("Live View is disabled", systemImage: "video.slash").foregroundStyle(.white) }
        } else if let url = StreamValidation.url(from: device.streamURL) {
            StreamPanel(url: url, active: active).id(url)
        } else {
            ZStack(alignment: .bottomLeading) {
                PorchIllustration(night: false)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Demo preview").font(.headline)
                    Text("No camera stream is connected").font(.caption)
                }.foregroundStyle(.white).padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            }
        }
    }
    private func action(_ title: String, icon: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).frame(width: 58, height: 58)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                Text(title).font(.caption.weight(.medium))
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain).accessibilityLabel(title)
    }
}
@MainActor struct StreamConnectionView: View {
    let deviceID: UUID
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var value = ""
    @State private var validationError: String?
    var body: some View {
        Form {
            Section("Your stream") {
                TextField("https://example.com/live.m3u8", text: $value)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                Text("Use an HTTPS HLS or AVPlayer-compatible video URL. This app does not obtain Ring stream URLs.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Text("The URL is stored only on this device and omitted from home exports. Use a short-lived link when possible.")
                    .font(.footnote)
            }
            if let validationError { Text(validationError).foregroundStyle(.red) }
            if !value.isEmpty { Button("Disconnect stream", role: .destructive) { value = ""; save() } }
        }
        .navigationTitle("Video Connection").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
        }
        .onAppear { value = store.device(id: deviceID)?.streamURL ?? "" }
    }
    private func save() {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty || StreamValidation.url(from: trimmed) != nil else {
            validationError = "Enter a valid HTTPS URL without a username or password."; return
        }
        guard var device = store.device(id: deviceID) else { dismiss(); return }
        device.streamURL = trimmed; store.saveDevice(device); dismiss()
    }
}
@MainActor struct EventPlaybackView: View {
    let eventID: UUID
    @EnvironmentObject private var store: AppStore
    @State private var urlDraft = ""
    @State private var editing = false
    @State private var error: String?
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Group {
            if let event = store.event(id: eventID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            if let url = StreamValidation.url(from: event.recordingURL) {
                                StreamPanel(url: url).id(url)
                            } else {
                                ZStack(alignment: .bottomLeading) {
                                    PorchIllustration()
                                    Text("Demo event - No recording attached").font(.caption.bold())
                                        .padding().foregroundStyle(.white).background(.black.opacity(0.65))
                                }
                            }
                        }.frame(height: 240).clipShape(RoundedRectangle(cornerRadius: 18))
                        Label(event.kind.title, systemImage: event.kind.icon).font(.title2.bold())
                        Text(event.title).font(.headline)
                        Text(event.timestamp, format: .dateTime.weekday(.wide).month().day().hour().minute())
                            .foregroundStyle(.secondary)
                        HStack {
                            Button { store.toggleFavorite(id: eventID) } label: {
                                Label(event.isFavorite ? "Starred" : "Star event", systemImage: event.isFavorite ? "star.fill" : "star")
                            }.buttonStyle(.bordered)
                            ShareLink(item: "\(event.title)\n\(event.timestamp.formatted())\nRing Rebuilt demo event")
                                .buttonStyle(.bordered)
                        }
                        Button("Attach your own video URL") { urlDraft = event.recordingURL; editing = true }
                            .buttonStyle(.borderedProminent)
                        Text("Demo events contain no Ring recording. You can attach an HTTPS video you are authorized to view.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Delete event", role: .destructive) { deleting = true }
                            .disabled(event.isFavorite)
                        if event.isFavorite { Text("Unstar this event before deleting it.").font(.caption).foregroundStyle(.secondary) }
                    }.padding()
                }.background(Color.ringBackground)
                .navigationTitle("Event Details").navigationBarTitleDisplayMode(.inline)
                .onAppear { store.markRead(id: eventID) }
                .sheet(isPresented: $editing) {
                    NavigationStack {
                        Form {
                            TextField("HTTPS video URL", text: $urlDraft).keyboardType(.URL)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                            Text("Supports HTTPS video and HLS accepted by AVPlayer.").font(.footnote)
                            if let error { Text(error).foregroundStyle(.red) }
                        }
                        .navigationTitle("Attach Video")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = false } }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    if store.saveRecordingURL(eventID: eventID, value: urlDraft) { error = nil; editing = false }
                                    else { error = "Enter a valid HTTPS URL." }
                                }
                            }
                        }
                    }
                }
                .confirmationDialog("Delete this event?", isPresented: $deleting, titleVisibility: .visible) {
                    Button("Delete event", role: .destructive) { store.deleteEvent(id: eventID); dismiss() }
                }
            } else {
                ContentUnavailableView("Event not found", systemImage: "clock.badge.xmark")
            }
        }
    }
}

