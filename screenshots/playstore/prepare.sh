#!/bin/sh
# Copies the emulator captures in ../android into src/, replacing their status
# bar with the clean 9:41 demo bar (the emulator draws a clipped clock and
# notification icons). bar.png is the top 120px of a demo-mode capture of a
# green app bar; the green screens match it pixel for pixel below the bar.
set -e
cd "$(dirname "$0")"
A=../android/Screenshot_20261108
mkdir -p src
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# Clock and icons alone, as an alpha mask (the star pattern stays below 20%).
magick bar.png -channel R -separate +channel -level 20%,100% "$TMP/mask.png"
icons() { # $1 colour -> icons in that colour on a transparent strip
  magick -size 1080x120 "xc:$1" "$TMP/mask.png" -alpha off -compose CopyOpacity -composite "$TMP/icons.png"
}

# Green app bar: paste the clean bar.
for s in 210049:2_index 210151:4_track 210158:5_progress 210204:6_settings; do
  magick "${A}_${s%%:*}.png" bar.png -geometry +0+0 -composite "src/${s#*:}.png"
done

# Mushaf page: plain paper, dark icons.
icons '#64625b'
magick "${A}_210123.png" -fill '#fbf4e4' -draw 'rectangle 0,0 1079,119' \
  "$TMP/icons.png" -geometry +0+0 -composite src/1_read.png

# Verse menu: the bar under the sheet's scrim, white icons on top.
icons white
magick "${A}_210142.png" \( bar.png -fill black -colorize 54% \) -geometry +0+0 -composite \
  "$TMP/icons.png" -geometry +0+0 -composite src/3_mark.png

# The phone frame shows only the top 75% of the screen, which would hide the
# sheet: drop the page lines between the held verse and the sheet to lift it,
# then pad the bottom back to full height in the sheet colour.
magick src/3_mark.png \( -clone 0 -crop 1080x1312+0+0 \) \( -clone 0 -crop 1080x1088+0+1768 \) \
  -delete 0 -append -background "#faf6f0" \
  -gravity north -extent 1080x2400 +repage src/3_mark.png
