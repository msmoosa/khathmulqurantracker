#!/bin/sh
# Captures the app on an iPad Pro 13" and the iPhone Duo's outer display into
# ../ipad-pro-13 and ../duo. Each screen is a debug build with demo data and a
# DEMO_* define that opens it on launch (see lib/demo/demo_data.dart).
# Usage: capture.sh <ipad udid> <duo udid>, both simulators booted.
set -e
cd "$(dirname "$0")/../.."
IPAD=$1; DUO=$2
OUT=screenshots
mkdir -p $OUT/ipad-pro-13 $OUT/duo
for d in $IPAD $DUO; do
  # "charged" draws a charging bolt; a full battery is "discharging" at 100.
  xcrun simctl status_bar $d override --time 9:41 --batteryState discharging \
    --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
done

shoot() { # $1 name, rest: dart defines
  name=$1; shift
  flutter build ios --simulator --debug --dart-define=DEMO=true "$@" >/dev/null
  for d in $IPAD $DUO; do
    xcrun simctl install $d build/ios/iphonesimulator/Runner.app
    xcrun simctl launch --terminate-running-process $d com.khathmulqurantracker >/dev/null
  done
  sleep 25 # launch, page fonts download, sheet animation
  [ -n "$name" ] || return 0
  xcrun simctl io $IPAD screenshot $OUT/ipad-pro-13/$name.png >/dev/null 2>&1
  xcrun simctl io $DUO screenshot --display=1 $OUT/duo/$name.png >/dev/null 2>&1
}

shoot read --dart-define=DEMO_PAGE=604
shoot mark --dart-define=DEMO_VERSE=19:6
shoot "" --dart-define=DEMO_PAGE=50 # leaves "Continue reading" on page 50
shoot index --dart-define=DEMO_TAB=0
shoot track --dart-define=DEMO_TAB=1
shoot progress --dart-define=DEMO_TAB=2
shoot settings --dart-define=DEMO_TAB=3
