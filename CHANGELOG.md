# Changelog

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
