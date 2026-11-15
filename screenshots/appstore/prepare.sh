#!/bin/sh
# Copies the simulator captures in ../ios (iPhone 17 Pro, 1206x2622) into src/.
# On iOS the reader's centred "Page N" title runs into the "Hold a verse for
# options" hint, so the hint is covered with the same strip of the Settings app
# bar (the star pattern lines up pixel for pixel), dimmed for the verse menu's
# 54% scrim.
set -e
cd "$(dirname "$0")"
mkdir -p src
src() { ls ../ios/*"$1"*; } # the names have a narrow no-break space before PM

cp "$(src 3.37.54)" src/track.png
cp "$(src 3.37.58)" src/progress.png
cp "$(src 3.38.01)" src/settings.png
cp "$(src 3.38.04)" src/index.png
magick "$(src 3.39.56)" \( src/settings.png -crop 456x150+750+200 \) \
  -geometry +750+200 -composite src/read.png
magick "$(src 3.38.29)" \( src/settings.png -crop 456x150+750+200 -fill black -colorize 54% \) \
  -geometry +750+200 -composite src/mark.png

# iPad Pro 13" (2064x2752) and the iPhone Duo's outer display (1398x2034),
# captured by capture.sh. Their bars are wide enough that the hint fits. On
# the iPad, the window resize grabber in the bottom right corner is painted
# over in the colour beside it.
mkdir -p src-ipad src-duo
for name in read index mark track progress settings; do
  bg=$(magick "../ipad-pro-13/$name.png" -format '%[pixel:p{1990,2720}]' info:)
  magick "../ipad-pro-13/$name.png" -fill "$bg" -draw 'rectangle 1996,2684 2063,2751' "src-ipad/$name.png"
  cp "../duo/$name.png" "src-duo/$name.png"
done
