# Reconstruction findings and decisions

## Scope

The deliverable is a separate SwiftUI source project, with working local state and optional user-provided video playback. Full Ring backend/hardware parity is blocked by missing verified service contracts, provisioning and native/runtime evidence. Exact visual fidelity is unverified.

## Evidence ledger

Primary archive inventory:
ev_34ef54c188ab5acc934d5a017667d63dcbf8fcf4bec34a29c45989755b246025.
Original report: ../ring-analysis.md.
Complete original ledger: ../ring-rea-evidence.json.
Independent parsed plists/JSON: ../ring-static-evidence.json and ../ring-static-supplement.json.

A full REA extraction attempt timed out at the client after 300 seconds and returned no usable extraction record. It was not treated as successful or repeated. A separate, explicitly selected 20-file UI evidence subset was materialized directly from the ZIP, with original member hashes in:
../reconstruction-evidence/selected-ui-manifest.json.
This is not a complete extracted Ring app.

REA opened the unchanged main executable within that subset:
SHA-256 6623692728ab8a910cc1d7059c3931667fdb944b1e7381f827fffcd5d62b2a7c.

REA decode_interface_builder evidence:
ev_f69fb9e578577bdc3a7f86709de5f08a7af477523a56484e69e8d64804d999f7.
Summary:
ev_53dd68d1feb792916113fbe37b1ab59e34625dc67e59264b3910e21ab01ddd83.
Portable ledger:
../reconstruction-evidence/ring-ui-rea-evidence.json.

The decoder reports 17 documents, 616 nodes and 158 edges. All 17 document hierarchy_complete flags are false. There are 46 unknown nodes; graph coverage reports 52 complete and 17 unsupported facets. Complete-within-view or untruncated delivery is not complete UI recovery. It cannot infer runtime-generated views, true pixel geometry or code handlers.

Example direct observation: MotionSensitivityCell.nib contains a view named _TtC4ring21MotionSensitivityCell and serialized label text “Motion Detection Sensitivity.” Its file hash is dbd15f3dd456b6afc0cc9e216fa64091caa12fc08c3c112638c5456907fff236. This supports a motion sensitivity control, not its backend semantics.

No original app execution or device UI capture was performed in this reconstruction pass. No REA configuration was changed. Native deep providers remain unavailable for this ARM64 Mach-O on this host.

## Resource-to-feature map

All source paths below are IPA members under Payload/ring.app/. These are shipped text/configuration observations; the reconstructed screens are new implementations.

| Feature | Evidence paths | Implementation / gap |
|---|---|---|
| Locations/modes/dashboard | en.lproj/Dashboard.strings, DashboardShortcuts.strings; RingLocationsOverviewUIResources.bundle/en.lproj/Localizable.strings | Per-location modes, local device cards; no real arming |
| Device tiles | RingDeviceTilesUI-Resources.bundle/en.lproj/DeviceTile.strings, DeviceTileState.strings | Searchable local device collection and offline states |
| Device controls | en.lproj/DeviceDashboardSwitches.strings | Saved motion/light/lock/volume demo controls |
| Live View | Streaming-LiveView-Resources.bundle/en.lproj/LiveView.strings | Native player for user URL; no recovered Ring transport/talk |
| History | RingRingHistoryEventsListKitUIResources.bundle/en.lproj/EventsList.strings, HistoryEntryAction.strings, DeleteHistoryEntryFlow.strings | Local filters/favorites/read/delete; starred deletion protection |
| Playback | History-Timeline-Resources.bundle/en.lproj/VideoPlayer.strings, ShareVideoFeature.strings | HTTPS playback and text sharing; no cloud fetch/download |
| Motion | MotionAISettingsUI-Resources.bundle/en.lproj/MotionSettings.strings; MotionSensitivityCell.nib | Sensitivity and editable local zones; no detection engine/schedules |
| Video | RingVideoSettingsUIResources.bundle/en.lproj/VideoSettings.strings | Saved video preferences; no hardware configuration |
| Health/general | RingDeviceHealthUIResources.bundle/en.lproj/DeviceHealth.strings; RingGeneralSettingsKitResources.bundle/en.lproj/GeneralSettings.strings | Rename/remove and honest unavailable telemetry |
| Setup | RingMDSDeviceSelectionUI-Resources.bundle/device_selection_flow_main.json and device_selection_flow_doorbells.json | Category/manual/QR/name flow; no physical pairing |
| Authentication | RingMultifactorAuthUIResources.bundle/en.lproj/SignIn.strings, VerifyPhone.strings, CodeVerification.strings | Not implemented; no credentials collected |

The setup JSON directly defines typed entrances, named steps and exit connections. The default route is preparation → device selection → scanning flow. Doorbell setup prioritizes QR recognition. We reconstructed this interaction pattern; we did not execute the original flow engine or recover its native implementation.

## Design choices and inferences

A blue/white adaptive SwiftUI design, four tabs, SF Symbols and a synthetic porch illustration provide a coherent exploratory interface. Placement, dimensions, typography and navigation are approximations. All camera artwork is marked demo.

Ring service behavior is not inferred from library names, endpoint URLs or permission descriptions. The Management framework's packaged key/manifest endpoints do not provide an authenticated app API. No endpoint was probed.

The app intentionally has a separate identifier, com.local.ringrebuilt. It has no original app groups, keychain groups, Ring push entitlement or private SDK framework dependencies. No attempt was made to bypass signing, account authorization, activation or device ownership.

## Verification boundaries

Source syntax and project consistency checks ran on Windows. Xcode compilation, actual unit tests and visual/device acceptance remain required on a Mac. Tests were added for meaningful state and privacy behavior but were not claimed as executed.

Full functionality remains incomplete. The next blocking inputs are an authorized service/backend integration, matching runtime/UI references, test hardware and a macOS/Xcode build/signing environment.


## Platform API references

The new adapters use Apple APIs, not recovered Ring implementation:

- [DataScannerViewController](https://developer.apple.com/documentation/visionkit/datascannerviewcontroller) for QR reading.
- [VideoPlayer](https://developer.apple.com/documentation/avkit/videoplayer) for user-provided video playback.
