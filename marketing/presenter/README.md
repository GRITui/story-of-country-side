# Game-Manual Video — build pipeline

Everything needed to reproduce
`marketing/story-of-countryside-manual.mp4`
(a ~78s 1280×720 illustrated player-manual reel with a procedurally
synthesized BGM — well under 30 minutes).

## Pieces

- `make_frames.py` — renders the 10 illustrated "manual card" scene PNGs
  into `frames/` from the pixel-art assets in `assets/pixelart/**`
  (Arial Rounded Bold is used for the friendly headings).
- `gen_music.py` — synthesizes `bgm.wav` (≈48s, 44.1 kHz mono) with NumPy:
  a cheerful chime/kalimba melody over soft pads + light percussion, in a
  C-major pentatonic feel. No licensed samples; fully procedural & CC0-free
  to distribute.
- `make_video.sh` — assembles the final MP4: applies a gentle Ken Burns zoom
  to each card, inserts the real-gameplay clip
  (`marketing/farmscene-plant-water-harvest.mp4`, a farming loop) after the
  farm card, concatenates, then muxes the **looped** BGM with a fade in/out.

## Reproduce

```bash
cd marketing/presenter
python3 make_frames.py          # (re)render scene cards
python3 gen_music.py            # (re)synthesize bgm.wav
./make_video.sh                 # assemble the final MP4
```

Requirements: Python 3 + Pillow + numpy, and `ffmpeg` / `ffprobe` on PATH.

## Output

`marketing/story-of-countryside-manual.mp4`
- resolution 1280×720, 30 fps, H.264 + AAC
- duration ≈ 78 s
- audio: looped BGM, mean ≈ −18 dB / max ≈ −2.4 dB