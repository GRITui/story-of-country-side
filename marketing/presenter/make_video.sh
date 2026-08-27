#!/usr/bin/env bash
# Assemble the game-manual video:
#   - each scene card -> a 1280x720 clip with a gentle zoom (ffmpeg zoompan)
#   - one real-gameplay clip inserted
#   - concat all clips, then mux the looping BGM with fade in/out
# Output: marketing/story-of-countryside-manual.mp4
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT="$(pwd)"
PRES="marketing/presenter"
FRAMES="$ROOT/$PRES/frames"
OUT="$ROOT/marketing/story-of-countryside-manual.mp4"
TMP="$ROOT/$PRES/build"
rm -rf "$TMP"; mkdir -p "$TMP"
FPS=30

scale_zoom() {
  echo "scale=1920:-2,zoompan=z='min(1.0+0.0006*on,1.16)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1280x720:fps=$FPS"
}
make_seg() { # img dur out
  ffmpeg -hide_banner -loglevel error -y -loop 1 -t "$2" -framerate $FPS -i "$1" \
    -vf "$(scale_zoom)" -t "$2" -r $FPS -c:v libx264 -pix_fmt yuv420p "$3"
}

LIST=()
i=0
for spec in \
  "step_00_title 4.5" \
  "step_01_toc 6.0" \
  "step_02_day 8.0" \
  "step_03_farm 8.0" \
  "step_05_animals 8.0" \
  "step_04_crops 8.0" \
  "step_06_wildlife 7.0" \
  "step_07_friends 8.0" \
  "step_08_shop 7.0" \
  "step_09_outro 6.0"
do
  set -- $spec
  make_seg "$FRAMES/$1.png" "$2" "$TMP/seg_$i.mp4"
  LIST+=("$TMP/seg_$i.mp4")
  i=$((i+1))
done

# real gameplay clip, inserted after the farm card
GF="$TMP/seg_gameplay.mp4"
ffmpeg -hide_banner -loglevel error -y -i "$ROOT/marketing/farmscene-plant-water-harvest.mp4" \
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1" \
  -r $FPS -c:v libx264 -pix_fmt yuv420p -t 7 "$GF"

# farm card is index 3 (0-indexed); put gameplay right after it
LIST=( "${LIST[@]:0:4}" "$GF" "${LIST[@]:4}" )

for f in "${LIST[@]}"; do echo "file '$f'"; done > "$TMP/list.txt"
ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$TMP/list.txt" -c copy "$TMP/concat.mp4"

DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$TMP/concat.mp4")
FADEOUT=$(echo "$DUR - 2.5" | bc -l)
ffmpeg -hide_banner -loglevel error -y -i "$TMP/concat.mp4" -stream_loop -1 -i "$ROOT/$PRES/bgm.wav" \
  -filter_complex "[1:a]afade=t=in:st=0:d=1.5,afade=t=out:st=${FADEOUT}:d=2.5,volume=0.9[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -t "$DUR" -movflags +faststart "$OUT"
echo "--- DONE: $OUT ($DUR s) ---"