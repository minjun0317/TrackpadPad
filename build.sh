#!/bin/bash
# Builds build/TrackpadPad.app. Signing with a stable identity keeps the
# Accessibility permission valid across rebuilds.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/TrackpadPad.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/TrackpadPad "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"

IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ { print $2; exit }')
codesign --force --sign "${IDENTITY:--}" "$APP"
echo "Built $APP (signed: ${IDENTITY:-ad-hoc})"
