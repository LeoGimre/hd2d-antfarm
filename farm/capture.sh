#!/usr/bin/env bash
# capture.sh — record a demo scene to web-ready video, plus QC frames.
#
#   farm/capture.sh <demo-name> [seconds]
#
# Godot's Movie Maker renders at a fixed timestep straight to file, so the result
# is deterministic and independent of how fast the machine actually runs. It does
# NOT work under --headless: it needs a real rendering context, which is why the
# antfarm runner lives in a logged-in GUI session.
#
# Emits, under farm/out/<demo>/:
#   clip.mp4    h264, web-ready
#   clip.webm   vp9
#   poster.jpg  first-frame still
#   qc-NN.png   sampled frames, for a human or an agent to actually look at
set -euo pipefail

DEMO="${1:?usage: capture.sh <demo-name> [seconds]}"
SECS="${2:-12}"
FPS=30
WIDTH=1280
HEIGHT=720

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
FFMPEG="${FFMPEG_BIN:-/opt/homebrew/bin/ffmpeg}"
SCENE="res://tools/demos/${DEMO}.tscn"
OUT="$ROOT/farm/out/$DEMO"

# Movie Maker mode needs a rendering context. On a Mac that is the logged-in GUI
# session the runner already lives in; a Linux container has no display at all,
# so re-exec into a virtual one. The guard variable stops a second re-exec if
# Xvfb comes up without exporting DISPLAY for some reason.
if [ -z "${DISPLAY:-}" ] && [ -z "${CAPTURE_UNDER_XVFB:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  export CAPTURE_UNDER_XVFB=1
  exec xvfb-run -a -s "-screen 0 ${WIDTH}x${HEIGHT}x24" "$0" "$@"
fi

[ -f "$ROOT/game/tools/demos/${DEMO}.tscn" ] || { echo "capture: no such demo scene: $DEMO" >&2; exit 2; }
command -v "$GODOT"  >/dev/null 2>&1 || [ -x "$GODOT" ]  || { echo "capture: godot not found at $GODOT" >&2; exit 2; }

rm -rf "$OUT"; mkdir -p "$OUT"
FRAMES=$(( SECS * FPS ))

echo "capture: $DEMO — ${SECS}s @ ${FPS}fps (${FRAMES} frames)"
# --quit-after exits cleanly at the frame count; killing it instead produces a
# file with no duration header, which ffmpeg then refuses to seek.
"$GODOT" --path "$ROOT/game" \
  --write-movie "$OUT/raw.ogv" \
  --fixed-fps "$FPS" \
  --quit-after "$FRAMES" \
  --resolution "${WIDTH}x${HEIGHT}" \
  "$SCENE" >"$OUT/godot.log" 2>&1 || {
    echo "capture: godot exited non-zero; tail of log:" >&2
    tail -20 "$OUT/godot.log" >&2
    exit 1
  }

[ -s "$OUT/raw.ogv" ] || { echo "capture: no video was written" >&2; tail -20 "$OUT/godot.log" >&2; exit 1; }

# Never rescale: resampling pixel art is how crisp sprites turn to mush.
"$FFMPEG" -y -loglevel error -i "$OUT/raw.ogv" \
  -c:v libx264 -crf 26 -preset slow -tune animation -pix_fmt yuv420p -movflags +faststart -an \
  "$OUT/clip.mp4"

"$FFMPEG" -y -loglevel error -i "$OUT/raw.ogv" \
  -c:v libvpx-vp9 -crf 38 -b:v 0 -row-mt 1 -an \
  "$OUT/clip.webm"

"$FFMPEG" -y -loglevel error -ss 1 -i "$OUT/clip.mp4" -frames:v 1 -q:v 3 "$OUT/poster.jpg"

# QC frames, evenly spread. The tick opens these and looks at them before it
# publishes; a black screen or a magenta missing-texture wash fails the gate.
"$FFMPEG" -y -loglevel error -i "$OUT/clip.mp4" \
  -vf "fps=1/$(( SECS / 4 > 0 ? SECS / 4 : 1 ))" -frames:v 4 "$OUT/qc-%02d.png"

rm -f "$OUT/raw.ogv"

echo "capture: ok"
for f in clip.mp4 clip.webm poster.jpg; do
  [ -f "$OUT/$f" ] && printf '  %-12s %8s bytes\n' "$f" "$(wc -c < "$OUT/$f" | tr -d ' ')"
done
ls "$OUT"/qc-*.png 2>/dev/null | sed 's|.*/|  qc frame: |'
