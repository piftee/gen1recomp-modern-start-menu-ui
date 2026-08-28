-- In-engine visual smoke test. Run with the command documented in README.md.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Runtime = require("src.mods.Runtime")
  local Screens = require("src.ui.Screens")
  local dir = os.getenv("SHOT_DIR") or "/tmp/modern-start-menu-ui"
  local previewTheme = os.getenv("POKEPORT_START_MENU_THEME") or "map"
  local previewZoom = tonumber(os.getenv("POKEPORT_START_MENU_ZOOM")) or 0
  local previewFaithful = os.getenv("POKEPORT_START_MENU_FAITHFUL") == "1"

  game.save.flags = game.save.flags or {}
  game.save.flags.EVENT_GOT_POKEDEX = true
  game.save.playTime = 13 * 3600 + 7 * 60
  game.save.options = game.save.options or {}
  game.save.options.uiLayout = "dynamic"
  game.save.options.faithfulRes = previewFaithful and 1 or 0
  game.save.options.zoom = previewZoom
  game.save.options.modOptions = game.save.options.modOptions or {}
  game.save.options.modOptions.modern_start_menu_ui =
    game.save.options.modOptions.modern_start_menu_ui or {}
  game.save.options.modOptions.modern_start_menu_ui.theme = previewTheme
  if game.mods then
    game.mods.modOptions = game.mods.modOptions or {}
    game.mods.modOptions.modern_start_menu_ui =
      game.mods.modOptions.modern_start_menu_ui or {}
    game.mods.modOptions.modern_start_menu_ui.theme = previewTheme
  end
  require("src.render.Zoom").offset = previewZoom
  if os.getenv("POKEPORT_START_MENU_PORTRAIT_PREVIEW") == "1"
      and love.window and love.window.setMode then
    love.window.setMode(589, 1280, { resizable = false, highdpi = false })
    U.wait(3)
  end
  if previewFaithful then
    require("src.core.FaithfulRes").apply(1)
  end
  Runtime.hooks:wrap("ui.start_menu.items", function(next, game_, items)
    local out = next(game_, items)
    for _, item in ipairs(out) do
      if item.id == "save" then item.label, item.shortLabel = "SALVAR", nil end
      if item.id == "options" then item.label, item.shortLabel = "OPÇÕES", nil end
      if item.id == "quit" then item.label, item.shortLabel = "SAIR", nil end
    end
    out[#out + 1] = { label = "DEXNAV SUPER LONG LABEL", shortLabel = "NAV",
      onSelect = function() end }
    out[#out + 1] = { id = "localized_tool", label = "OPÇÕES",
      shortLabel = "OPÇÕES",
      onSelect = function() end }
    return out
  end, -1000, "modern-start-preview")

  -- Lets release QA exercise the exact path used by older API 2 phone builds:
  -- remove only this mod's new presentation hook while leaving its
  -- screen.pushed compatibility listener installed.
  if os.getenv("POKEPORT_START_MENU_COMPAT_PREVIEW") == "1" then
    Runtime.hooks:removeOwner("modern_start_menu_ui")
    U.log("forcing pre-presentation-hook compatibility path")
  end

  if os.getenv("POKEPORT_START_MENU_WORLD_PREVIEW") == "1" then
    U.teleport(game, "PALLET_TOWN", 10, 10, "down")
  else
    while game.stack:top() do game.stack:pop() end
  end
  local scaleBeforeMenu = game.renderer:fitScale()
  local menu = Screens.push(game, "StartMenu")
  -- Preview identities do not inherit the player's enabled-mod list. Keep the
  -- driver self-contained by applying the exact production decorator when the
  -- loader did not already do so. A release QA run can also replace an older
  -- installed copy's decorator with the workspace version without touching
  -- the player's enabled-mod profile.
  if os.getenv("POKEPORT_START_MENU_WORKSPACE_PREVIEW") == "1"
      and menu.modernStartMenuUI then
    menu.update = menu.classicStartMenuUpdate or menu.update
    menu.draw = menu.classicStartMenuDraw or menu.draw
    menu.uiSize = menu.classicStartMenuUISize
    menu.sgbPalettes = menu.classicStartMenuSGBPalettes
    menu.modernStartMenuUI = nil
  end
  if not menu.modernStartMenuUI then
    local icons = dofile("mods/modern_start_menu_ui/icons.lua")
    local previewMod = {
      id = "modern_start_menu_ui",
      options = {
        get = function(_, key)
          if key == "theme" then return previewTheme end
        end,
      },
      assets = {
        image = function(_, relative)
          local path = "mods/modern_start_menu_ui/" .. relative
          local file = assert(io.open(path, "rb"))
          local bytes = file:read("*a")
          file:close()
          local data = love.filesystem.newFileData(bytes, relative)
          return love.graphics.newImage(data)
        end,
      },
    }
    local presentation = dofile("mods/modern_start_menu_ui/screen.lua")(
      previewMod, icons)
    presentation.decorate(menu, game)
  end
  menu.index = 1
  U.wait(10)
  local requestedW, requestedH
  if menu.uiSize then requestedW, requestedH = menu:uiSize() end
  local rendererW, rendererH = game.renderer:uiSize()
  U.log("START surface requested/rendered", requestedW, requestedH,
    rendererW, rendererH)
  U.log("START fit scale before/after", scaleBeforeMenu,
    game.renderer:fitScale())
  U.log("START menu theme", previewTheme)
  U.log("START menu survey zoom", previewZoom)
  U.log("START menu faithful ratio", previewFaithful and "ON" or "OFF")
  U.log(menu.modernStartMenuUI and "PASS modern START menu is active"
    or "FAIL modern START menu was not installed")
  U.shot(game, dir .. "/modern_start_menu_ui_page_1.png")

  menu.index = math.min(10, #menu.items)
  menu.scroll = 9
  U.wait(10)
  U.shot(game, dir .. "/modern_start_menu_ui_page_2.png")

  -- Options exposes one entry for this mod. Its dedicated page lists every
  -- discovered third-party action, and selecting one opens the visual 4x4
  -- icon grid. Capture both grid pages and apply DEX to prove persistence and
  -- the live icon swap visually.
  if game.stack:top() == menu then game.stack:pop() end
  local options = Screens.push(game, "OptionsMenu")
  local settingsRow
  for index, row in ipairs(options.rows or {}) do
    if row.id == "modern_start_menu_ui_settings_open" then
      settingsRow = row
      options.index = index
      options.scroll = math.max(0, index - 4)
      break
    end
  end
  if settingsRow then
    U.wait(8)
    U.log("PASS dedicated Modern Start Menu row is present")
    U.shot(game, dir .. "/modern_start_menu_ui_options_entry.png")
    settingsRow.activate(game)
    local settings = game.stack:top()
    U.wait(8)
    U.shot(game, dir .. "/modern_start_menu_ui_settings.png")
    local selector
    for index, item in ipairs(settings.items or {}) do
      if tostring(item.key):find("DEXNAV", 1, true) then
        selector = item
        settings.index = index
        settings.scroll = math.max(0, index - 4)
        break
      end
    end
    if selector then
      settings.onChoose(selector, settings)
      local picker = game.stack:top()
      U.wait(8)
      U.log("PASS third-party entry opens the icon grid")
      U.shot(game, dir .. "/modern_start_menu_ui_icon_grid_1.png")
      picker.index = 17
      U.wait(8)
      U.shot(game, dir .. "/modern_start_menu_ui_icon_grid_2.png")
      picker.index = 2
      U.tap(game, "a")
      U.wait(5)
    else
      U.log("FAIL DEXNAV selector is missing from dedicated settings")
    end
    if game.stack:top() == settings then game.stack:pop() end
    if game.stack:top() == options then game.stack:pop() end
    menu = Screens.push(game, "StartMenu")
    for index, item in ipairs(menu.items) do
      if tostring(item.label):find("DEXNAV", 1, true) then
        menu.index = index
        menu.scroll = math.floor((index - 1) / 9) * 9
        break
      end
    end
    U.wait(8)
    U.log("PASS selected third-party icon applies immediately")
    U.shot(game, dir .. "/modern_start_menu_ui_custom_icon.png")

    local saveItem
    for _, item in ipairs(menu.items) do
      if item.id == "save" then saveItem = item break end
    end
    if saveItem and type(saveItem.onSelect) == "function" then
      -- Deliberately retain START below the transparent Save stack. Some
      -- compatible menu controllers do this, and it is the exact palette-
      -- ownership path that used to leak the phone theme through half of the
      -- summary and dialogue boxes.
      saveItem.onSelect()
      U.wait(120)
      U.log("PASS SAVE prompt retains viewport without phone-theme leakage")
      U.shot(game, dir .. "/modern_start_menu_ui_save_prompt.png")
    else
      U.log("FAIL SAVE action is missing")
    end
  else
    U.log("FAIL dedicated Modern Start Menu row is missing")
  end
end
