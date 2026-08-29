# Modern Start Menu UI

Modern Start Menu UI presents Pokémon Red's START menu as a compact Gen 1
phone panel. The map remains visible on the left while every available action
appears in a paged three-by-three icon grid.

Gold, Silver, and Crystal use the same phone panel over the native Gen 2 START
controller, including PACK and POKéGEAR actions.

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
Buttons show only their centred 16×16 symbol; the full selected label in the
footer provides the name without squeezing tiny duplicate text into each tile.

After opening START once, use **Options → Modern Start Menu**. The dedicated
page contains the phone theme, horizontal position, header clock and one row
for every third-party START action.
Selecting an action opens a two-page 4×4 visual grid. Leave it on **Auto** to
use the entry's ID or label, or choose from 31 explicit native symbols such as
Dex, PKMN, Bag, Quest, Map, Music, Camera, Trophy, Tools, Mail, Shop, Battle,
Potion, Bike and Search. Overrides are saved per entry and apply immediately.
Common third-party `DEX` and `PARTY` labels are recognized automatically.

## Themes

Open **Options → Modern Start Menu → Phone Theme** to switch between four
saved treatments:

- **MAP** inherits the current location and remains the default.
- **RED** uses a warm Pokédex-inspired coral and crimson ramp.
- **BLUE** uses a cool cyan and navy ramp.
- **DMG** uses the classic green handheld ramp.

Fixed themes recolour only the phone shell, leaving the visible map unchanged.
The game's global **Colors** setting still has final say, so forced grayscale,
inverted and Classic display modes continue to behave consistently.

## Position and clock

**Menu Position** offers Left, Mid-L, Center, Mid-R and Right. Right remains
the default. On wide desktop displays this moves only the finished phone panel
across the window; it does not resize or recenter the game canvas. Compact,
Faithful Ratio and mobile-overlay layouts apply the same preference within
their native viewport.

**Header Clock** defaults to **Play**, preserving the elapsed play-time display
used by previous releases. Choose **Device** for the phone or computer's local
24-hour time.

The panel always leaves the renderer's native 160×144 UI surface unchanged.
It therefore inherits the player's centred/top/high screen composition
instead of recentering the world when START opens, and the SAVE prompt takes
over without moving the underlying game. A wide desktop redraws only the phone
after that stable frame is composed. Faithful Ratio, portrait displays and
mobile touch/controller overlays retain the native surface. Survey zoom
continues to affect the map, but no longer scales the phone panel down with it.

The bundled icons are a native 16×16 one-bit PNG atlas. Thirty-one frames use
NikoIchu's clean CC0 Pixel Icons directly on their original grid; the Pokémon
party frame is a matching custom Poké Ball. The offline packer changes only
the source's black/white canvas into opaque ink and transparency. It never
crops, scales, traces, interpolates or cleans up the source pixels. The active
display palette recolours that single ink shade alongside the themed panel.

## Compatibility

The presentation consumes the final `ui.start_menu.items` result. Mods may keep
using legacy `{ label, onSelect }` rows unchanged; an optional stable `id`
improves automatic icon selection and saved override keys. On newer engines the
mod uses `ui.start_menu.presentation`. On earlier API 2 mobile builds it falls
back to the existing `screen.pushed` lifecycle event, after the finished menu
has been placed on the stack. A total replacement remains compatible when it
exposes the usual StartMenu controller fields (`items`, `update`, and `draw`).
Legacy rows labelled with the current player name are recognized as the
trainer profile; other unknown labels retain their footer name and receive the
generic menu icon until the player chooses an override. Latin-script accents
are folded into the compact alphabet (`Ç` to `C`, `Õ` to `O`, and so on),
while other scripts retain the game's native-font footer fallback.

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
