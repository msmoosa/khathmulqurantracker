#!/bin/sh
# Renders template.html into App Store screenshots: iPhone 1320x2868 (6.9")
# and 1206x2622 (6.3"), iPad 2064x2752 (13") and the iPhone Duo's outer
# display at 1398x2034. Source captures in src*/ are made by prepare.sh.
# App Store Connect rejects PNGs with alpha, so every set is flattened.
set -e
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

render() { # $1 query, $2 size, $3 output folder
  mkdir -p "$3"
  for slide in 1:1_read 2:2_index 3:3_mark 4:4_track 5:5_progress 6:6_settings; do
    n=${slide%%:*}; name=${slide#*:}
    "$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
      --window-size="$2" --allow-file-access-from-files \
      --screenshot="$PWD/$3/$name.png" "file://$PWD/template.html$1#$n" 2>/dev/null
    magick "$3/$name.png" -alpha off "$3/$name.png"
  done
}

render "" 1320,2868 6.9in
render "?d=ipad" 2064,2752 ipad-13in
render "?d=duo" 1398,2034 duo-outer

mkdir -p 6.3in
for f in 6.9in/*.png; do
  magick "$f" -resize '1206x2622!' "6.3in/${f#6.9in/}"
done
