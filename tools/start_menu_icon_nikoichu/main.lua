-- Packs the selected NikoIchu 1-bit Pixel Icons into the native 16x16 atlas
-- used by Modern Start Menu UI. Source coordinates are copied exactly: there
-- is no crop, scale, trace, interpolation, cleanup pass, or palette guess.
-- The only conversion turns the source's white marks into opaque black ink
-- and its black canvas into transparency. The party frame is a deliberately
-- authored one-bit Poké Ball on the same grid.

local ICONS = {
  "pokedex", "party", "bag", "trainer", "save",
  "options", "link", "mods", "quit", "generic",
}

local NIKO_SOURCE = {
  pokedex = "pokedex.png",
  bag = "bag.png",
  trainer = "trainer.png",
  save = "save.png",
  options = "options.png",
  link = "link.png",
  mods = "mods.png",
  quit = "quit.png",
  generic = "generic.png",
}

local PARTY = {
  "................",
  ".....######.....",
  "...##......##...",
  "..#..........#..",
  ".#............#.",
  ".#............#.",
  "#..............#",
  "######.##.######",
  "#.....#..#.....#",
  "######.##.######",
  "#..............#",
  ".#............#.",
  ".#............#.",
  "..#..........#..",
  "...##......##...",
  ".....######.....",
}

local SIZE = 16

local function join(root, suffix)
  if root:sub(-1) == "/" then return root .. suffix end
  return root .. "/" .. suffix
end

local function readAll(path)
  local file, err = io.open(path, "rb")
  assert(file, ("cannot open %s: %s"):format(path, tostring(err)))
  local bytes = file:read("*a")
  file:close()
  return bytes
end

local function writeAll(path, bytes)
  local file, err = io.open(path, "wb")
  assert(file, ("cannot write %s: %s"):format(path, tostring(err)))
  file:write(bytes)
  file:close()
end

local function loadImage(path, name)
  local fileData = love.filesystem.newFileData(readAll(path), name .. ".png")
  return love.image.newImageData(fileData)
end

local function ink(image, x, y)
  image:setPixel(x, y, 0, 0, 0, 1)
end

local function fromNiko(source, id)
  local width, height = source:getDimensions()
  assert(width == SIZE and height == SIZE,
    ("%s source must remain native 16x16, got %dx%d"):format(
      id, width, height))
  local output = love.image.newImageData(SIZE, SIZE)
  local marks, mixed = 0, 0
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      local red, green, blue, alpha = source:getPixel(x, y)
      local light = red * 0.2126 + green * 0.7152 + blue * 0.0722
      if alpha >= 0.5 and light >= 0.5 then
        ink(output, x, y)
        marks = marks + 1
      end
      if alpha >= 0.5 and light > 0.01 and light < 0.99 then
        mixed = mixed + 1
      end
    end
  end
  assert(marks > 0, id .. " source has no white icon pixels")
  assert(mixed == 0, id .. " source is no longer strictly one-bit")
  return output
end

local function partyFrame()
  assert(#PARTY == SIZE, "party pattern must contain sixteen rows")
  local output = love.image.newImageData(SIZE, SIZE)
  for y, row in ipairs(PARTY) do
    assert(#row == SIZE, ("party row %d must be sixteen pixels"):format(y))
    for x = 1, SIZE do
      if row:sub(x, x) == "#" then ink(output, x - 1, y - 1) end
    end
  end
  return output
end

local function bounds(image)
  local left, top, right, bottom = SIZE, SIZE, -1, -1
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      local red, green, blue, alpha = image:getPixel(x, y)
      assert(alpha == 0 or alpha == 1, "atlas transparency must stay binary")
      if alpha == 1 then
        assert(red == 0 and green == 0 and blue == 0,
          "atlas icon pixels must use one opaque ink shade")
        left, top = math.min(left, x), math.min(top, y)
        right, bottom = math.max(right, x), math.max(bottom, y)
      end
    end
  end
  assert(right >= left and bottom >= top, "native frame has no visible pixels")
  return left, top, right, bottom
end

local function encode(image)
  return image:encode("png"):getString()
end

function love.load()
  local root = assert(os.getenv("POKEPORT_ICON_ROOT"),
    "set POKEPORT_ICON_ROOT to the repository's absolute path")
  local sourceDir = join(root, "art/modern_start_menu_ui/nikoichu/source")
  local nativeDir = join(root, "art/modern_start_menu_ui/nikoichu/native")
  local atlasPath = join(root,
    "mods/modern_start_menu_ui/assets/start_menu_icons.png")
  local atlas = love.image.newImageData(#ICONS * SIZE, SIZE)

  for index, id in ipairs(ICONS) do
    local frame
    if id == "party" then
      frame = partyFrame()
    else
      local sourceName = assert(NIKO_SOURCE[id], "no source for " .. id)
      frame = fromNiko(loadImage(join(sourceDir, sourceName), id), id)
    end
    local left, top, right, bottom = bounds(frame)
    atlas:paste(frame, (index - 1) * SIZE, 0, 0, 0, SIZE, SIZE)
    writeAll(join(nativeDir, id .. ".png"), encode(frame))
    print(("%-8s native=16x16 bounds=%d,%d-%d,%d"):format(
      id, left, top, right, bottom))
  end

  writeAll(atlasPath, encode(atlas))
  print("atlas    " .. atlasPath)
  love.event.quit(0)
end
