# Modern Start Menu UI

Modern Start Menu UI presents Pokémon Red's START menu as a compact Gen 1
phone panel. The map remains visible on the left while every available action
appears in a paged three-by-three icon grid.

The mod changes presentation only. Pokémon, Bag, Pokédex, Trainer, Save,
Options, Link, Mods, Quit and third-party entries retain the callbacks built by
the engine and by `ui.start_menu.items` mods.

## Install

Import the packaged `.zip` or `.modpkg` from the game's Mods manager and enable
**Modern Start Menu UI**, then use **Apply & Restart**. Disabling it restores
the classic list without changing the save file.

## Controls

- Left/Right moves one tile.
- Up/Down moves one grid row.
- A opens the selected action.
- B or Start closes the panel.

The current tile is restored the next time the menu opens. More than nine
entries create additional pages automatically. Long labels scroll through the
footer, and entries with no recognized ID receive a generic menu-symbol tile.

## Themes

Open **Options → Phone Theme** to switch between four saved treatments:

- **MAP** inherits the current location and remains the default.
- **RED** uses a warm Pokédex-inspired coral and crimson ramp.
- **BLUE** uses a cool cyan and navy ramp.
- **DMG** uses the classic green handheld ramp.

Fixed themes recolour only the phone shell, leaving the visible map unchanged.
The game's global **Colors** setting still has final say, so forced grayscale,
inverted and Classic display modes continue to behave consistently.

On a portrait phone the panel uses a tall transparent native-pixel surface and
sits in the upper usable third, below top overlays and above visible touch
controls. Landscape and Faithful Ratio layouts retain the compact 160×144
surface with a four-pixel screen inset. Survey zoom continues to affect the
map, but no longer scales the phone panel down with it; controller overlays can
therefore reserve part of the phone without making the menu hard to read.

The bundled icons are a native 16×16 one-bit PNG atlas. Nine frames use
NikoIchu's clean CC0 Pixel Icons directly on their original grid; the Pokémon
party frame is a matching custom Poké Ball. The offline packer changes only
the source's black/white canvas into opaque ink and transparency. It never
crops, scales, traces, interpolates or cleans up the source pixels. The active
display palette recolours that single ink shade alongside the themed panel.

## Compatibility

The presentation consumes the final `ui.start_menu.items` result. Mods may keep
using legacy `{ label, onSelect }` rows unchanged; optional `id` and
`shortLabel` fields improve icon and caption selection. On newer engines the
mod uses `ui.start_menu.presentation`. On earlier API 2 mobile builds it falls
back to the existing `screen.pushed` lifecycle event, after the finished menu
has been placed on the stack. A total replacement remains compatible when it
exposes the usual StartMenu controller fields (`items`, `update`, and `draw`).
Legacy rows labelled with the current player name are recognized as the
trainer profile; other unknown labels retain their caption and receive the
generic menu icon.

## Develop

From the Gen1Recomp repository root:

```sh
python3 tools/modkit.py validate mods/modern_start_menu_ui --base auto
luajit mods/modern_start_menu_ui/tests/modern_start_menu_ui_test.lua
python3 tools/modkit.py pack mods/modern_start_menu_ui \
  -o build/modern_start_menu_ui.modpkg
```

For an in-engine screenshot preview:

```sh
SHOT_DIR=/tmp/modern-start-menu-ui \
POKEPORT_DRIVER=mods/modern_start_menu_ui/tests/preview_driver.lua \
POKEPORT_IDENTITY=modern-start-menu-ui-preview love .
```

The reproducible icon-art pipeline and source provenance live in
`art/modern_start_menu_ui/README.md`. The selected source PNGs are development
files and are not included in the `.modpkg`.

To rebuild the production atlas directly from the selected native sprites:

```sh
tools/start_menu_icon_nikoichu/run.sh
```

## Credits

- Gen1Recomp for the native mod platform and original renderer.
- pret/pokered for the reference behavior of the START menu.
- NikoIchu for the CC0 [1-bit Pixel Icons](https://nikoichu.itch.io/pixel-icons)
  used by the menu.
- ishhodaszi for the matching one-bit Poké Ball.
