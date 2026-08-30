# Super User Report — Sprint 001

- **Date:** 2026-08-25 (baseline pass)
- **Tested at:** base branch `claude/farming-game-pm-requirements-w9ugtk`
  @ `0de7f80` ("Writer/Dialogue Designer standup: idle…")
- **Machine:** macOS (Apple Silicon), fresh clone-equivalent state,
  Godot **4.3.stable.official.77dcf97d8** — same major.minor.patch as QA
  runs, installed from scratch for this test (player-machine parity).

## Environment parity check — PASS

| Step | Result |
| --- | --- |
| Headless editor import pass | Clean |
| Full suite `tests/TestRunner.tscn` | **959/959 checks pass**, exit 0 |
| Smoke boot (`--headless --quit-after 60`) | Clean boot, exit 0, no runtime errors |

Independently reproduced QA's epoch-3 PR #75 finding on a player machine:
every full-suite run still ends with
`WARNING: ObjectDB instances leaked at exit` /
`ERROR: 8 resources still in use at exit` (the AudioManager one-shot-SFX
playback path). This supports QA's fix-forward recommendation — it's
console-visible red noise on any player machine that shows logs, and it
masks future real leaks. Not blocking play.

(Note for honesty: this sprint's "play" was headless + code-flow
walkthrough; an interactive windowed session driving FarmScene by hand is
planned for Sprint 002.)

## What works well (tell the squads)

1. The intro narration voice is genuinely strong — the burnt-coffee /
   resignation-letter beat sells "escape the grind" better than any menu
   would. Content lane should treat this as the tone anchor.
2. HUD binds every displayed value to its owning autoload's signals with
   ready-time priming — no stale-clock/gold window for players.
3. Test count has grown 904 → 959 across recent merges without breaking
   the run here; the loop's green-build discipline holds on a second
   machine.

## Findings

### P1 — Saving during a festival silently loses the festival
`main_controller.gd` (docstring, festival sub-scope): FestivalManager has
no `to_save_dict()/from_save_dict()`; a festival active at save time is
not re-shown after reload. Player impact: save during a festival night,
reload next day, and the festival — plus its mini-game and rewards
window — is simply gone with no in-game explanation. Reads as a bug to a
player even though it's a known backend model gap.
**Ask:** either persist/re-derive active-festival state, or block/hint
saving while a festival is live. Whichever is cheaper; silent loss is the
harmful part.

### P2 — No title screen, no New Game/Continue choice
Boot auto-loads-or-creates a save and plays the intro once; there is no
moment where a player chooses anything (documented stand-in behavior in
`main_controller.gd`). A player who wants a fresh start has no path at
all. `design/ui-flows/menu-hud-flow-spec.md §1` already specs this flow
and Frontend-Squad standups say they're idle waiting on backend work —
this looks like the highest player-visible-value item currently unowned.

### P3 — Hotbar is dead UI
HUD ships an 8-slot empty placeholder strip with no items, icons, or
binding (deliberate, documented in `hud.gd`). Players see an affordance
that does nothing. Either hide the strip until item metadata exists, or
bind the starter tool into slot 0 so it teaches the pattern.

### P3 — Every boot returns to Farm
No last-location persistence (`main_controller.gd` flags this as a real
gap). A player who fell asleep in the mine wakes up on the farm. Low
urgency, cheap fix once SaveManager grows a location field.

### P3 — Intro has no advance hint or skip
Six text screens advance only via Space/Enter/click, with no "▼" hint and
no skip-all control. First-run players may click around; returning
players re-watching nothing (intro is once-per-save, so exposure is
low). Small polish: hint label on line 1 + hold-to-skip or Esc.

### P4 — Idea: settings/options system
Standups confirm Settings has no backend and Frontend is queued behind
it. Once real music lands (still procedural today), volume controls stop
being optional. Flagging early so it doesn't surprise anyone later.

## Tally

P0: 0 · P1: 1 · P2: 1 · P3: 3 · P4: 1

— Super User seat (ox-alpha), see `SUPERUSER.md` for charter/cadence
