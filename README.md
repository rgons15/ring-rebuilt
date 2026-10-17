# Ring Rebuilt — native SwiftUI reconstruction

This is a **new source project**, not a modified Ring IPA or recovered original source. It implements an independent, local reconstruction of major resource-backed Ring workflows. **Full Ring functionality and exact visual parity are not achieved.** The app opens into a clearly labeled demo home.

## Open and run

1. Copy this entire RingRebuilt folder to a Mac with Xcode 16 or newer and an iOS 17+ SDK/runtime.
2. Open **RingRebuilt.xcodeproj**. Select the shared **RingRebuilt** scheme.
3. For a simulator, choose an iPhone simulator and Run.
4. For your iPhone, select a signing team under Signing & Capabilities, change com.local.ringrebuilt to a unique bundle identifier if necessary, enable Developer Mode on the phone, select it, then Run.
5. The installed display name is **Ring Rebuilt**. It uses its own sandbox and bundle identifier and does not replace the original Ring app.

No third-party runtime packages, copied Ring frameworks, account credentials, private entitlements or Ring API keys are included. You do not need a Ring account to explore the demo. No compiled/signed IPA is supplied: this Windows machine has no Xcode and cannot perform the required iOS build.

## Implemented source-level workflows

| Area | Behavior |
|---|---|
| Dashboard | Location selector, per-location Disarmed/Home/Away simulation, device cards, recent activity |
| Devices | Search/category filters, add/rename/remove, online-state simulation, battery sample display |
| Setup | Category → transient manual/QR code → name/location; creates a local device only |
| Camera UI | Illustrated demo preview; full screen; actual AVPlayer playback for an authorized HTTPS video/HLS URL |
| Event History | Search/type/favorite filters, read state, star/unstar, protected deletion, details and text sharing |
| Recording UI | Attach and play your own HTTPS video URL; no Ring recordings are downloaded |
| Motion | Detection/alert preferences, sensitivity, up to three editable normalized rectangle zones |
| Video preferences | Live View enable, HDR/night vision/bandwidth preferences saved locally; these do not reconfigure hardware or transform video |
| Device Health | Local status/battery samples; real firmware, network, serial and telemetry explicitly unavailable |
| Settings | Location add/edit, appearance, haptics, alert preferences, sanitized JSON sharing, reset confirmation |
| Persistence | Atomic protected local JSON, backup exclusion, error reporting, corrupt-file preservation, per-location modes |
| Alerts | In-app simulated-event banners honor global/device alert preferences; no OS push delivery |
| QR scanning | VisionKit camera QR reader with permission/availability handling and manual fallback; no hardware pairing |

Sample events contain **no camera footage**. Demo snapshots add an activity marker, not an image. Talk/siren controls explain their unavailable integration or create a labeled local alarm event. The app does not operate locks, lights or alarm hardware.

The app never requests a Ring email/password. It stores user-entered video URLs locally under iOS data protection and omits them from exports. Use authorized short-lived URLs. URLs may still contain access tokens, so don't share the app's private storage.

## Unimplemented integrations

Ring authentication/MFA, device discovery and pairing, Ring live-stream negotiation and two-way talk, camera recordings/subscriptions, remote motion/video configuration, cloud event history, push notifications, lock/alarm control, emergency dispatch, guest access, Ring E2EE key management, widgets/notification extensions and the Neighbors service are **not implemented**.

These require supported service interfaces and, in several cases, provisioning/hardware-specific protocols. Merely shipping a framework or finding an endpoint in an IPA does not recover the server contract. There is no fake successful Ring login or hardware pairing.

To finish those features, supply an authorized integration specification/test backend and suitable test devices, then implement and validate one vertical feature at a time. Do not put credentials in source control or chat. Real account/hardware work also requires new runtime evidence from the matching app version.

## REA evidence and design fidelity

The analyzed IPA is Ring 5.103.1 (5.103.1.1), SHA-256 a738cc9e852a02d6038981739febaf1c0a0be979082141b716207c3091853e39. The connected phone separately had Ring 5.115.0 installed; it was not treated as the same build.

See **RECONSTRUCTION.md** for exact source-resource paths and evidence IDs. A compact, portable REA record is included in [evidence/rea-ui-summary.json](evidence/rea-ui-summary.json). Full local analysis reports/ledgers and the original IPA are not published in this repository. A selected-resource REA decode recovered 17 documents, 616 nodes and 158 connections, with incomplete hierarchy/unknown classes and no inferred pixel geometry.

Layout, spacing, colors, illustration and navigation are **new design choices**, not a verified pixel-perfect copy. No live UI screenshots were captured or compared, and no original executable/framework is included in the app target. The original app was not changed.

## Verification

Windows checks: all Swift files parse with tree-sitter; the OpenStep Xcode project parses; source membership, scheme target IDs, plist and icon references are validated. See validation-report.json.

**Not yet verified:** Swift SDK type checking, Xcode compilation, XCTest execution, simulator layout and real-iPhone behavior. Passing a syntax parser is not a passing Xcode build.

Seven XCTest cases cover persistence/location isolation, protected favorite deletion, URL/setup-code exclusion from exports, motion/alert preference behavior, bounds normalization, corrupt-file preservation and stream-URL validation. On a Mac, run Product → Test or:

    bash scripts/test-macos.sh

For the portable structural verifier, install tree-sitter, tree-sitter-swift and openstep-parser in an isolated Python environment, then run:

    python scripts/verify_project.py

Device acceptance checklist: launch after signing; switch locations/modes and relaunch; add/rename/remove a demo device; create/star/filter/delete events; edit/save zones; test dark mode and large Dynamic Type; scan a nonsecret QR; try both a valid authorized stream and an invalid URL; verify cancelled camera permission/manual fallback.

## Files

- RingRebuilt/Models: Codable models and main-actor persistent store.
- RingRebuilt/Views: SwiftUI screens and VisionKit/AVKit adapters.
- Tests/AppStoreTests.swift: behavior tests for Xcode.
- generate_project.py: deterministic dependency-free PBX project generator; run from the parent directory if adding sources.
- scripts: structural validation and macOS build/test entry points.

This project is independent and is not affiliated with Ring. It does not provide a working security or emergency-monitoring service.


## Development provenance

Created with OpenAI Codex and the reverse-engineer-anything (REA) tools. The Swift implementation is newly written reconstruction code; source syntax/project checks ran on Windows. No Xcode build or device-test success is claimed.
