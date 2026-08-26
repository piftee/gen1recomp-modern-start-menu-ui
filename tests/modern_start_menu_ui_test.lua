-- Standalone: luajit mods/modern_start_menu_ui/tests/modern_start_menu_ui_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Font = require("src.render.Font")
local Runtime = require("src.mods.Runtime")
local StateStack = require("src.core.StateStack")
local StartMenu = require("src.ui.StartMenu")
local Strings = require("src.core.Strings")

local data = T.fixtures.fresh()
Font.load(data)
local run = T.sdk.loadMods({ "mods/modern_start_menu_ui" }, {
  data = data, dev = true,
})
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
Strings.load(run.data)

local schema = run.loader.optionSchemas.modern_start_menu_ui or {}
T.eq(#schema, 1, "registers one phone presentation setting")
T.eq(schema[1].key, "theme", "the theme setting has a stable saved key")
T.eq(schema[1].default, "map",
  "existing installs keep the location-reactive palette")
T.eq(#schema[1].choices, 4, "four deliberate phone themes are available")
T.eq(schema[1].choices[4][2], "dmg",
  "the theme list includes the classic DMG treatment")

do
  local optionGame = {
    data = run.data,
    save = { options = {} },
    mods = run.loader,
  }
  local optionRows = Runtime.call("ui.options.rows",
    function(_, rows) return rows end,
    optionGame, { { id = "text_speed" } })
  T.eq(#optionRows, 2,
    "one theme row is added to the regular Options menu")
  T.eq(optionRows[2].id, "modern_start_menu_ui_theme",
    "the phone theme follows the game's own option rows")
  T.eq(optionRows[2].value(optionGame), "MAP",
    "the in-game row reports the reactive default")
  optionRows[2].step(optionGame, 1)
  T.eq(run.loader.modOptions.modern_start_menu_ui.theme, "red",
    "the in-game row changes the live phone theme")
  T.eq(optionGame.save.options.modOptions.modern_start_menu_ui.theme, "red",
    "the in-game row persists its theme choice")
  optionRows[2].step(optionGame, -1)
end

-- API 2 mobile builds can lack ui.start_menu.presentation while still
-- providing the screen lifecycle events. Exercise that exact fallback with
-- an undecorated, engine-shaped StartMenu controller.
local legacyMenu = {
  screenId = "StartMenu",
  items = {
    { label = "ITEM", onSelect = function() end },
    { label = "CACHE", onSelect = function() end },
  },
  index = 1,
  scroll = 0,
  update = function() end,
  draw = function() end,
}
legacyMenu.game = {
  save = { playTime = 0 },
  input = { wasPressed = function() return false end },
}
local legacyStack = setmetatable({}, { __index = StateStack })
legacyStack:init()
legacyMenu.game.stack = legacyStack
legacyStack:push(legacyMenu)
T.check(legacyMenu.modernStartMenuUI == true,
  "screen.pushed decorates pre-presentation-hook mobile menus")
T.eq(#legacyMenu.items, 2,
  "the mobile fallback preserves every engine and third-party row")

local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end

local input = { pressed = {} }
function input:wasPressed(key) return self.pressed[key] == true end
local function press(menu, key)
  input.pressed[key] = true
  menu:update(0)
  input.pressed[key] = nil
end

local anchor
local game = {
  data = run.data,
  save = {
    flags = { EVENT_GOT_POKEDEX = true },
    party = { { species = "FIXMON_A" } },
    player = { name = "RED" },
    pokedex = { seen = {}, owned = {} },
    options = {}, playTime = 13 * 3600 + 7 * 60,
  },
  input = input,
  stack = stack,
  modStatus = { available = { { id = "modern_start_menu_ui" } } },
  renderer = {
    uiCentered = false,
    worldActive = true,
    uiScale = function(self)
      return self.uiCentered and 6 or 3
    end,
    fitScale = function() return 6 end,
    setUIAnchor = function(_, x, y, w, h, where)
      anchor = { x, y, w, h, where }
    end,
  },
}

local selected = false
local removeItems = Runtime.hooks:wrap("ui.start_menu.items",
  function(next, game_, items)
    local out = next(game_, items)
    out[#out + 1] = { label = "DEXNAV SUPER LONG LABEL", shortLabel = "NAV",
      onSelect = function() selected = true end }
    out[#out + 1] = { label = "QUESTS", onSelect = function() end }
    out[#out + 1] = { label = "CRAFT", onSelect = function() end }
    out[#out + 1] = { label = "FOLLOW", onSelect = function() end }
    return out
  end, 0, "modern-start-test")

local menu = StartMenu.new(game)
stack:push(menu)
T.check(menu.modernStartMenuUI == true, "the modern presentation is active")
T.eq(#menu.items, 13, "every built-in and third-party action survives")
local expectedIds = {
  "pokedex", "party", "bag", "trainer", "save", "options", "link", "mods", "quit",
}
for index, id in ipairs(expectedIds) do
  T.eq(menu.items[index].id, id, "built-in item " .. index .. " has stable id")
end

press(menu, "right")
T.eq(menu.index, 2, "right moves one tile")
press(menu, "down")
T.eq(menu.index, 5, "down moves one grid row")
press(menu, "up")
T.eq(menu.index, 2, "up returns to the previous row")
press(menu, "left")
T.eq(menu.index, 1, "left moves one tile")
press(menu, "left")
T.eq(menu.index, 13, "navigation wraps across all pages")
T.eq(menu.scroll, 9, "the last item displays on the second page")
T.eq(game.save.startMenuIndex, 13, "the selected tile persists in the save")

menu.index, menu.scroll, menu.noSound = 10, 9, true
press(menu, "a")
T.check(selected, "third-party callback runs unchanged")
T.eq(stack:top(), nil, "selecting a normal tile closes the menu")

menu = StartMenu.new(game)
stack:push(menu)
menu.noSound = true
press(menu, "start")
T.eq(stack:top(), nil, "Start closes the phone panel")

-- Drawing is exercised with the real headless graphics stub. The anchor is
-- the critical integration point that keeps the map visible in Dynamic UI.
menu = StartMenu.new(game)
stack:push(menu)
T.eq(game.renderer:uiScale(), 3,
  "a zoomed-out world would normally reduce Dynamic UI scale")
menu:draw()
T.eq(game.renderer:uiScale(), 6,
  "the modern START panel stays at the readable fit scale over survey zoom")
T.eq(game.renderer:uiScale(), 3,
  "the scale hold restores Dynamic UI immediately after composition")
T.eq(anchor[1], 52, "the panel keeps a native-pixel right margin")
T.eq(anchor[2], 4, "the panel keeps a native-pixel top margin")
T.eq(anchor[3], 104, "the complete phone panel is edge anchored")
T.eq(anchor[4], 136, "the shell ends after its footer instead of filling the screen")
T.eq(anchor[5], "topright", "Dynamic UI docks the panel to the right edge")

local presentation = run.loader.exports.modern_start_menu_ui.presentation
T.eq(presentation.iconFor({ id = "save", label = "ANYTHING" }), "save",
  "stable ids select built-in icons")
T.eq(presentation.iconFor({ label = "RED" }, game), "trainer",
  "legacy player-name rows select the trainer profile icon")
T.eq(presentation.tileLabelFor({ label = "RED" }, "trainer"), "ID",
  "legacy trainer rows receive the compact profile caption")
T.eq(presentation.iconFor({ label = "UNFAMILIAR TOOL" }), "generic",
  "unknown mod rows receive the generic icon")
local iconAtlas = love.graphics.newImage(
  "mods/modern_start_menu_ui/" .. presentation.iconAsset)
local atlasWidth, atlasHeight = iconAtlas:getDimensions()
T.eq(atlasWidth, 160, "the production atlas contains ten native icon frames")
T.eq(atlasHeight, 16, "the production atlas stays at native icon height")
T.eq(presentation.iconPaletteSize, 1,
  "the NikoIchu icon contract uses one opaque ink colour")
T.eq(presentation.iconOffsetY, 2,
  "icons sit one native pixel lower than the original tile position")

-- A portrait phone gets a tall transparent UI surface, then positions the
-- compact panel in the upper usable third above the touch controls. This is
-- the same geometry exercised by the Android screenshot, without depending
-- on a particular device's density.
local graphics = love.graphics
local oldPixelDimensions = graphics.getPixelDimensions
local oldDimensions = graphics.getDimensions
local TouchControls = require("src.core.TouchControls")
local oldTouchVisible, oldTouchLayout = TouchControls.visible,
  TouchControls.layout
graphics.getPixelDimensions = function() return 480, 960 end
graphics.getDimensions = function() return 480, 960 end
TouchControls.visible = function() return true end
TouchControls.layout = function()
  local zone = { cy = 850, w = 160 }
  return { dpad = zone, a = zone, b = zone, start = zone, select = zone }
end
local paletteOwner = {
  sgbPalettes = function()
    return { { colors = {}, x = 0, y = 0, w = 160, h = 144 } }
  end,
}
table.insert(stack.states, 1, paletteOwner)
local portraitW, portraitH = menu:uiSize()
game.renderer.uiSize = function() return portraitW, portraitH end
menu:draw()
local portraitLayout = presentation.layoutFor(menu)
local portraitZones = menu:sgbPalettes(game)
T.eq(portraitW, 160, "portrait mode retains a readable native width")
T.eq(portraitH, 320, "portrait mode uses the available phone height")
T.check(anchor[2] > 4,
  "the portrait phone panel no longer sticks to the top edge")
T.check(anchor[2] + anchor[4] < portraitLayout.availableHeight,
  "the portrait phone panel ends above the visible controls")
T.eq(portraitZones[1].h, portraitH,
  "the inherited palette base covers every portrait menu row")
T.eq(#portraitZones, 1,
  "the MAP theme leaves the inherited location palette untouched")
run.loader.modOptions.modern_start_menu_ui.theme = "red"
local themedZones = menu:sgbPalettes(game)
local phoneZone = themedZones[#themedZones]
T.eq(presentation.themeFor(), "red",
  "the presentation reads theme changes without reopening the game")
T.eq(phoneZone.x, portraitLayout.panelX,
  "a fixed theme begins at the responsive phone position")
T.eq(phoneZone.y, portraitLayout.panelY,
  "a fixed theme follows the phone's portrait anchor")
T.eq(phoneZone.w, portraitLayout.panelW,
  "a fixed theme is clipped to the phone width")
T.eq(phoneZone.h, portraitLayout.panelH,
  "a fixed theme is clipped to the phone height")
T.eq(phoneZone.colors[2][1], 255,
  "the RED theme supplies its authored warm accent")
run.loader.modOptions.modern_start_menu_ui.theme = "map"
table.remove(stack.states, 1)
TouchControls.visible, TouchControls.layout = oldTouchVisible, oldTouchLayout
graphics.getPixelDimensions, graphics.getDimensions = oldPixelDimensions,
  oldDimensions
game.renderer.uiSize = nil

-- A higher-priority presentation that violates the contract must not replace
-- the usable classic controller returned by StartMenu.
local removeBad = Runtime.hooks:wrap("ui.start_menu.presentation",
  function() return false end, 2000, "bad-presentation-test")
local fallback = StartMenu.new(game)
T.check(fallback.modernStartMenuUI ~= true,
  "invalid presentation output falls back to the classic menu")
T.check(type(fallback.update) == "function" and type(fallback.draw) == "function",
  "the fallback remains usable")
removeBad()
removeItems()

T.finish("modern_start_menu_ui")
