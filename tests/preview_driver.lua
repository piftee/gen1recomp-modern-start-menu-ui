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
    out[#out + 1] = { label = "DEXNAV SUPER LONG LABEL", shortLabel = "NAV",
      onSelect = function() end }
    out[#out + 1] = { label = "QUEST LOG", shortLabel = "QUEST",
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
end
