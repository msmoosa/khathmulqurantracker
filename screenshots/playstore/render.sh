#!/bin/sh
# Renders template.html into 1080x1920 Play Store phone screenshots.
# Source captures in src/ come from the emulator in demo mode
# (--dart-define=DEMO=true) with the system UI demo status bar enabled.
set -e
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p phone
for slide in 1:1_track 2:2_progress 3:3_reminder; do
  n=${slide%%:*}; name=${slide#*:}
  "$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --window-size=1080,1920 --allow-file-access-from-files \
    --screenshot="$PWD/phone/$name.png" "file://$PWD/template.html#$n" 2>/dev/null
done

# Feature graphic: 1024x500, no alpha (Play rejects transparent PNGs).
"$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1024,500 --allow-file-access-from-files \
  --screenshot="$PWD/feature_graphic.png" "file://$PWD/feature.html" 2>/dev/null
