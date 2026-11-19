#!/bin/bash
# Usage: make-source.sh <ipa> <out.json> <owner/repo>
# Writes an AltStore source so AltStore can auto-update the app from the "latest" release.
set -euo pipefail
IPA="$1"; OUT="$2"; REPO="$3"
OWNER="${REPO%%/*}"
APP="$(mktemp -d)"
unzip -q "$IPA" -d "$APP"
PLIST="$APP/Payload/OpenClient.app/Info.plist"
VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")"
SIZE="$(stat -f%z "$IPA")"
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$OUT" <<EOF
{
  "name": "OpenClient Personal",
  "identifier": "com.${OWNER,,}.openclient.source",
  "apps": [{
    "name": "OpenClient",
    "bundleIdentifier": "com.ntoporcov.openclient",
    "developerName": "ntoporcov (personal build by ${OWNER})",
    "subtitle": "Private unlimited build",
    "version": "${VER}",
    "versionDate": "${DATE}",
    "downloadURL": "https://github.com/${REPO}/releases/download/latest/OpenClient-altstore.ipa",
    "localizedDescription": "Personal non-commercial build of OpenClient (PolyForm Noncommercial 1.0.0).",
    "iconURL": "https://raw.githubusercontent.com/${REPO}/main/OpenClient_icons/AppIcon-1024.png",
    "size": ${SIZE},
    "versions": [{"version": "${VER}", "buildVersion": "${BUILD}", "date": "${DATE}", "downloadURL": "https://github.com/${REPO}/releases/download/latest/OpenClient-altstore.ipa", "size": ${SIZE}}]
  }],
  "news": []
}
EOF
cat "$OUT"
