return function(mod, icons)
  local Font = require("src.render.Font")
  local Sound = require("src.core.Sound")
  local paletteOK, PaletteFX = pcall(require, "src.render.PaletteFX")
  if not paletteOK then PaletteFX = nil end
  local touchOK, TouchControls = pcall(require, "src.core.TouchControls")
  if not touchOK then TouchControls = nil end

  local Presentation = {}
  local SCREEN_W, SCREEN_H = 160, 144
  local PORTRAIT_MIN_H, PORTRAIT_MAX_H = 224, 400
  local PANEL_MARGIN, PANEL_W, PANEL_H = 4, 104, 136
  local CELL_W, CELL_H, COL_STEP, ROW_STEP = 30, 30, 32, 32
  local PAGE_SIZE, COLUMNS = 9, 3
  local ICON_OFFSET_X, ICON_OFFSET_Y = 7, 2
  local iconAtlas, iconQuads, iconLoadFailed

  local WHITE, LIGHT, DARK, INK = 1, 0.82, 0.34, 0
  -- Each authored palette keeps paper, accent, body and ink far enough apart
  -- to survive the engine's four-shade post-pass. MAP intentionally has no
  -- palette: it inherits the current location, preserving combinations such
  -- as the lime/cyan route colours seen on a phone.
  local THEME_PALETTES = {
    red = {
      { 255, 247, 232 }, { 255, 154, 126 },
      { 196, 55, 70 }, { 34, 23, 28 },
    },
    blue = {
      { 244, 251, 255 }, { 113, 204, 246 },
      { 43, 116, 181 }, { 13, 34, 50 },
    },
    dmg = {
      { 224, 248, 208 }, { 136, 192, 112 },
      { 52, 104, 86 }, { 8, 24, 32 },
    },
  }
  local VALID_THEMES = { map = true, red = true, blue = true, dmg = true }
  local BUILTIN_IDS = {
    pokedex = true, party = true, bag = true, trainer = true, save = true,
    options = true, link = true, mods = true, quit = true,
  }
  local LABEL_IDS = {
    ["POKéDEX"] = "pokedex", ["POKEDEX"] = "pokedex",
    ["POKéMON"] = "party", ["POKEMON"] = "party",
    ITEM = "bag", BAG = "bag", SAVE = "save", OPTION = "options",
    OPTIONS = "options", LINK = "link", MODS = "mods", QUIT = "quit",
    TRAINER = "trainer", PLAYER = "trainer",
  }
  local LEGACY_SHORT_LABELS = {
    pokedex = "DEX", party = "PKMN", bag = "BAG", trainer = "ID",
    save = "SAVE", options = "OPT", link = "LINK", mods = "MODS",
    quit = "QUIT",
  }

  -- A native 3x5 caption face. The game's active font is retained as the
  -- selected-label fallback for scripts this alphabet cannot represent, but
  -- it cannot fit inside a 30px app tile. Keeping the compact alphabet as
  -- pixel rows makes captions equally crisp on every LÖVE target.
  local MINI = {
    A={"010","101","111","101","101"}, B={"110","101","110","101","110"},
    C={"011","100","100","100","011"}, D={"110","101","101","101","110"},
    E={"111","100","110","100","111"}, F={"111","100","110","100","100"},
    G={"011","100","101","101","011"}, H={"101","101","111","101","101"},
    I={"111","010","010","010","111"}, J={"001","001","001","101","010"},
    K={"101","101","110","101","101"}, L={"100","100","100","100","111"},
    M={"101","111","111","101","101"}, N={"101","111","111","111","101"},
    O={"010","101","101","101","010"}, P={"110","101","110","100","100"},
    Q={"010","101","101","111","011"}, R={"110","101","110","101","101"},
    S={"011","100","010","001","110"}, T={"111","010","010","010","010"},
    U={"101","101","101","101","111"}, V={"101","101","101","101","010"},
    W={"101","101","111","111","101"}, X={"101","101","010","101","101"},
    Y={"101","101","010","010","010"}, Z={"111","001","010","100","111"},
    ["0"]={"111","101","101","101","111"}, ["1"]={"010","110","010","010","111"},
    ["2"]={"110","001","010","100","111"}, ["3"]={"110","001","010","001","110"},
    ["4"]={"101","101","111","001","001"}, ["5"]={"111","100","110","001","110"},
    ["6"]={"011","100","110","101","010"}, ["7"]={"111","001","010","010","010"},
    ["8"]={"010","101","010","101","010"}, ["9"]={"010","101","011","001","110"},
    [":"]={"000","010","000","010","000"}, ["/"]={"001","001","010","100","100"},
    ["."]={"000","000","000","000","010"}, ["-"]={"000","000","111","000","000"},
    ["?"]={"110","001","010","000","010"}, [" "]={"000","000","000","000","000"},
  }

  local function gray(value, alpha)
    love.graphics.setColor(value, value, value, alpha or 1)
  end

  local function fill(x, y, w, h, shade)
    gray(shade)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y),
      math.floor(w), math.floor(h))
  end

  local function miniText(text)
    text = tostring(text or "")
    text = text:gsub("é", "E"):gsub("è", "E"):gsub("ê", "E")
      :gsub("á", "A"):gsub("à", "A"):gsub("â", "A")
      :gsub("í", "I"):gsub("ó", "O"):gsub("ú", "U")
      :gsub("É", "E"):gsub("È", "E"):gsub("Ê", "E")
      :gsub("Á", "A"):gsub("À", "A"):gsub("Â", "A")
      :gsub("Í", "I"):gsub("Ó", "O"):gsub("Ú", "U")
    text = text:upper()
    return (text:gsub("[^A-Z0-9:/%.%-%? ]", "?"))
  end

  local function smallWidth(text)
    local normalized = miniText(text)
    return math.max(0, #normalized * 4 - 1)
  end

  local function drawSmall(text, x, y, shade)
    local normalized = miniText(text)
    x, y = math.floor(x), math.floor(y)
    for index = 1, #normalized do
      local glyph = MINI[normalized:sub(index, index)] or MINI["?"]
      for row = 1, 5 do
        for col = 1, 3 do
          if glyph[row]:sub(col, col) == "1" then
            fill(x + (index - 1) * 4 + col - 1, y + row - 1, 1, 1,
              shade == nil and INK or shade)
          end
        end
      end
    end
    return smallWidth(normalized)
  end

  local function fitSmall(text, width)
    text = miniText(text)
    if smallWidth(text) <= width then return text end
    for count = #text - 1, 1, -1 do
      local candidate = text:sub(1, count) .. "."
      if smallWidth(candidate) <= width then return candidate end
    end
    return "."
  end

  local function centerSmall(text, x, y, width, shade)
    text = fitSmall(text, width)
    drawSmall(text, x + math.max(0, (width - smallWidth(text)) / 2), y, shade)
  end

  local function normalizedId(item, game)
    local id = type(item) == "table" and item.id or nil
    if type(id) == "string" and BUILTIN_IDS[id] then return id end
    local label = type(item) == "table" and tostring(item.label or "") or ""
    local upper = label:upper()
    local known = LABEL_IDS[upper]
    if known then return known end
    -- API 2 phone builds predate stable START-menu item ids. Their trainer
    -- row is labelled only with the current player name, so recognize that
    -- authoritative value before falling back to a third-party monogram.
    local player = game and game.save and game.save.player
    local playerName = player and tostring(player.name or "") or ""
    if playerName ~= "" and upper == playerName:upper() then return "trainer" end
    return "generic"
  end

  local function loadIconAtlas()
    if iconAtlas and iconQuads then return true end
    if iconLoadFailed then return false end
    local ok, atlas = pcall(function()
      return mod.assets:image(icons.asset)
    end)
    if not ok or not atlas then
      iconLoadFailed = true
      if mod.log and mod.log.error then
        mod.log:error("could not load %s: %s", tostring(icons.asset),
          tostring(atlas))
      end
      return false
    end

    local size = icons.size or 16
    local width, height = atlas:getDimensions()
    if height < size then
      iconLoadFailed = true
      if mod.log and mod.log.error then
        mod.log:error("%s is too small (%dx%d)", tostring(icons.asset),
          width, height)
      end
      return false
    end
    if atlas.setFilter then atlas:setFilter("nearest", "nearest") end
    local quads = {}
    for id, frame in pairs(icons.frames or {}) do
      local sourceX = frame * size
      if sourceX + size <= width then
        quads[id] = love.graphics.newQuad(sourceX, 0, size, size,
          width, height)
      end
    end
    iconAtlas, iconQuads = atlas, quads
    return true
  end

  local function drawIcon(id, x, y, label)
    local loaded = loadIconAtlas()
    local quad = loaded and (iconQuads[id] or iconQuads.generic) or nil
    if quad then
      gray(WHITE)
      love.graphics.draw(iconAtlas, quad, math.floor(x), math.floor(y))
    else
      -- A corrupt or missing atlas must never make the START menu unusable.
      -- This intentionally plain frame is a last-resort diagnostic, not the
      -- production art path.
      fill(x + 1, y + 1, 14, 14, INK)
      fill(x + 2, y + 2, 12, 12, WHITE)
    end
  end

  local function itemLabel(item)
    if type(item) ~= "table" then return "UNKNOWN" end
    return tostring(item.label or item.id or "UNKNOWN")
  end

  local function tileLabel(item, id)
    if type(item) == "table" and type(item.shortLabel) == "string"
        and item.shortLabel ~= "" then
      return item.shortLabel
    end
    if LEGACY_SHORT_LABELS[id] then return LEGACY_SHORT_LABELS[id] end
    return itemLabel(item)
  end

  local function displayPixels()
    local width, height
    if love.graphics.getPixelDimensions then
      width, height = love.graphics.getPixelDimensions()
    else
      width, height = love.graphics.getDimensions()
    end
    return tonumber(width) or SCREEN_W, tonumber(height) or SCREEN_H
  end

  local function faithfulRatioEnabled(menu)
    local options = menu and menu.game and menu.game.save
      and menu.game.save.options
    return (tonumber(options and options.faithfulRes) or 0) > 0
  end

  local function responsiveSize(menu)
    if faithfulRatioEnabled(menu) then return SCREEN_W, SCREEN_H end
    local pixelWidth, pixelHeight = displayPixels()
    if pixelHeight > pixelWidth then
      local scale = math.max(1, math.floor(pixelWidth / SCREEN_W))
      local height = math.min(PORTRAIT_MAX_H,
        math.floor(pixelHeight / scale))
      if height >= PORTRAIT_MIN_H then return SCREEN_W, height end
    end
    return SCREEN_W, SCREEN_H
  end

  local function uiSize(menu)
    return responsiveSize(menu)
  end

  local function portraitControlsTop(pixelWidth, pixelHeight)
    if not TouchControls or pixelHeight <= pixelWidth then return nil end
    local okVisible, visible = pcall(TouchControls.visible, TouchControls)
    if not okVisible or not visible then return nil end
    local okLayout, controls = pcall(TouchControls.layout, TouchControls)
    if not okLayout or type(controls) ~= "table" then return nil end
    local _, unitHeight = love.graphics.getDimensions()
    unitHeight = tonumber(unitHeight) or pixelHeight
    if unitHeight <= 0 then return nil end
    local dpiY = pixelHeight / unitHeight
    local top
    for _, name in ipairs({ "dpad", "a", "b", "start", "select" }) do
      local zone = controls[name]
      if type(zone) == "table" and tonumber(zone.cy) and tonumber(zone.w) then
        local y = (zone.cy - zone.w * 0.58) * dpiY
        top = top and math.min(top, y) or y
      end
    end
    return top and math.max(SCREEN_H, math.floor(top)) or nil
  end

  local function layoutFor(menu)
    local width, height = responsiveSize(menu)
    local renderer = menu and menu.game and menu.game.renderer
    if not faithfulRatioEnabled(menu) and renderer and renderer.uiSize then
      local ok, rendererWidth, rendererHeight = pcall(renderer.uiSize, renderer)
      if ok then
        width = tonumber(rendererWidth) or width
        height = tonumber(rendererHeight) or height
      end
    end
    width = math.max(SCREEN_W, math.floor(width))
    height = math.max(SCREEN_H, math.floor(height))

    local availableHeight = height
    local pixelWidth, pixelHeight = displayPixels()
    local controlsTop = portraitControlsTop(pixelWidth, pixelHeight)
    if controlsTop and height >= PORTRAIT_MIN_H then
      local scale = math.max(1, math.floor(math.min(
        pixelWidth / width, pixelHeight / height)))
      local offsetY = math.max(0,
        math.floor((pixelHeight - height * scale) / 2))
      local usable = math.floor((controlsTop - offsetY) / scale)
      if usable >= PANEL_H + PANEL_MARGIN * 2 then
        availableHeight = math.min(height, usable)
      end
    end

    local panelX = width - PANEL_MARGIN - PANEL_W
    local panelY = PANEL_MARGIN
    if height >= PORTRAIT_MIN_H then
      panelY = math.floor((availableHeight - PANEL_H) / 2)
      panelY = math.max(PANEL_MARGIN,
        math.min(height - PANEL_H - PANEL_MARGIN, panelY))
    end
    return {
      width = width,
      height = height,
      panelX = panelX,
      panelY = panelY,
      panelW = PANEL_W,
      panelH = PANEL_H,
      gridX = panelX + 4,
      gridY = panelY + 22,
      availableHeight = availableHeight,
    }
  end

  local function selectedTheme()
    local options = mod and mod.options
    if not (options and type(options.get) == "function") then return "map" end
    local ok, value = pcall(options.get, options, "theme")
    if ok and VALID_THEMES[value] then return value end
    return "map"
  end

  local function applyPanelTheme(zones, layout)
    local colors = THEME_PALETTES[selectedTheme()]
    if not colors then return zones end
    zones = zones or {}
    -- Renderer applies later zones on top and moves their scissors with the
    -- top-right anchor, so this recolours exactly the phone shell wherever it
    -- is docked without tinting the overworld beneath it.
    zones[#zones + 1] = {
      colors = colors,
      x = layout.panelX, y = layout.panelY,
      w = layout.panelW, h = layout.panelH,
    }
    return zones
  end

  -- Overworld SGB zones describe the original 160x144 UI surface. A portrait
  -- START menu deliberately extends that transparent surface, so inherit the
  -- map palette and extend its full-screen base zone; otherwise the renderer's
  -- palette scissors would clip the lower rows at native y=144.
  local function sgbPalettes(menu, game)
    local layout = layoutFor(menu)
    local states = game and game.stack and game.stack.states or {}
    local menuIndex
    for index = #states, 1, -1 do
      if states[index] == menu then
        menuIndex = index
        break
      end
    end
    if menuIndex then
      for index = menuIndex - 1, 1, -1 do
        local state = states[index]
        if state and type(state.sgbPalettes) == "function" then
          local ok, zones = pcall(state.sgbPalettes, state, game)
          if ok and type(zones) == "table" and zones[1] then
            local inherited = {}
            for zoneIndex, zone in ipairs(zones) do
              local copy = {}
              for key, value in pairs(zone) do copy[key] = value end
              inherited[zoneIndex] = copy
            end
            local base = inherited[1]
            if (tonumber(base.x) or 0) == 0 and (tonumber(base.y) or 0) == 0 then
              base.w = math.max(tonumber(base.w) or 0, layout.width)
              base.h = math.max(tonumber(base.h) or 0, layout.height)
            end
            return applyPanelTheme(inherited, layout)
          end
        end
      end
    end
    if PaletteFX and game and game.data then
      local colors = PaletteFX.pal(game.data, "MEWMON")
      if colors then
        return applyPanelTheme({ { colors = colors, x = 0, y = 0,
          w = layout.width, h = layout.height } }, layout)
      end
    end
    return applyPanelTheme(nil, layout)
  end

  local function drawShell(menu, layout)
    local panelX, panelY = layout.panelX, layout.panelY
    fill(panelX, panelY, PANEL_W, PANEL_H, INK)
    fill(panelX + 2, panelY + 1, PANEL_W - 4, PANEL_H - 2, DARK)
    fill(panelX + 4, panelY + 4, PANEL_W - 8, PANEL_H - 8, WHITE)

    -- Earpiece and compact status line: play time on the left, page on right.
    fill(panelX + 39, panelY + 3, 26, 3, INK)
    fill(panelX + 42, panelY + 3, 20, 1, LIGHT)
    local seconds = math.max(0, math.floor(menu.game.save.playTime or 0))
    local time = ("%d:%02d"):format(math.floor(seconds / 3600),
      math.floor(seconds / 60) % 60)
    drawSmall(time, panelX + 7, panelY + 9, INK)
    local count = #menu.items
    local pages = math.max(1, math.ceil(count / PAGE_SIZE))
    local page = count > 0 and math.floor((menu.index - 1) / PAGE_SIZE) + 1 or 1
    local pageText = ("%d/%d"):format(page, pages)
    drawSmall(pageText, panelX + PANEL_W - 7 - smallWidth(pageText),
      panelY + 9, INK)
    fill(panelX + 4, panelY + 18, PANEL_W - 8, 1, INK)
  end

  local function drawTiles(menu, layout)
    local count = #menu.items
    if count == 0 then
      centerSmall("NO MENU ITEMS", layout.panelX + 8,
        layout.panelY + 64, PANEL_W - 16, INK)
      return
    end
    local pageStart = math.floor((menu.index - 1) / PAGE_SIZE) * PAGE_SIZE + 1
    for slot = 1, PAGE_SIZE do
      local itemIndex = pageStart + slot - 1
      local item = menu.items[itemIndex]
      if not item then break end
      local col, row = (slot - 1) % COLUMNS, math.floor((slot - 1) / COLUMNS)
      local x, y = layout.gridX + col * COL_STEP,
        layout.gridY + row * ROW_STEP
      local selected = itemIndex == menu.index
      if selected then
        fill(x - 1, y - 1, CELL_W + 2, CELL_H + 2, INK)
        fill(x + 1, y + 1, CELL_W - 2, CELL_H - 2, WHITE)
        fill(x + 11, y - 3, 8, 2, INK)
      else
        fill(x, y, CELL_W, CELL_H, LIGHT)
        fill(x + 1, y + 1, CELL_W - 2, CELL_H - 2, WHITE)
      end
      local id = normalizedId(item, menu.game)
      drawIcon(id, x + ICON_OFFSET_X, y + ICON_OFFSET_Y, itemLabel(item))
      centerSmall(tileLabel(item, id), x + 2, y + 21, CELL_W - 4, INK)
    end
  end

  local function drawFooter(menu, layout)
    local panelX, panelY = layout.panelX, layout.panelY
    fill(panelX + 4, panelY + 118, PANEL_W - 8, 1, INK)
    if #menu.items == 0 then return end
    local label = itemLabel(menu.items[menu.index])
    local x, y, width = panelX + 8, panelY + 124, PANEL_W - 16
    -- The mini alphabet covers Latin captions. For other scripts, retain the
    -- game's active font/charmap so a localization mod's real glyphs appear
    -- instead of turning its selected label into question marks.
    local native = miniText(label):find("?", 1, true) ~= nil
    local textWidth = native and Font.width(label) or smallWidth(label)
    local function drawLabel(at)
      if native then
        gray(INK)
        Font.draw(label, math.floor(at), y - 1)
      else
        drawSmall(label, math.floor(at), y + 1, INK)
      end
    end
    if textWidth <= width then
      drawLabel(x + (width - textWidth) / 2)
      return
    end
    -- Long localized or third-party labels pass through the footer in full;
    -- tile captions stay compact, but the authoritative label is never lost.
    local gap = 18
    local travel = textWidth + gap
    -- Show the beginning immediately, pause long enough to read it, then
    -- loop two copies so the footer never becomes an unexplained blank.
    local elapsed = math.max(0, (menu.modernStartElapsed or 0) - 1)
    local offset = (elapsed * 14) % travel
    if love.graphics.setScissor then love.graphics.setScissor(x, y - 1, width, 10) end
    drawLabel(x - offset)
    drawLabel(x - offset + travel)
    if love.graphics.setScissor then love.graphics.setScissor() end
  end

  local function drawSafari(menu, layout)
    local game, ow = menu.game, menu.game.overworld
    if not (game.save.safari and ow and ow.map and ow.inSafariStepZone
        and ow:inSafariStepZone()) then return end
    local safari = game.save.safari
    fill(0, 0, layout.panelX, 17, INK)
    fill(1, 1, layout.panelX - 2, 15, WHITE)
    local steps = math.max(0, math.floor(safari.steps or 0))
    local balls = math.max(0, math.floor(safari.balls or 0))
    centerSmall(("STEP %d/500"):format(steps), 2, 2,
      layout.panelX - 4, INK)
    centerSmall(("BALL %d"):format(balls), 2, 9,
      layout.panelX - 4, INK)
  end

  local function move(menu, delta)
    local count = #menu.items
    if count == 0 then return end
    local index = ((menu.index - 1 + delta) % count) + 1
    if index ~= menu.index then
      menu.index = index
      menu.modernStartElapsed = 0
    end
    menu.scroll = math.floor((menu.index - 1) / PAGE_SIZE) * PAGE_SIZE
  end

  local function update(menu, dt)
    menu.modernStartElapsed = (menu.modernStartElapsed or 0) + (dt or 0)
    local input = menu.game.input
    if input:wasPressed("left") then
      move(menu, -1)
    elseif input:wasPressed("right") then
      move(menu, 1)
    elseif input:wasPressed("up") then
      move(menu, -COLUMNS)
    elseif input:wasPressed("down") then
      move(menu, COLUMNS)
    elseif input:wasPressed("a") and #menu.items > 0 then
      if not menu.noSound then Sound.play(menu.game.data, "Press_AB") end
      local item = menu.items[menu.index]
      if not item.keepOpen then menu.game.stack:pop() end
      if type(item.onSelect) == "function" then item.onSelect() end
    elseif menu.cancelable and (input:wasPressed("b")
        or (menu.startCloses and input:wasPressed("start"))) then
      if input:wasPressed("b") and not menu.noSound then
        Sound.play(menu.game.data, "Press_AB")
      end
      menu.game.stack:pop()
      if menu.onCancel then menu.onCancel() end
    end
    if menu.game.save then
      menu.game.save.startMenuIndex = math.max(1, menu.index or 1)
    end
  end

  local function draw(menu)
    local renderer = menu.game and menu.game.renderer
    local layout = layoutFor(menu)
    -- A tall responsive surface covers the physical play area, so its centred
    -- panel can still dock horizontally against the right edge. Compact
    -- 144px surfaces—including Faithful Ratio—are already centred by the
    -- renderer; top-right docking those would discard the vertical letterbox
    -- position and pin the phone to the physical top of a tall display.
    if renderer and renderer.setUIAnchor
        and layout.height >= PORTRAIT_MIN_H then
      renderer:setUIAnchor(layout.panelX, layout.panelY,
        PANEL_W, PANEL_H, "topright")
    end
    -- Dynamic UI normally follows the overworld's survey zoom. That is a
    -- useful default for classic screen furniture, but it makes this
    -- already-compact panel half-size when a Pocket Taco / controller
    -- overlay is paired with a zoomed-out map. Give Renderer:endFrame one
    -- FIT-scale answer while leaving Dynamic UI itself enabled. The wrapper
    -- removes itself before render.compose / render.hud mods run; the map
    -- keeps its own zoom and the phone keeps the middle alignment above.
    if renderer and renderer.worldActive and renderer.uiCentered ~= true
        and not renderer.modernStartMenuScaleHold
        and type(renderer.uiScale) == "function"
        and type(renderer.fitScale) == "function" then
      local originalUIScale = renderer.uiScale
      local readableScale = renderer:fitScale()
      renderer.modernStartMenuScaleHold = true
      renderer.uiScale = function(active)
        active.uiScale = originalUIScale
        active.modernStartMenuScaleHold = nil
        return readableScale
      end
    end
    love.graphics.push("all")
    drawShell(menu, layout)
    drawTiles(menu, layout)
    drawFooter(menu, layout)
    drawSafari(menu, layout)
    love.graphics.pop()
  end

  function Presentation.decorate(menu, game)
    if menu.modernStartMenuUI then return menu end
    menu.game = game or menu.game
    menu.classicStartMenuUpdate = menu.update
    menu.classicStartMenuDraw = menu.draw
    menu.classicStartMenuUISize = menu.uiSize
    menu.classicStartMenuSGBPalettes = menu.sgbPalettes
    menu.modernStartMenuUI = true
    menu.modernStartElapsed = 0
    menu.update = update
    menu.draw = draw
    menu.uiSize = uiSize
    menu.sgbPalettes = sgbPalettes
    if #menu.items > 0 then
      menu.index = math.max(1, math.min(menu.index or 1, #menu.items))
      menu.scroll = math.floor((menu.index - 1) / PAGE_SIZE) * PAGE_SIZE
    else
      menu.index, menu.scroll = 0, 0
    end
    return menu
  end

  Presentation.PAGE_SIZE = PAGE_SIZE
  Presentation.PANEL_X = SCREEN_W - PANEL_MARGIN - PANEL_W
  Presentation.PANEL_W = PANEL_W
  Presentation.PANEL_H = PANEL_H
  Presentation.iconOffsetY = ICON_OFFSET_Y
  Presentation.iconFor = normalizedId
  Presentation.tileLabelFor = tileLabel
  Presentation.layoutFor = layoutFor
  Presentation.uiSize = uiSize
  Presentation.sgbPalettes = sgbPalettes
  Presentation.themeFor = selectedTheme
  Presentation.themePalettes = THEME_PALETTES
  Presentation.iconAsset = icons.asset
  Presentation.iconPaletteSize = icons.paletteSize
  return Presentation
end
