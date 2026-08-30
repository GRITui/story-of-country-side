# Menu Structure & HUD Layout Logic — Flow Spec

Squad: UX-UI-Designer
Source: `backlog-inbox.md` item `UX-FLOW-01`
Scope: navigation flow and layout *logic* only — no final visual assets, no
color/typography tokens. Those are blocked on Decision E (art style, issue
#6) per the run brief; this doc is deliberately stack- and style-agnostic so
it stays valid regardless of that outcome.

Grounded in the sub-issues under epic #8 (Core Gameplay Loop) and epic #10
(Progression & Economy), since HUD content is driven by what state those
systems track (time/stamina from #12, inventory/shipping from #22, skills
from #25).

## 1. Top-level menu structure

```
Title Screen
├── New Game
│   ├── Farm name / character name entry
│   ├── (if Decision D ships co-op) Solo vs. Co-op mode select
│   └── (if Decision A ships Homestead Challenge) Challenge-mode toggle
├── Continue
│   └── Save slot list (thumbnail, in-game date, playtime)
├── Settings
│   ├── Audio
│   ├── Controls / input rebinding
│   └── Accessibility (text size, colorblind palette, screen shake)
└── Quit

In-Game Pause Menu
├── Resume
├── Inventory (full-screen, see §3)
├── Map
├── Skills / Progression (per #25)
├── Settings (same subtree as above)
└── Save & Quit to Title
```

**Rule:** the pause menu freezes game time, matching the existing
time-freeze precedent already scoped for festivals in #21 — one time-freeze
mechanism, reused by both systems, not two competing ones.

## 2. HUD layout (always-on, during free play)

```
┌─────────────────────────────────────────────────────────────┐
│ [Date/Season/Weather]                      [Gold]  [Clock]  │  ← top bar
│                                                                │
│                                                                │
│                        (game viewport)                        │
│                                                                │
│                                                                │
│ [Stamina bar]                                    [Hotbar]     │  ← bottom bar
└─────────────────────────────────────────────────────────────┘
```

- **Top-left cluster** (date/season/weather): read-only, sourced from the
  Time & Stamina foundation (#12). No interaction target.
- **Top-right cluster** (gold, clock): gold updates on Shipping Bin payout
  (#22); clock is the same clock instance #12 owns — HUD never keeps its
  own duplicate timer state.
- **Bottom-left** (stamina bar): direct visual mapping to #12's stamina
  value. Pass-out threshold gets a distinct visual state (not just "empty")
  since #12 scopes a pass-out penalty as a distinct event from merely being
  at 0.
- **Bottom-right** (hotbar): tool/item quick-select. Slot count is a design
  parameter, not fixed by this spec — leave as an open variable for
  Engineer squad to bind to inventory size.

**Rule:** the HUD reads from a single shared game-state object per cluster
(time/season/weather from one source, gold/inventory from another). This
spec does not prescribe the state management approach (that's an
Engineer-squad implementation decision) but does prescribe that HUD panels
are pure display of engine-owned state — no HUD-local duplicate state, to
avoid the two-clocks/two-gold-counters class of bug.

## 3. Full-screen inventory / menu screens

Applies to Inventory, Map, and Skills screens (§1 pause-menu children).

- All three are full-screen overlays, not panels layered over the live
  viewport — this matches the pause-menu time-freeze in §1 (nothing should
  render as "live" behind a full-screen menu, to avoid a state-desync class
  of bug where the player thinks the game is paused but stamina/time still
  ticks).
- Consistent screen chrome: title top-left, close/back control top-right
  (same physical location across all three, so the input binding is
  learned once).
- Inventory grid uses the same slot component as the hotbar (§2) — one
  slot-rendering component, reused, not two separate implementations.

## 4. Open items for Engineer squad (not decided by this spec)

- Exact hotbar slot count and inventory grid dimensions (depends on item
  count once Agriculture/Ranching/Fishing/Foraging land — #13/#14/#15/#17).
- Whether HUD clusters are separate components/nodes or one combined HUD
  scene — an implementation detail once the engine/stack is chosen
  (currently blocked on `ENG-STACK` in `backlog-inbox.md`).
- Co-op HUD variant (second player's stamina/hotbar) is out of scope until
  Decision D (#5) resolves single-player vs. co-op.

## 5. Controls / input map (#101)

Added by Frontend Squad, Sprint 2, closing this doc's own previously-empty
gap on movement/controls (verified at the time #101 was filed: zero
mentions anywhere in this file).

Registered named actions (`project.godot`'s `[input]` section):

| Action                          | Default binding(s)     | Wired to |
|----------------------------------|-------------------------|----------|
| `move_up` / `move_down` / `move_left` / `move_right` | WASD + Arrow keys | `PlayerAvatar.move_by_input()`, polled once per frame in each world scene's `_process()` |
| `interact`                       | E                        | Re-runs that world scene's own click-to-interact cycle (`_handle_tile_click`) against the tile one step in front of the avatar's current facing direction |
| `advance_dialog`                 | Space, Enter             | `IntroSequence._unhandled_input` (replaces the built-in `ui_accept` it used before named actions existed) |
| `hotbar_1`..`hotbar_5`           | 1-5                      | Registered as a foundation for #94's live hotbar; not consumed by anything yet -- no hotbar-slot binding system exists in this repo as of #101 |

**Interaction model stays hybrid, by design:** mouse-tile-click remains the
primary targeting input for every world scene (plant/water/harvest,
feed/brush/collect, break rock/descend ladder, gather) -- keyboard
movement and `interact` are additive, not a replacement, per #101's own
scope guard ("mouse-first interaction remains fully functional"). A player
can walk with WASD/arrows and press `interact` to act on whatever tile
they're facing, or just click tiles directly as before; both paths call
the same per-scene `_handle_tile_click`, so there is exactly one
interaction/validation path behind either input method.

**Pause toggle (`ui_cancel`, Escape) is unchanged** -- it was already a
named engine action, not a raw click/button-index check, so #101's "read
actions instead of raw button indices" ask doesn't apply to it.

**Non-goals (per #101's own scope guards, still true):** no combat
inputs (peaceful/no-combat was already decided); no gamepad remapping UI
in v1 -- actions are just registered as engine-remappable, no
rebind-key screen exists yet.

## 6. Traceability

| HUD/menu element      | Backing system issue |
|------------------------|----------------------|
| Clock / date / season  | #12 (Time & Stamina) |
| Stamina bar             | #12 |
| Gold                     | #22 (Shipping Bin economy) |
| Hotbar / inventory grid | #12 dependents (#13–#17), inventory shape TBD |
| Skills screen            | #25 (Skill Leveling) |
| Festival time-freeze reuse | #21 (Festivals) |
| Homestead Challenge toggle | #2 (Decision A) |
| Co-op mode select         | #5 (Decision D) |
| Controls / input map      | #101 (this doc's §5) |
