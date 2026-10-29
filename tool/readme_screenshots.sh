#!/bin/bash
# Shoots the README gallery (integration_test/readme_gallery_test.dart) on one
# device and writes 360-wide PNGs: Android to docs/screenshots, iOS to
# docs/screenshots/ios. Status bar in demo mode with the clock at 10:00.
#
# Usage: tool/readme_screenshots.sh android <adb-serial>
#        tool/readme_screenshots.sh ios <simulator-udid>
set -eu
PLATFORM="${1:?android or ios}"
DEVICE="${2:?device id}"
RAW="build/readme_shots/$PLATFORM"
rm -rf "$RAW"
mkdir -p "$RAW"

case "$PLATFORM" in
  android)
    OUT=docs/screenshots
    demo() { adb -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
    adb -s "$DEVICE" shell settings put global sysui_demo_allowed 1
    demo enter
    demo clock -e hhmm 1000
    demo battery -e level 100 -e plugged false
    demo network -e wifi show -e level 4 -e mobile hide
    demo notifications -e visible false
    integration_test/device_shots_watcher.sh android "$DEVICE" "$RAW" &
    ;;
  ios)
    OUT=docs/screenshots/ios
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    # simctl wants an ISO UTC instant; this one reads 10:00 in local time.
    xcrun simctl status_bar "$DEVICE" override --time "$(date -u -r "$(date -j -f '%Y-%m-%d %H:%M:%S' '2026-01-01 10:00:00' +%s)" +%Y-%m-%dT%H:%M:%S.000Z)" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularMode notSupported
    integration_test/device_shots_watcher.sh "$DEVICE" "$RAW" &
    ;;
  *) echo "unknown platform: $PLATFORM" >&2; exit 2 ;;
esac
WATCHER=$!
trap 'kill "$WATCHER" 2>/dev/null' EXIT

ANDROID_SERIAL="$DEVICE" HISAB_SHOTS_DIR="$RAW/in_app" flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/readme_gallery_test.dart -d "$DEVICE"

mkdir -p "$OUT"
for shot in "$RAW"/*_device.png; do
  name=$(basename "$shot" _device.png)
  sips --resampleWidth 360 "$shot" --out "$OUT/${name#*_}.png" >/dev/null
  echo "wrote $OUT/${name#*_}.png"
done
