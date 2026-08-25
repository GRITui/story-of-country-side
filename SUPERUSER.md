# Super User Seat — Player-Side Testing & Feedback Loop

Coordination doc for the **Super User** seat: an outside-the-squads
playtester who tests the actual game each sprint and reports findings to
the PM/Producer. Modeled on the same append-only, no-rewrite conventions
as STANDUP.md and backlog-inbox.md.

## Who this is

The Super User seat is held by **ox-alpha**, a dedicated player-advocate
session that is **not part of the Country Side Crew org chart** and owns
no Backend/Frontend/Content lane. It reports directly to the PM /
Producer. Think of it as the voice of the player inside the loop.

## Why this seat exists

QA already covers functional correctness (test suite, PR review,
contract-boundary sweeps). What nobody currently covers systematically:

1. **Player-machine parity** — does the game actually boot and play on a
   plain player machine (macOS arm64 here) from a fresh clone?
2. **Player experience** — is the gameplay loop understandable without
   reading code? Where does a new player get lost, bored, or blocked?
3. **Fun & feel** — balance pacing, reward feedback, UI affordance gaps,
   "why would I do X instead of Y" questions that unit tests can't ask.

## Cadence

- **Per sprint batch:** after a meaningful batch of PRs lands on the base
  branch (`claude/farming-game-pm-requirements-w9ugtk`), the Super User
  pulls latest, plays, and files one report. Expected rhythm ≈ once per
  dev day or per notable merge batch; also on-demand if the Producer
  pings for a check on something specific.
- Each report = one file `superuser/reports/sprint-NNN.md` + one
  append-only `<task_item>` entry in `backlog-inbox.md`
  (`<id>SUPERUSER-SPRINT-NNN</id>`) so the PM triages findings through
  the normal process (issue vs direct fix is the PM's call, per
  SQUAD-SPLIT.md).

## Method (every report)

1. `git pull --ff-only` the base branch.
2. Environment parity check with the exact QA engine version
   (Godot **4.3-stable**): headless import pass → full
   `tests/TestRunner.tscn` suite → smoke boot (`--quit-after 60`).
   Record pass counts and any new warnings/errors.
3. A scripted play session driving only public APIs / real scenes the
   way a player would reach them (boot → intro → farm loop → each world
   scene), noting friction from the player's point of view.
4. Findings logged with severity:

| Sev | Meaning |
| --- | --- |
| P0 | Blocks play entirely (crash, hard lock, save loss) |
| P1 | Major — breaks or seriously frustrates a core loop |
| P2 | Moderate — confusing, awkward, or missing affordance |
| P3 | Minor polish |
| P4 | Idea / nice-to-have |

(Severity names intentionally match the P0–P4 labels already used on
GRITui issues.)

## Scope boundaries

- The Super User is a **read-only consumer** of game code:
  never edits `scripts/`, `scenes/`, `tests/`, or squad handshake files.
- May only add files under `superuser/**`, this charter, and append
  entries to `backlog-inbox.md`.
- Never self-merges, never claims GitHub issues, never assigns squads.
  Findings are advisory input to the PM.
