import SwiftUI
import VisionKit
import Vision
import UIKit
import AVFoundation

@MainActor struct QRScannerView: View {
    var onCode: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var permission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Group {
                if permission == .authorized && DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    ScannerController(onCode: { value in
                        onCode(String(value.prefix(512)))
                        dismiss()
                    }, onError: { error = $0 })
                        .ignoresSafeArea(edges: .bottom)
                } else if permission == .notDetermined {
                    VStack(spacing: 20) {
                        Image(systemName: "qrcode.viewfinder").font(.system(size: 64)).foregroundStyle(Color.ringBlue)
                        Text("Scan a demo setup code").font(.title2.bold())
                        Text("Camera access is used only to read a QR code. It does not pair Ring hardware.")
                            .multilineTextAlignment(.center)
                        Button("Allow Camera") {
                            AVCaptureDevice.requestAccess(for: .video) { granted in
                                Task { @MainActor in permission = granted ? .authorized : .denied }
                            }
                        }.buttonStyle(.borderedProminent)
                    }.padding(28)
                } else {
                    ContentUnavailableView("Scanner unavailable", systemImage: "qrcode.viewfinder",
                                           description: Text("Use manual entry instead. Camera access and a supported iPhone are required."))
                }
            }
            .navigationTitle("Scan QR Code").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                if let error { Text(error).font(.footnote).padding().frame(maxWidth: .infinity).background(.regularMaterial) }
            }
        }
    }
}
private struct ScannerController: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onError: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode, onError: onError) }
    func makeUIViewController(context: Context) -> ScannerHost {
        let host = ScannerHost()
        host.scanner.delegate = context.coordinator
        host.onError = onError
        return host
    }
    func updateUIViewController(_ controller: ScannerHost, context: Context) { }
    static func dismantleUIViewController(_ controller: ScannerHost, coordinator: Coordinator) {
        controller.scanner.stopScanning()
    }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        let onError: (String) -> Void
        private var delivered = false
        init(onCode: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onCode = onCode; self.onError = onError
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !delivered else { return }
            for item in addedItems {
                if case let .barcode(barcode) = item, let value = barcode.payloadStringValue {
                    delivered = true; dataScanner.stopScanning(); onCode(value); return
                }
            }
        }
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            onError("Scanning stopped. Close the scanner and use manual entry.")
        }
    }
}
private final class ScannerHost: UIViewController {
    let scanner = DataScannerViewController(
        recognizedDataTypes: [.barcode(symbologies: [.qr])],
        qualityLevel: .balanced,
        recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false,
        isPinchToZoomEnabled: true,
        isGuidanceEnabled: true,
        isHighlightingEnabled: true
    )
    var onError: ((String) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(scanner); view.addSubview(scanner.view); scanner.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanner.view.topAnchor.constraint(equalTo: view.topAnchor),
            scanner.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        scanner.didMove(toParent: self)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do { try scanner.startScanning() } catch { onError?("Unable to start the camera. Use manual entry instead.") }
    }
    override func viewWillDisappear(_ animated: Bool) {
        scanner.stopScanning()
        super.viewWillDisappear(animated)
    }
}

