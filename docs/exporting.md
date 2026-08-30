# Exporting "Story of Country Side"

The repo ships a committed `export_presets.cfg` with three presets, so a clean clone
can produce builds without manually reconfiguring the Godot export dialog.

## Pinned engine version

All presets target **Godot 4.3-stable** (the project's `project.godot` declares
`config/features=PackedStringArray("4.3", "GL Compatibility")`, and the rendering
method is `gl_compatibility` for both desktop and mobile). Use the matching editor —
not a newer minor — so import caches and export output stay reproducible.

## Export templates

- Export templates are **not** committed to the repository.
- Before the first export, install them **once** per machine, either from the Godot
  editor (**Editor ▸ Manage Export Templates ▸ Download and Install**) or by letting
  `--export-*` prompt for them.
- `export_presets.cfg` only describes *what* to export; the template binaries come
  from your local Godot install.

## Clean-clone web build

```sh
godot --headless --path . --export-release Web export/index.html
```

or, via npm:

```sh
npm run build:web
```

This produces `export/index.html` (plus the `.pck`, `.wasm`, and `.js` files beside
it). The Playwright webServer in `playwright.config.ts` is written to serve this
directory, so once the export exists you can point E2E tests at the real canvas.

## Presets

| Preset            | Export path                              | Notes |
|-------------------|------------------------------------------|-------|
| `Web`             | `export/index.html`                      | Threadless (see below) |
| `macOS`           | `export/macos/story-of-country-side.app` | Universal binary, codesigning disabled |
| `Windows Desktop` | `export/windows/story-of-country-side.exe` | x86_64 |

Each preset is versioned `1.0` and uses `export_filter="all_resources"` with an
exclude filter that keeps `.godot/`, `node_modules/`, `tests/`, `artifacts/`,
`marketing/`, and `content/` out of the build.

## Web threading decision

The Web preset ships **threadless** (`variant/thread_support=false`). A threadless
build does not use SharedArrayBuffer, so it runs on any static host without the
COOP/COEP response headers that a threaded build requires (GitHub Pages, itch.io,
`python3 -m http.server`, and the local Playwright webServer all serve fine without
them). This maximizes hosting compatibility for the cheapest-to-host artifact.

If you ever need a threaded build (e.g. multithreaded physics/audio and you control
the hosting headers), flip `variant/thread_support=true` in `export_presets.cfg` and
re-export — but keep the committed preset threadless by default.

## macOS codesigning

`codesign/codesign=0` (disabled) keeps clean-clone builds reproducible without an
Apple identity. Re-enable signing in the editor when you have distribution
credentials.