#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
  echo "Install Xcode and select it with xcode-select first." >&2
  exit 1
fi
device_id="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x["udid"] for devices in d["devices"].values() for x in devices if x.get("isAvailable") and "iPhone" in x["name"]]; print(a[0] if a else "")')"
if [[ -z "$device_id" ]]; then
  echo "Install an iOS Simulator runtime in Xcode Settings > Platforms." >&2
  exit 1
fi
xcodebuild -project RingRebuilt.xcodeproj -scheme RingRebuilt \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath .build -resultBundlePath ".build/TestResults-$(date +%Y%m%d-%H%M%S).xcresult" \
  CODE_SIGNING_ALLOWED=NO test

