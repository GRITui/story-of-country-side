# Squad Handshake — Audio (Composer/Sound Designer)

<squad_metadata>
  <squad_name>Audio-Squad</squad_name>
  <current_status>IDLE</current_status>
  <active_task_id>none</active_task_id>
  <sprint_completion_percentage>100</sprint_completion_percentage>
</squad_metadata>

## Epoch 31 note (Producer session, fix-forward on QA's finding)
QA-Tester's epoch 3 review found a residual `AudioStreamGeneratorPlayback`
leak reproducing on every test run since PR #75 -- narrower than the
track-switching leak this session's epoch 30 fix already covered:
`play_sfx()` had no way to release a one-shot's playback once it
finished naturally, unlike `play_music`'s `stop_music()` symmetry. Fixed
via PR #80 (squash-merged): a token-guarded `get_tree().create_timer()`
release on natural completion, plus a new public `stop_sfx()` the tests
now call in cleanup. 921/921 tests pass, zero leak warnings on
`--verbose`, clean smoke boot. Worth knowing for future audio work:
`stop_sfx()` is now the deterministic way to silence a one-shot early
(e.g. a Settings mute toggle, once one exists) rather than reaching into
the player directly.

## Real constraint (read this first)

This squad has no audio-synthesis or music-composition tool available in
this environment. Nothing shipped here is real composed music or a
designed sound effect the way a human sound designer would produce. What
this squad can build: the real integration layer (an `AudioManager`
autoload other managers' signals hook into) populated with honest
procedurally generated placeholder tones (sine-wave beeps/chimes/drones
via `AudioStreamGenerator`), not silence and not fabricated "finished"
audio. Every PR from this squad should say explicitly what's procedural
vs. what still needs a real composer/sound designer or a licensed SFX/
music library.

## Epoch 1 update

Confirmed via grep before starting: zero audio anywhere in the repo (no
music, no SFX, no `AudioStreamPlayer` usage) — this is a genuinely new
lane, not picking up existing audio work.

Shipped `AudioManager` (`scripts/autoload/audio_manager.gd`), registered
in `project.godot`'s `[autoload]` block after `WeatherManager` and before
`SaveManager`, matching the repo's established autoload-ordering
convention. Public API: `play_sfx(sfx_id)`, `play_music(track_id)`,
`stop_music()`, `get_current_music()`, `is_sfx_registered(sfx_id)`,
`is_music_registered(track_id)`, plus `sfx_played`/`music_changed`/
`music_stopped` signals — same "signals + read-only getters" contract
every other autoload in this repo follows.

All sound is procedurally generated at runtime, no audio assets on disk:
`AudioStreamGenerator`/`AudioStreamGeneratorPlayback` push a plain sine
wave. One-shot SFX push their full short duration up front; the single
registered "ambient" music track is a continuously-topped-up sine drone
(topped up every `_process` tick, since a generator buffer is finite) —
this is a drone, not a composed loop, and is documented as such in the
file's own docstring.

Wired four of the most obviously audio-worthy existing signals directly
in `AudioManager`'s own `_ready()` — same "backend-adjacent autoload
connects to another autoload's public signal" pattern
`InfrastructureManager` already uses for `TimeManager.day_started`:

* `ShippingBinManager.payout_processed` -> `"coin"` sfx
* `FarmPlotManager.crop_harvested` -> `"harvest"` sfx
* `RelationshipManager.heart_event_triggered` -> `"heart"` sfx
* `MarriageManager.married` -> `"wedding"` sfx

Read-only via public signals only, per `SQUAD-SPLIT.md`'s Backend
contract — no private-field access on any other manager. No `SaveManager`
integration: `AudioManager` holds no state worth persisting (current
music track resets cleanly on load/boot, same as first boot).

PR: gritui/story-of-country-side#75 (branch `feature/audio-manager`,
base `claude/farming-game-pm-requirements-w9ugtk`). 838/838 tests pass
(23 new) against the real Godot 4.3 engine headless — new tests verify
registration, `play_sfx`/`play_music`/`stop_music` return values and
signal firing (including the same-track-twice and already-stopped no-op
cases), and that each of the four real manager signals actually triggers
the right sfx via a direct `.emit()` call in the test, same convention
`test_runner.gd` already uses elsewhere to test signal-reactive code
(e.g. `ShippingBinManager.gold_changed.emit()` around line 1925 for HUD
tests). Headless has no real audio output device, so these tests verify
logic/wiring, not actual sound — called out in both files' docstrings.
Clean smoke boot (`--quit-after 60`), no `AudioServer` errors. Not tied
to an existing GitHub issue (#52/#53/#1 are Frontend/Content/process,
none audio) — noted in the PR description rather than forcing a link
that doesn't exist. Merge itself: see the Producer's note right below —
this session hit its rate limit right after opening the PR, so it
didn't self-merge this round.

## Epoch note (Producer session, merge assist)
This squad's session hit its 5-hour rate limit right after opening PR
#75, before it could self-merge. Producer verified independently against
the real Godot 4.3 engine headless (`--verbose` this time, not just the
default run) and found a real leak: `_start_music_loop()`/
`_start_one_shot_tone()` reassign the player's stream and call `play()`
again without stopping any still-playing prior stream first, orphaning
its `AudioStreamGeneratorPlayback` -- a genuine cumulative-leak risk over
a session with many track switches or rapid re-triggered SFX (e.g. lots
of harvesting/gifting in a short span), not just test-harness noise.
Fixed directly on `feature/audio-manager` (stop the player before
starting a new stream, both paths), re-verified 850/850 still passes,
resolved a real `tests/test_runner.gd` append conflict against the
moving base branch, squash-merged as PR #75. Worth knowing for any future
audio work: a fire-and-forget one-shot SFX left "playing" past its
synthesized duration is expected (no real-time frame ticking advances it
during a headless test) and isn't itself a bug -- the actual defect was
only in the *reassignment* path, not the one-shot's natural lifetime.

## Cross-Squad Requests

None blocking this round — all four signals hooked into were already
public before this PR.

## Escalation raised separately (not decided unilaterally)

Sent to the Studio Head (`session_01B5vPtzVbyrN4Xw86RSmBD6`) via
`create_trigger`/`persistent_session_id` (`trig_01SmE36gWWmYhv4WUrmQHW2D`,
fired 2026-08-19T07:21Z): whether this project should invest in a real
composer/sound designer or a licensed SFX/music library rather than
continuing on procedural placeholder tones. This is a genuine
scope/budget question, not something this squad can settle by building
more procedural content — flagging once and moving on rather than
re-raising it every epoch unless something changes.

## Remaining / ideas for next epoch

* More signal hookups exist that would be reasonable next candidates:
  `SkillManager.level_changed` (a level-up chime), `QuestManager`
  completion, `FestivalManager` start/end, `ToolManager` upgrade,
  `CommunityGoalManager` bundle completion. Deliberately kept this first
  pass to four signals rather than wiring everything at once.
* No settings/volume UI exists yet (no `scripts/ui/settings_overlay.gd` —
  `SQUAD-SPLIT.md`/Frontend's own notes flag Settings as blocked on a
  backend system that doesn't exist). `AudioManager` has no
  volume/mute API yet since nothing would consume it — add one once a
  Settings overlay is actually being built, not before.
* If real composed music/SFX ever becomes available (human sound
  designer or a licensed pack), `AudioManager`'s `register_sfx`/
  `register_music` calls in `_register_default_content()` are the single
  place to swap procedural definitions for real `AudioStream` resource
  paths — the public API (`play_sfx`/`play_music`) would not need to
  change for callers.
