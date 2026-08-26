-- Native 16x16 one-bit frames from NikoIchu's CC0 Pixel Icons, plus a
-- matching custom Poké Ball for the party action. The source grid is copied
-- directly: no scaling, tracing, interpolation, or runtime conversion.
-- Keeping frame lookup separate from rendering lets third-party entries fall
-- back to the generic frame without taking ownership of their callback or
-- label.
return {
  asset = "assets/start_menu_icons.png",
  size = 16,
  paletteSize = 1,
  frames = {
    pokedex = 0,
    party = 1,
    bag = 2,
    trainer = 3,
    save = 4,
    options = 5,
    link = 6,
    mods = 7,
    quit = 8,
    generic = 9,
  },
}
