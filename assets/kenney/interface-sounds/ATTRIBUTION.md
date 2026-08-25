# Attribution — Interface Sounds (Kenney)

- **Original pack**: [Interface Sounds](https://kenney.nl/assets/interface-sounds) by [Kenney](https://kenney.nl) (www.kenney.nl)
- **License**: CC0 1.0 Universal (public domain dedication) — see `License.txt` in this directory, copied verbatim from inside the pack itself. Free for personal, educational, and commercial use; attribution appreciated but not required.
- **Retrieved via**: [Calinou/kenney-interface-sounds](https://github.com/Calinou/kenney-interface-sounds), a GitHub-hosted, Godot-oriented repackaging of this same Kenney pack maintained by Hugo Locurcio (Calinou), a Godot engine core contributor — not a redistribution loophole, Kenney's own CC0-1.0 license explicitly permits this. Files there are converted from the original OGG to WAV (that repo's own README states this is a lossless conversion for lower CPU cost / better Godot compatibility, not a re-edit of the audio content). This environment's egress policy blocks kenney.nl directly (confirmed via `curl`, consistent with the Art squad's own finding in `assets/kenney/isometric-miniature-farm/ATTRIBUTION.md`); GitHub itself (git-clone protocol) and `raw.githubusercontent.com` are reachable. Cloned read-only via `add_repo` + `git clone`, no push access needed.
- **License verified the same way the Art squad's precedent set**: read the pack's own bundled `License.txt` directly (copied here verbatim), not just the mirror repo's own README label — genuine CC0-1.0, Kenney's own text, no ambiguity.
- **Files used here** (unmodified from the mirror, renamed to nothing — original filenames kept):
  - `pluck_001.wav` (0.11s) — used for `AudioManager`'s `"coin"` sfx (`ShippingBinManager.payout_processed`)
  - `confirmation_001.wav` (0.30s) — used for `"harvest"` sfx (`FarmPlotManager.crop_harvested`)
  - `bong_001.wav` (0.13s) — used for `"heart"` sfx (`RelationshipManager.heart_event_triggered`)
  - `select_006.wav` (1.95s, the pack's one noticeably longer/more elaborate "select"-prefixed sound) — used for `"wedding"` sfx (`MarriageManager.married`)

## How these four were picked (an honest limitation)

This environment has no audio playback capability — nothing here was chosen
by ear. The mapping above was picked from Kenney's own semantic filenames
(`pluck`/`confirmation`/`bong`/`select` read as plausible fits for a coin
pickup, a positive action confirmation, a single notification chime, and a
bigger celebratory moment respectively) plus measured duration/file-size via
Python's `wave` module (shorter, snappier clips for the frequent SFX;
`select_006.wav` picked for `"wedding"` specifically because, at 1.95s, it's
a clear outlier among the pack's eight `select_*` files -- 001/002/007/008
are ~60ms clicks and 003-005 are ~385ms, so 006 is very likely a distinct,
more elaborate sound bundled under the same name prefix, not just another
short click). This is a reasonable best-effort, not a verified-by-ear
choice -- flagging for whoever next has real audio playback (or asks a
human) to swap any of these four if actually listening reveals a mismatch.
Swapping is a one-line change: each is loaded by `register_sfx_asset()` in
`audio_manager.gd`'s `_register_default_content()`.

## What's still procedural, and why

The `"ambient"` music track registered in `audio_manager.gd` is still a
procedurally generated sine drone (see that file's own docstring) -- this
Interface Sounds pack is SFX only, no music/ambient loop, and no fitting
free CC0 music track was found this round. Per the Studio Head's direction
(squad-handshake-audio.md epoch 2): "where nothing fitting exists yet, it's
fine to leave a procedural placeholder rather than force a bad fit" --
music search wasn't exhausted (Kenney's "Music Jingles"/"RPG Audio" packs
exist and are CC0, just not yet located through a reachable GitHub mirror
the way Interface Sounds was), so this isn't a final "no music exists"
verdict, just this round's honest stopping point.
