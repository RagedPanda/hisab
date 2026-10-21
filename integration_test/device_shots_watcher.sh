#!/bin/bash
# Companion to integration_test/harness.dart: captures full-device simulator
# screenshots (status bar, Dynamic Island, home indicator, keyboard) in sync
# with the in-app screenshots.
#
# The in-app suite drops a request file into the app's Documents/device_shots
# folder before every screenshot and waits for it to disappear. This script
# polls that folder, runs `simctl io screenshot`, and deletes the request.
#
# Usage: integration_test/device_shots_watcher.sh <simulator-udid> <output-dir> [bundle-id]
# Run it in the background BEFORE `flutter drive`, and stop it afterwards.
set -u
UDID="${1:?simulator udid}"
OUT="${2:?output directory}"
BUNDLE="${3:-com.sarv.hisab}"
mkdir -p "$OUT"

resolve_dir() {
  local container
  container=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data 2>/dev/null) || return 1
  echo "$container/Documents/device_shots"
}

DIR=""
cleanup() { [ -n "$DIR" ] && rm -f "$DIR/watcher_alive"; exit 0; }
trap cleanup INT TERM

while true; do
  NEXT=$(resolve_dir) || { sleep 1; continue; }
  if [ "$NEXT" != "$DIR" ]; then
    [ -n "$DIR" ] && rm -f "$DIR/watcher_alive"
    DIR="$NEXT"
    mkdir -p "$DIR" && touch "$DIR/watcher_alive"
    echo "watching $DIR"
  fi
  for req in "$DIR"/req_*; do
    [ -e "$req" ] || continue
    name=$(basename "$req")
    name=${name#req_}
    sleep 0.2
    xcrun simctl io "$UDID" screenshot "$OUT/${name}_device.png" >/dev/null 2>&1
    rm -f "$req"
    echo "captured $name"
  done
  sleep 0.2
done
