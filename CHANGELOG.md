# Changelog

## 0.1.13

- Prevented fixed phone-theme palette zones from leaking into Save summaries,
  YES/NO choices and dialogue boxes when a compatible START controller keeps
  the phone beneath the transparent Save stack.
- Restored the normal inherited full-screen palette for overlays while
  retaining the selected theme whenever the phone itself is active.

## 0.1.12

- Consolidated every in-game preference under one **Modern Start Menu** row
  in Options, with a dedicated phone-theme and mod-entry settings page.
- Added a two-page 4×4 visual selector for third-party START actions, with 32
  native choices including Auto, Quest, Map, Music, Camera, Trophy, Tools,
  Mail, Shop, Battle, Potion, Bike, Craft and Search.
- Expanded the atlas from 10 to 32 native 16×16 one-bit frames selected from
  NikoIchu's CC0 Pixel Icons v1.2; no scaling, tracing or interpolation is used.
- Removed the duplicate miniature captions from each START button and
  vertically centred the icons; the full selected action name remains in the
  footer.
- Persisted picker changes immediately and refreshed the settings row without
  requiring the menu or game to be reopened.

## 0.1.11

- Kept START on the game's existing 160×144 render surface on every display,
  preventing screen-position modes and the SAVE prompt from recentering the
  map or moving the phone panel when they take over.
- Added saved per-entry icon selectors to the regular Options screen for
  third-party START actions, with AUTO plus every bundled native icon.
- Recognized common DEX/PARTY aliases automatically and folded Latin accents,
  so Portuguese labels such as `OPÇÕES` render cleanly as `OPCOES` instead
  of broken question marks.
- Accepted Gen 2's native split play-time clock when drawing the phone header,
  preventing Gold, Silver and Crystal from crashing as START opens.
- Labelled the Gen 2 POKéGEAR action as GEAR instead of LINK. Genuine Link
  actions retain their own LINK caption.

## 0.1.10

- Kept the native 160×144 UI surface whenever the mobile touch/controller
  overlay is active, so opening START cannot change the renderer's fit scale.
- Prevented the overworld and phone panel from shrinking together when a
  Pocket Taco or another mobile overlay already reserves part of the screen.
- Retained the centred overlay composition, Faithful Ratio behavior and the
  optional tall portrait layout when mobile controls are genuinely absent.

## 0.1.9

- Vertically centred the phone panel across compact, landscape and portrait
  layouts instead of biasing it toward the top edge.
- Centred portrait layouts inside the usable play area above visible touch
  controls, retaining the right-edge dock and readable survey-zoom scale.
- Kept Faithful Ratio inside the renderer's centred native 160×144 viewport,
  fixing the panel being pinned to the physical top of tall phone screens.

## 0.1.8

- Kept the phone panel at the normal readable UI scale when the overworld is
  using survey zoom, instead of shrinking the menu along with the map.
- Preserved Dynamic UI's top-right docking and the map's selected zoom level,
  including portrait setups that reserve the lower screen for a Pocket Taco
  or another controller overlay.
- Added a regression case and an adjustable survey-zoom screenshot preview.

## 0.1.7

- Replaced the generated and traced menu artwork with clean native 16×16
  symbols selected from NikoIchu's CC0 1-bit Pixel Icons collection.
- Added a matching hand-authored one-bit Poké Ball for the Pokémon party tile.
- Replaced the cramped two-letter third-party overlay with NikoIchu's clean
  menu-symbol fallback; the tile caption and footer still identify the entry.
- Kept every source sprite on its original 16×16 grid with no scaling,
  tracing, interpolation or cleanup pass.
- Retained the existing icon offset, menu layout, themes, navigation and
  third-party action handling.

## 0.1.6

- Added saved `MAP`, `RED`, `BLUE` and `DMG` phone themes, selectable from
  both the regular in-game Options screen and the mod manager.
- Kept `MAP` as the default so the panel continues to inherit each location's
  palette, including the lime/cyan route combination.
- Scoped fixed themes to the 104×136 phone shell; the overworld retains its
  own palette and responsive placement remains unchanged.

## 0.1.5

- Recognize the legacy trainer row by the current player name, restoring a
  clearly differentiated trainer ID-card sprite and compact `ID` caption on
  API 2 phones.
- Added a portrait-native transparent UI surface and placed the panel in the
  upper usable third, clear of both the top overlay and lower touch controls.
- Inset the compact 104×136 shell from the screen edges and extended inherited
  map palette zones so every relocated row remains visible and colorized.
- Rebuilt the icon atlas from individually generated flat masters, using
  Pixfix 0.2.0 plus deterministic 16×16 contour and palette cleanup to remove
  speckling, broken outlines and source-antialiasing artifacts.

## 0.1.4

- Added an API 2 `screen.pushed` compatibility path for mobile engine builds
  that predate the dedicated START-menu presentation hook.
- Kept the final engine-built item list intact, including third-party rows
  such as CACHE, while applying the phone panel after construction.
- Made the legacy path idempotent so newer engines still use the native hook
  without double-wrapping the controller.

## 0.1.3

- Moved every menu icon down by one native pixel inside its tile.
- Removed internal white highlight holes before pixel-grid conversion so solid
  icon bodies no longer lose chunks when transparency is applied.
- Repaired broken contours and stray pixel clusters across the complete icon
  set, including the capture ball, backpack, trainer, gear and power symbol.

## 0.1.2

- Re-concepted the complete menu in a flat icon style using the real in-game
  screenshot as the image-generation edit target.
- Replaced the rejected hand trace with Pixfix grid recovery and
  center-weighted pixel voting from the selected generated shapes.
- Limited the resulting native 16×16 icons to three opaque shades, binary
  transparency and a shared outline/accent/fill system.
- Added a repeatable image-generation-to-Pixfix atlas build pipeline.

## 0.1.1

- Replaced the hand-authored icon bitmaps with professionally generated source
  art normalized into a single four-tone PNG atlas.
- Reworked the Pokédex as a simpler closed device so its silhouette remains
  legible at native size.
- Added binary transparency, nearest-neighbour rendering and a deterministic
  source-to-16×16 art pipeline.

## 0.1.0

- Added the Gen 1 phone-panel START menu presentation.
- Added a paged three-by-three tile grid with full directional navigation.
- Added four-tone icons for every built-in action and generic third-party
  monogram tiles.
- Preserved final hooked item lists, callbacks, save cursor, menu sounds,
  conditional entries and Safari status.
