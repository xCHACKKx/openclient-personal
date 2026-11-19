#!/bin/bash
# Usage: package-ipa.sh <products-dir> <output.ipa>
# Takes the unsigned OpenClient.app, embeds minimal entitlements with ldid
# (AltStore re-signs with the free account and rewrites bundle ID / app group),
# and zips it as an IPA.
set -euo pipefail

PRODUCTS="$1"
OUT="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
APP="$PRODUCTS/OpenClient.app"
[ -d "$APP" ] || { echo "OpenClient.app not found in $PRODUCTS"; ls "$PRODUCTS"; exit 1; }

ENT="$(mktemp -d)/ent.plist"
# Free Apple IDs cannot use WeatherKit; keychain groups need a real team prefix.
# Only the app group is kept (AltStore rewrites it per team).
cat > "$ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>com.apple.security.application-groups</key>
<array><string>group.com.ntoporcov.openclient</string></array>
</dict></plist>
EOF

for appex in "$APP"/PlugIns/*.appex; do
  [ -d "$appex" ] && ldid -S"$ENT" "$appex"
done
for fw in "$APP"/Frameworks/*.framework; do
  [ -d "$fw" ] && ldid -S "$fw"
done
ldid -S"$ENT" "$APP"

# AltStore remaps the app group via this key
/usr/libexec/PlistBuddy -c "Delete :ALTAppGroups" "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ALTAppGroups array" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Add :ALTAppGroups:0 string group.com.ntoporcov.openclient" "$APP/Info.plist"

W="$(mktemp -d)"
mkdir "$W/Payload"
cp -R "$APP" "$W/Payload/"
(cd "$W" && zip -qry "$OUT" Payload)
ls -l "$OUT"
