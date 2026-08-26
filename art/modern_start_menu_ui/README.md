# Modern Start Menu icon sources

## Production NikoIchu set (v0.1.7)

The current atlas uses selected files from NikoIchu's native 16×16
[1-bit Pixel Icons](https://nikoichu.itch.io/pixel-icons), released under
CC0 1.0. Source frames live in `nikoichu/source/`; exact converted frames live
in `nikoichu/native/`.

| Menu frame | Selected NikoIchu source |
| --- | --- |
| Pokédex | `Tools_Crafting_Books_Manual_Codex_Instructions_Tutorial_Documentation.png` |
| Bag | `Travel_Backpack_Bag_School.png` |
| Trainer | `Travel_Person_Player_Character_Single.png` |
| Save | `Software_Save_Button_Floppy_Disk.png` |
| Options | `Software_Options_Settings_Sliders_Knobs_Audio.png` |
| Link | `Software_Link_Chain_Shortcut_Combo.png` |
| Mods | `Software_Options_Settings_Cogwheel_Gear_Mechanics.png` |
| Quit | `Software_Exit_Quit_Crossout_Button.png` |
| Generic mod | `Controller_Buttons_Menu_Options_Settings.png` |

The party frame is a custom symmetrical one-bit Poké Ball declared directly
in `tools/start_menu_icon_nikoichu/main.lua`. The packer asserts a 16×16
source grid, pure one-bit input, binary transparency, one opaque output shade
and at least one visible pixel per frame. It preserves every source coordinate
exactly and performs no scaling, tracing, interpolation or contour cleanup.

Rebuild from the repository root:

```sh
tools/start_menu_icon_nikoichu/run.sh
```

Only the resulting `mods/modern_start_menu_ui/assets/start_menu_icons.png`
ships at runtime. `mods/modern_start_menu_ui/THIRD_PARTY_NOTICES.md` records
the CC0 source in the distributable package.

## Archived independent-master set (v0.1.5)

The v0.1.5 atlas replaces the screenshot-wide trace with ten independently
generated flat masters. This gives each subject a strong isolated silhouette
before it reaches the native grid and prevents neighboring cells, captions or
selection borders from contaminating the vote.

- Selected masters: `generated_masters_v2/*.png`
- Final prompt set and generation IDs: `generated-v2-prompts.md`
- Standardized Pixfix inputs: `pixfix/generated-v2-source/*.png`
- Pixfix 16×16 votes: `pixfix/generated-v2-logical/*.png`
- Native sprites: `pixfix/native/*.png`
- Shipped atlas: `mods/modern_start_menu_ui/assets/start_menu_icons.png`
- Rebuild entry point: `tools/start_menu_icon_pixfix/run-generated-v2.sh`

OpenAI's built-in image-generation tool created the transparent grayscale
masters in text-to-image mode. Each prompt limits the design to a connected,
flat silhouette and at most three opaque colors. The rebuild script places
variable-sized outputs on a common 1254×1254 transparent square, then runs
Pixfix 0.2.0 with a forced 78.375px pitch (1254 / 16), center-weighted logical
voting and the committed flat-icon palette. The capture ball keeps that clean
Pixfix vote directly; the less regular subjects use an area vote over their
opaque bounds before the shared native contour repair.

The packer asserts 16×16 frames, binary transparency, and no more than three
opaque DMG shades. It removes tiny disconnected debris, fills only unintended
enclosed holes, reasserts black boundary cells, and centers every silhouette.
No generated source or conversion dependency ships in the gameplay archive.

### Rebuild v0.1.5

```sh
POKEPORT_ICON_ROOT="$PWD" \
PIXFIX_BIN=/path/to/pixfix \
tools/start_menu_icon_pixfix/run-generated-v2.sh
```

The run used Pixfix 0.2.0 commit
`73ffde49dc0c8e2364c3e3b2b61284e03a8854a2`.

## Production Pixfix set (v0.1.3)

The shipped icons are recovered native pixel graphics, not a hand trace.
OpenAI's built-in image-generation tool first edited the real in-game
screenshot in `precise-object-edit` mode to establish one coherent flat-icon
set. Pixfix 0.2.0 then detected and voted the generated pixel clusters onto a
native grid.

- Edit target: `build/previews/modern_start_menu_ui/current-setup/v0.1.1-generated-masters.png`
- Production composite: `flat-icon-concept-final.png`
- Cleanup prompt set: `cleanup-prompts.md`
- Pixfix source crops: `pixfix/source/*.png`
- Pixfix logical-pixel output: `pixfix/logical/*.png`
- Native 16×16 sprites: `pixfix/native/*.png`
- Shipped atlas: `mods/modern_start_menu_ui/assets/start_menu_icons.png`
- Conversion entry point: `tools/start_menu_icon_pixfix/run.sh`

The original selected concept was generated as
`exec-c5de1f7c-5af3-43f4-a1db-5109cb75acbe.png`. Built-in image-generation
mode: `precise-object-edit`. Prompt:

```text
Use case: precise-object-edit
Asset type: game UI screenshot concept for direct native-sprite tracing
Input images: Image 1 is the edit target and must remain the base screenshot
Primary request: change only the nine pictogram icons inside the 3x3 START-menu
cells. Redesign them as one cohesive set of crisp, flat 16x16-style pixel icons
with strong professional silhouettes and no more than three opaque colours per
icon: near-black outline, sky-blue accent, and warm gray fill. Use no gradients,
texture, highlights, or antialiasing.
Icon subjects: closed handheld encyclopedia; capture ball; front-facing
backpack; cap-wearing trainer bust; floppy disk; three horizontal sliders; two
cable plugs joined by a curved cable; eight-tooth hollow gear; broken-ring
power symbol.
Style/medium: expert flat Game Boy-era pixel icon design, chunky deliberate
clusters, consistent stroke, balanced negative space and equal visual weight.
Constraints: preserve the screenshot geometry, overworld, panel, cells,
selection, separators, typography, labels, palette and all non-icon pixels;
change only the nine pictograms; no new text or watermark.
Avoid: shading, gradients, gloss, texture, dithering inside icons, thin noisy
details, 3D depth, soft edges, inconsistent perspectives, childish doodles,
modern emoji and rounded app tiles.
```

The v0.1.3 cleanup used three additional built-in `precise-object-edit` passes
to close contours, replace unwanted white highlights inside solid icon bodies,
and simplify the capture-ball mechanism. The final production composite keeps
the verified complete-set cleanup and takes only the top-center party-icon crop
from the narrow third pass, rejecting collateral drift elsewhere. Exact inputs,
outputs and prompts are recorded in `cleanup-prompts.md`.

Pixfix removes remaining antialiasing mechanically using a forced
7-source-pixel pitch, majority-vote logical-pixel recovery and the shared
working palette in `pixfix/flat-icons.hex`. White is treated as the tile
background. The native packing stage maps the three remaining colors to DMG
shades `0`, `85` and `170`, makes the background transparent, removes tiny
disconnected debris, fills unintended enclosed holes, restores black boundary
cells and normalizes the explicitly symmetric subjects. It then centers each
recovered silhouette and fits only the 17-pixel-tall Link result to the 16×16
frame. The generic third-party tile reuses the recovered gear silhouette
beneath its runtime monogram.

The resulting atlas has binary transparency and no more than three opaque
colors per icon. The game recolors those grayscale shades through the active
four-color display palette; in Pewter's ADVANCED palette they become
near-black, sky blue and warm gray.

### Rebuild the native atlas

The conversion was verified with Pixfix 0.2.0 from commit
`73ffde49dc0c8e2364c3e3b2b61284e03a8854a2`. With `ffmpeg`, `love` and that
Pixfix executable available, run from the repository root:

```sh
POKEPORT_ICON_ROOT="$PWD" \
PIXFIX_BIN=/path/to/pixfix \
tools/start_menu_icon_pixfix/run.sh
```

The script recreates all screenshot crops, asks Pixfix for native logical
pixels, and runs the atlas packer. The packer verifies the 16×16 frame size and
three-opaque-color limit before writing the 160×16 production atlas.

Pixfix source: <https://github.com/lovelaced/pixfix>

## Archived generated masters (v0.1.1)

`generated_masters/` and `normalized/` preserve the earlier approach for
provenance. Those ten source images were created separately with the built-in
tool in `stylized-concept` mode, then reduced with
`tools/start_menu_icon_pipeline`. They are no longer consumed by the mod.

| Frame | Selected generation |
| --- | --- |
| Pokédex | `exec-db1d386c-fe16-4d17-bfe8-6cf737640405.png` |
| Party | `exec-70cf5b24-741b-40cd-ac33-04f34548ec2f.png` |
| Bag | `exec-de3418e1-564f-4f82-b543-c49225cfa067.png` |
| Trainer | `exec-7dec0d62-655b-499b-a5c3-e30eac34cdae.png` |
| Save | `exec-dc611b43-82b7-4dd5-ba5d-4ad1266d66dd.png` |
| Options | `exec-cbfbf4e3-7422-43f8-9abb-5737ecf9d56a.png` |
| Link | `exec-77d3abd1-b48b-4919-b6e5-c40a000f9b0f.png` |
| Mods | `exec-663df268-6802-4990-88c3-16326d2e2b8f.png` |
| Quit | `exec-c9905969-6ec2-4779-8608-1f4fb92b3ada.png` |
| Generic | `exec-b7cead95-4bc4-408a-a4a9-3404f62f9257.png` |
