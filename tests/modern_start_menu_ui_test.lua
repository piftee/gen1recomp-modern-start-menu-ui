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
T.eq(#schema, 3, "registers theme, placement, and clock settings")
T.eq(schema[1].key, "theme", "the theme setting has a stable saved key")
T.eq(schema[1].default, "map",
  "existing installs keep the location-reactive palette")
T.eq(#schema[1].choices, 4, "four deliberate phone themes are available")
T.eq(schema[1].choices[4][2], "dmg",
  "the theme list includes the classic DMG treatment")
T.eq(schema[2].key, "position",
  "menu placement has a stable saved key")
T.eq(schema[2].default, "right",
  "existing installs retain the intended right-edge placement")
T.eq(#schema[2].choices, 5,
  "placement offers edge, middle, and centred choices")
T.eq(schema[3].key, "clock", "the header clock has a stable saved key")
T.eq(schema[3].default, "play",
  "existing installs keep play time unless the player opts into device time")

do
  local optionStack = { states = {} }
  function optionStack:push(state) self.states[#self.states + 1] = state end
  function optionStack:pop() return table.remove(self.states) end
  function optionStack:top() return self.states[#self.states] end
  local optionWrites = 0
  local optionGame = {
    data = run.data,
    save = { options = {} },
    mods = run.loader,
    stack = optionStack,
    input = {
      wasPressed = function() return false end,
      isDown = function() return false end,
    },
    writeOptions = function() optionWrites = optionWrites + 1 end,
  }
  local optionRows = Runtime.call("ui.options.rows",
    function(_, rows) return rows end,
    optionGame, { { id = "text_speed" } })
  T.eq(#optionRows, 2,
    "one Modern Start Menu row is added to the regular Options menu")
  T.eq(optionRows[2].id, "modern_start_menu_ui_settings_open",
    "all phone preferences sit behind one stable Options row")
  T.eq(optionRows[2].label, "MODERN START MENU",
    "the dedicated page is clearly named in Options")
  T.eq(optionRows[2].value(optionGame), "OPEN",
    "the Options row advertises that it opens a page")
  T.check(optionRows[2].activate(optionGame),
    "the dedicated settings page opens from Options")
  local settingsMenu = optionStack:top()
  T.eq(settingsMenu.screenId, "modern_start_menu_ui:settings",
    "the dedicated settings page has a stable screen id")
  T.eq(settingsMenu.items[1].label, "PHONE THEME",
    "the phone theme is inside the dedicated page")
  T.eq(settingsMenu.items[1].right, "MAP",
    "the dedicated page reports the reactive default")
  T.eq(settingsMenu.items[2].label, "POSITION",
    "horizontal placement is inside the dedicated page")
  T.eq(settingsMenu.items[2].right, "RIGHT",
    "the placement page reports the right-edge default")
  T.eq(settingsMenu.items[3].label, "CLOCK",
    "clock source is inside the dedicated page")
  T.eq(settingsMenu.items[3].right, "PLAY",
    "the clock page reports the compatible play-time default")
  T.eq(settingsMenu.items[4].label, "NO MOD ENTRIES",
    "the empty page explains that START must discover mod entries")
  settingsMenu.onChoose(settingsMenu.items[1], settingsMenu)
  T.eq(run.loader.modOptions.modern_start_menu_ui.theme, "red",
    "the dedicated page changes the live phone theme")
  T.eq(optionGame.save.options.modOptions.modern_start_menu_ui.theme, "red",
    "the dedicated page persists its theme choice")
  T.eq(optionWrites, 1, "submenu changes are written immediately")
  settingsMenu.onChoose(settingsMenu.items[2], settingsMenu)
  T.eq(run.loader.modOptions.modern_start_menu_ui.position, "left",
    "the dedicated page changes the live menu placement")
  settingsMenu.onChoose(settingsMenu.items[3], settingsMenu)
  T.eq(run.loader.modOptions.modern_start_menu_ui.clock, "device",
    "the dedicated page changes the live header clock")
  for _ = 1, 3 do
    settingsMenu.onChoose(settingsMenu.items[1], settingsMenu)
  end
  for _ = 1, 4 do
    settingsMenu.onChoose(settingsMenu.items[2], settingsMenu)
  end
  settingsMenu.onChoose(settingsMenu.items[3], settingsMenu)
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
  mods = run.loader,
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
local optionWrites = 0
game.writeOptions = function() optionWrites = optionWrites + 1 end

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

local classicUpdate = menu.classicStartMenuUpdate
local delegatedSelect = 0
menu.classicStartMenuUpdate = function(_, _)
  if input:wasPressed("select") then delegatedSelect = delegatedSelect + 1 end
end
press(menu, "select")
T.eq(delegatedSelect, 1,
  "unhandled SELECT shortcuts reach the decorated source controller")
menu.classicStartMenuUpdate = classicUpdate

menu.index, menu.scroll, menu.noSound = 10, 9, true
press(menu, "a")
T.check(selected, "third-party callback runs unchanged")
T.eq(stack:top(), nil, "selecting a normal tile closes the menu")

menu = StartMenu.new(game)
stack:push(menu)
T.eq(menu.index, 10,
  "closing and reopening START restores the previously selected tile")
menu.noSound = true
press(menu, "start")
T.eq(stack:top(), nil, "Start closes the phone panel")

-- A compact 160x144 surface is already centred by the renderer. Leaving it
-- unanchored keeps the phone vertically centred in that faithful viewport
-- instead of pinning it to the physical top edge of a tall display.
menu = StartMenu.new(game)
stack:push(menu)
T.eq(game.renderer:uiScale(), 3,
  "a zoomed-out world would normally reduce Dynamic UI scale")
anchor = nil
menu:draw()
T.eq(game.renderer:uiScale(), 6,
  "the modern START panel stays at the readable fit scale over survey zoom")
T.eq(game.renderer:uiScale(), 3,
  "the scale hold restores Dynamic UI immediately after composition")
T.eq(anchor, nil,
  "compact and faithful surfaces retain the renderer's middle alignment")

-- Gen 2 stores play time as a split clock table. Opening START must accept
-- that native save shape instead of passing the table to math.floor.
game.save.playTime = { hours = 12, minutes = 34, seconds = 56, frames = 0 }
local gen2ClockDrawn, gen2ClockError = pcall(menu.draw, menu)
T.check(gen2ClockDrawn,
  "the phone draws a native Gen 2 play-time table without crashing: "
    .. tostring(gen2ClockError))
game.save.playTime = 13 * 3600 + 7 * 60

local presentation = run.loader.exports.modern_start_menu_ui.presentation
T.eq(presentation.clockTextFor(menu), "13:07",
  "the compatible default header still reports elapsed play time")
T.eq(presentation.clockLabelFor(menu), "PLAY 13:07",
  "the elapsed clock identifies itself in the compact phone header")
run.loader.modOptions.modern_start_menu_ui.clock = "device"
T.eq(presentation.clockFor(), "device",
  "the presentation sees the live clock-source preference")
T.eq(presentation.clockTextFor(menu, { hour = 6, min = 42 }), "06:42",
  "device time uses the local 24-hour clock with stable padding")
T.eq(presentation.clockLabelFor(menu, { hour = 6, min = 42, wday = 1 }),
  "SUN 06:42",
  "device time includes the local weekday so it cannot resemble play time")
T.eq(presentation.clockLabelFor(menu, { hour = 6, min = 42 }), "NOW 06:42",
  "a compact source label survives device clocks without weekday metadata")
run.loader.modOptions.modern_start_menu_ui.clock = "play"

T.eq(presentation.positionFor(), "right",
  "the phone defaults to the requested right-side placement")
T.eq(presentation.layoutFor(menu).panelX, 52,
  "right placement keeps the compact phone against its native edge")
run.loader.modOptions.modern_start_menu_ui.position = "center"
T.eq(presentation.layoutFor(menu).panelX, 28,
  "center placement moves only the phone inside the stable surface")
run.loader.modOptions.modern_start_menu_ui.position = "left"
T.eq(presentation.layoutFor(menu).panelX, 4,
  "left placement reaches the opposite native edge")
run.loader.modOptions.modern_start_menu_ui.position = "right"

do
  local gen2Save = { playTime = { hours = 1, minutes = 2 },
    startMenuIndex = 3 }
  local gen2Game = { data = run.data, save = gen2Save, input = input }
  local function gen2Controller()
    local controller = {
      game = gen2Game,
      items = {
        { value = "pokedex", label = "DEX" },
        { value = "pokemon", label = "PKMN" },
        { value = "pack", label = "PACK" },
        { value = "status", label = "PLAYER" },
      },
      list = { index = 1 },
      update = function() end,
      draw = function() end,
      choose = function() end,
      close = function(self) self.closed = true end,
    }
    return presentation.decorate(controller, gen2Game)
  end
  local gen2Menu = gen2Controller()
  T.eq(gen2Menu.index, 3,
    "Gen 2 restores the shared START cursor when the phone opens")
  press(gen2Menu, "right")
  T.eq(gen2Menu.index, 4, "Gen 2 grid navigation still moves normally")
  T.eq(gen2Save.startMenuIndex, 4,
    "Gen 2 writes the selected phone tile before closing")
  press(gen2Menu, "b")
  T.check(gen2Menu.closed, "Gen 2 retains its native close callback")
  T.eq(gen2Controller().index, 4,
    "Gen 2 reopens on its previously selected tile")
end

T.eq(presentation.iconFor({ id = "save", label = "ANYTHING" }), "save",
  "stable ids select built-in icons")
T.eq(presentation.iconFor({ label = "RED" }, game), "trainer",
  "legacy player-name rows select the trainer profile icon")
T.eq(presentation.iconFor({ value = "pokegear", label = "<PO><KE>GEAR" }, game),
  "pokegear", "Gen 2 POKéGEAR is not relabelled as Link")
T.eq(presentation.tileLabelFor({ value = "pokegear", label = "<PO><KE>GEAR" },
  "pokegear"), "GEAR", "the Gen 2 POKéGEAR tile has an honest caption")
T.eq(presentation.tileLabelFor({ label = "RED" }, "trainer"), "ID",
  "legacy trainer rows receive the compact profile caption")
T.eq(presentation.iconFor({ label = "UNFAMILIAR TOOL" }), "generic",
  "unknown mod rows receive the generic icon")
T.eq(presentation.iconFor({ label = "DEX" }), "pokedex",
  "common third-party DEX labels receive a useful automatic icon")
T.eq(presentation.iconFor({ label = "PARTY" }), "party",
  "common third-party PARTY labels receive a useful automatic icon")
T.eq(presentation.iconFor({ label = "OPÇÕES" }), "options",
  "Portuguese option labels are recognized after accent folding")
T.eq(presentation.normalizeText("OPÇÕES"), "OPCOES",
  "Latin accents render as complete compact-font letters")
T.check(presentation.isCustomItem({ id = "another_mod_options", label = "OPÇÕES" }),
  "a recognized label with a third-party id still receives an icon selector")
local iconAtlas = love.graphics.newImage(
  "mods/modern_start_menu_ui/" .. presentation.iconAsset)
local atlasWidth, atlasHeight = iconAtlas:getDimensions()
T.eq(atlasWidth, 512, "the production atlas contains 32 native icon frames")
T.eq(atlasHeight, 16, "the production atlas stays at native icon height")
T.eq(presentation.iconPaletteSize, 1,
  "the NikoIchu icon contract uses one opaque ink colour")
T.eq(presentation.iconOffsetY, 7,
  "icons are vertically centred after redundant tile captions are removed")
T.eq(presentation.tileLabels, false,
  "START buttons rely on the full footer label instead of tiny captions")

-- Opening START while the mobile overlay is active must not replace the
-- native 160x144 UI surface with a tall menu-owned canvas. Keeping the same
-- surface is what guarantees the renderer's fit scale—and therefore both the
-- map and the menu size—cannot change just because START was pressed.
local graphics = love.graphics
local oldPixelDimensions = graphics.getPixelDimensions
local oldDimensions = graphics.getDimensions
local TouchControls = require("src.core.TouchControls")
local oldTouchVisible, oldTouchLayout = TouchControls.visible,
  TouchControls.layout
local oldTouchActive, oldTouchEnabled = TouchControls.active,
  TouchControls.enabled
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
local overlayW, overlayH = menu:uiSize()
game.renderer.uiSize = function() return overlayW, overlayH end
anchor = nil
menu:draw()
local overlayLayout = presentation.layoutFor(menu)
T.eq(overlayW, 160, "the mobile overlay retains the native menu width")
T.eq(overlayH, 144,
  "the mobile overlay cannot introduce a scale-changing tall surface")
T.eq(overlayLayout.height, 144,
  "overlay layout uses the same native surface as the closed menu")
T.eq(anchor, nil,
  "overlay mode stays centred rather than adding a screen-edge anchor")
game.renderer:uiScale() -- consume the one-frame readable-scale hold

-- Physical controllers hide the built-in artwork after their first input,
-- but the configured mobile overlay still reserves the same phone layout.
TouchControls.visible = function() return false end
TouchControls.active, TouchControls.enabled = true, true
T.eq(select(2, menu:uiSize()), 144,
  "a controller-hidden mobile overlay still retains the native surface")

-- With the touch overlay explicitly absent, START still keeps the exact same
-- native surface. This is the screen-position regression guard: opening the
-- menu must not recalculate or recenter the map on a tall display.
TouchControls.active = false
local portraitW, portraitH = menu:uiSize()
game.renderer.uiSize = function() return portraitW, portraitH end
anchor = nil
menu:draw()
local portraitLayout = presentation.layoutFor(menu)
local portraitZones = menu:sgbPalettes(game)
T.eq(portraitW, 160, "portrait mode retains a readable native width")
T.eq(portraitH, 144,
  "opening START cannot replace the game's native render surface")
T.eq(portraitLayout.panelY, 4,
  "the phone remains inside the renderer-owned native viewport")
T.eq(anchor, nil,
  "START does not overwrite centered/top/high screen positioning")
T.eq(portraitZones[1].h, portraitH,
  "the inherited palette base retains the native viewport height")
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
  "a fixed theme follows the phone's native position")
T.eq(phoneZone.w, portraitLayout.panelW,
  "a fixed theme is clipped to the phone width")
T.eq(phoneZone.h, portraitLayout.panelH,
  "a fixed theme is clipped to the phone height")
T.eq(phoneZone.colors[2][1], 255,
  "the RED theme supplies its authored warm accent")

-- Save implementations from compatible menu mods can push their transparent
-- summary and choice boxes without first popping START. Those overlays must
-- inherit only the underlying map palette, never the phone's rectangular
-- fixed-theme zone.
local saveOverlay = { draw = function() end }
stack:push(saveOverlay)
local saveOverlayZones = menu:sgbPalettes(game)
T.eq(#saveOverlayZones, 1,
  "a Save overlay does not inherit the phone-only theme rectangle")
T.eq(saveOverlayZones[1].w, portraitW,
  "a Save overlay retains the normal inherited full-screen palette")
stack:pop()
run.loader.modOptions.modern_start_menu_ui.theme = "map"

-- Faithful Ratio deliberately restores a compact 160x144 canvas even on a
-- portrait phone. It must use that canvas's centred viewport instead of
-- re-applying the ordinary top-right screen-edge anchor.
game.save.options.faithfulRes = 1
anchor = nil
local faithfulW, faithfulH = menu:uiSize()
local faithfulLayout = presentation.layoutFor(menu)
menu:draw()
T.eq(faithfulW, 160, "Faithful Ratio retains the native menu width")
T.eq(faithfulH, 144, "Faithful Ratio retains the native menu height")
T.eq(faithfulLayout.panelY, 4,
  "the phone stays centred inside the faithful viewport")
T.eq(anchor, nil,
  "Faithful Ratio does not pin the phone to the physical top edge")
game.save.options.faithfulRes = 0
table.remove(stack.states, 1)
TouchControls.visible, TouchControls.layout = oldTouchVisible, oldTouchLayout
TouchControls.active, TouchControls.enabled = oldTouchActive, oldTouchEnabled
graphics.getPixelDimensions, graphics.getDimensions = oldPixelDimensions,
  oldDimensions
game.renderer.uiSize = nil

-- Wide desktop placement is a final phone-only pass. Gen 1 previously used
-- only the centred cartridge pass here, which caused the Windows regression
-- where the intended right-edge phone drifted toward the middle.
do
  local oldWidePixels, oldWideDimensions = graphics.getPixelDimensions,
    graphics.getDimensions
  graphics.getPixelDimensions = function() return 1024, 768 end
  graphics.getDimensions = function() return 1024, 768 end
  run.loader.modOptions.modern_start_menu_ui.position = "right"
  run.loader.modOptions.modern_start_menu_ui.theme = "blue"
  local hudOK, hudError = pcall(Runtime.call, "render.hud",
    function() end, game, {
      width = 1024, height = 768, scale = 5, dpiX = 1, dpiY = 1,
    })
  T.check(hudOK,
    "the Gen 1 wide-screen phone pass renders cleanly: " .. tostring(hudError))
  T.eq(menu.modernStartLastWideWidth, 204,
    "the wide phone uses the complete crisp desktop width")
  T.eq(menu.modernStartHudPass, nil,
    "the final-pass marker never leaks into later screens")
  menu.modernStartHudPass = true
  T.eq(presentation.layoutFor(menu).panelX, 96,
    "right placement docks the phone at the wide display edge")
  menu.modernStartHudPass = nil
  run.loader.modOptions.modern_start_menu_ui.theme = "map"
  graphics.getPixelDimensions, graphics.getDimensions = oldWidePixels,
    oldWideDimensions
end

-- Unknown rows discovered through ui.start_menu.items live on the dedicated
-- page and open a visual 4x4 picker. AUTO keeps label/id detection; every
-- other value maps directly to a native atlas frame.
do
  local rows = Runtime.call("ui.options.rows",
    function(_, original) return original end, game, {})
  T.eq(#rows, 1,
    "discovered entries do not clutter the game's main Options list")
  T.eq(rows[1].label, "MODERN START MENU",
    "the main Options list retains one dedicated entry")
  T.check(rows[1].activate(game), "the populated settings page opens")
  local settingsMenu = stack:top()
  T.eq(#settingsMenu.items, 9,
    "three phone preferences, five discovered entries, and Back share one page")
  local selector
  for _, item in ipairs(settingsMenu.items) do
    if item.key == "label:DEXNAV SUPER LONG LABEL" then selector = item break end
  end
  T.check(selector ~= nil, "the DEXNAV entry has its own icon selector")
  T.eq(selector.label, "DEXNAV SUPE.",
    "long third-party labels stay identifiable in the dedicated list")
  T.eq(selector.right, "AUTO",
    "unknown entries preserve automatic icon detection by default")
  settingsMenu.onChoose(selector, settingsMenu)
  local picker = stack:top()
  T.eq(picker.screenId, "modern_start_menu_ui:icon_picker",
    "selecting a mod entry opens the visual icon picker")
  T.eq(#picker.choices, 32,
    "the picker offers two complete pages of useful native icons")
  T.eq(picker.index, 1, "a new entry opens on AUTO")
  press(picker, "right")
  T.eq(picker.index, 2, "right moves through the four-column icon grid")
  press(picker, "down")
  T.eq(picker.index, 6, "down moves one full icon-grid row")
  press(picker, "up")
  T.eq(picker.index, 2, "up returns to the previous icon-grid row")
  press(picker, "a")
  T.eq(stack:top(), settingsMenu,
    "choosing an icon returns to Modern Start Menu settings")
  T.eq(settingsMenu.items[settingsMenu.index].right, "DEX",
    "the settings row refreshes to the chosen icon")
  T.eq(presentation.iconFor(menu.items[10], game), "pokedex",
    "the selected icon is applied immediately to the existing menu item")
  local savedIcons = game.save.options.modOptions.modern_start_menu_ui.icons
  T.eq(savedIcons["label:DEXNAV SUPER LONG LABEL"], "pokedex",
    "the override is persisted under the entry's stable normalized key")
  T.eq(run.loader.modOptions.modern_start_menu_ui.icons
      ["label:DEXNAV SUPER LONG LABEL"], "pokedex",
    "the live loader receives the same override")
  T.eq(optionWrites, 1, "picker selections are written immediately")
  settingsMenu.onChoose(settingsMenu.items[settingsMenu.index], settingsMenu)
  picker = stack:top()
  press(picker, "left")
  press(picker, "a")
  T.eq(presentation.iconFor(menu.items[10], game), "generic",
    "choosing AUTO restores automatic detection")
  T.eq(savedIcons["label:DEXNAV SUPER LONG LABEL"], nil,
    "AUTO removes the saved override cleanly")
  T.eq(optionWrites, 2, "returning to AUTO is persisted immediately")
end

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
