# Seasonal Palette Spec — Decision E Art Direction (Epsilon)

Source: Squad Epsilon, S-Tier P2 (Issues #112 / #113 / #115, Decision E).

This project has no external asset pipeline yet (see `squad-handshake-art.md`);
every pixel comes from procedural `Image`/`Color` math. The palette below is
the seasonal re-skin contract for `ProceduralTileArt` so seasonal transitions
read cozy without requiring per-tile hand-painted variants.

## Goals

- Four seasons should be instantly legible on the ground plane.
- Tint must apply as a *global multiplier* so existing `STATE_COLORS`
  dictionaries work unmodified (backward compatible).
- Accent speckles add a second read for Spring/Fall without recoloring
  the whole tile.

## Base seasonal tints

Applied as `Color(r * tint.r, g * tint.g, b * tint.b)` before shading:

| Season | R    | G    | B    | Read |
|--------|------|------|------|------|
| Spring | 1.04 | 1.06 | 1.02 | Slightly brighter + green push, fresh growth |
| Summer | 1.06 | 1.02 | 0.94 | Warm, sun-bleached |
| Fall   | 1.08 | 0.98 | 0.90 | Amber/golden, harvest warmth |
| Winter | 0.92 | 0.96 | 1.08 | Cool/desaturated, blue frost |

Unknown season falls back to Spring (identity-ish, safe default). All
multipliers are clamped `0..1` after application so no channel overflows
even on saturated tile colors.

## Accent variants (2 + extras)

Two primary re-skin accents, plus two supporting tints:

| Variant     | Color                | Usage |
|-------------|----------------------|-------|
| `blossom`   | `#F5B8CC` (pink)     | Spring interior speckles (~6% of pixels, 0.18 lerp) |
| `ember`     | `#DB7333` (amber)    | Fall interior speckles (same density) |
| `warm_light`| `#F5E08C` (pale gold)| Optional overlay for festival days / warm interiors |
| `frost`     | `#C7DBF5` (ice blue) | Optional winter overlay / snowfall mask |

Implementation: `ProceduralTileArt.get_seasonal_accent_color(variant)` returns
the `Color`; scenes that want décor can sample it. The generator itself only
applies `blossom` (Spring) and `ember` (Fall) speckles; the other two are
exposed for future HUD/FX without coupling here.

## Audio palette companion

Seasonal music uses procedural sine loops as placeholders until a composer
lands. Per-season center frequencies mirror the visual warmth:

- Spring **329.63 Hz (E4)** — bright
- Summer **392.00 Hz (G4)** — warm
- Fall **261.63 Hz (C4)** — mellow
- Winter **164.81 Hz (E3)** — sparse/low

`AudioManager.register_season_track(season, stream_path)` maps a future
`res://audio/music/<season>_theme.ogg` path to the procedural stand-in
today. When real assets land, only that mapping changes.

## Weather interaction

Rain/Snow/Storm days water all plots and, via the blue-shifted Winter tint
plus the `frost` accent, reinforce seasonal mood even on overcast days.
Storm adds a texture flag (`WeatherManager.is_storm_today()`) for optional
heavier FX without changing the core weather string.

## Traceability

- `scripts/world/procedural_tile_art.gd` — `get_seasonal_palette()`, tint path
- `scripts/autoload/weather_manager.gd` — storm flag, rain watering
- `scripts/autoload/audio_manager.gd` — `register_season_track` / seasonal frequencies
- `scripts/autoload/festival_manager.gd` — one festival per season, flavor_text
