-- StartMenu remains responsible for building actions and every other mod
-- still contributes through ui.start_menu.items before this mod sees the
-- final controller. New engines expose a dedicated presentation hook; the
-- screen.pushed listener below keeps the same archive working on API 2 mobile
-- builds released before that hook existed.
return function(mod)
  local optionSchema = {
    { key = "theme", label = "START MENU THEME", type = "choice",
      default = "map", choices = {
        { "MAP", "map" }, { "RED", "red" },
        { "BLUE", "blue" }, { "DMG", "dmg" },
      } },
  }
  mod.options:define(optionSchema)

  local function setTheme(game, value)
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[mod.id] = options.modOptions[mod.id] or {}
      options.modOptions[mod.id].theme = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[mod.id] = loader.modOptions[mod.id] or {}
      loader.modOptions[mod.id].theme = value
      if loader.events then
        loader.events:emit("mod.options_changed",
          { mod = mod.id, key = "theme", value = value })
      end
    end
  end

  local function themeLabel()
    local current = mod.options:get("theme")
    for _, choice in ipairs(optionSchema[1].choices) do
      if choice[2] == current then return choice[1] end
    end
    return "MAP"
  end

  local function stepTheme(game, direction)
    local choices = optionSchema[1].choices
    local current, index = mod.options:get("theme"), 1
    for i, choice in ipairs(choices) do
      if choice[2] == current then index = i break end
    end
    index = (index - 1 + (direction or 1)) % #choices + 1
    setTheme(game, choices[index][2])
    return true
  end

  -- Keep the theme beside the game's other display choices. The manager's
  -- per-mod settings page reads the same schema, while this row makes the
  -- palette switch reachable directly from the phone's OPTION tile.
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    out[#out + 1] = {
      id = "modern_start_menu_ui_theme",
      label = "PHONE THEME",
      value = themeLabel,
      step = stepTheme,
    }
    return out
  end)

  local function loadModule(filename, label)
    local source, readErr = mod:read(filename)
    if not source then
      mod.log:error("%s is missing (%s); reinstall the mod", filename,
        tostring(readErr or "unknown read error"))
      return nil
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. filename)
    if not chunk then
      mod.log:error("%s did not compile: %s", label, tostring(compileErr))
      return nil
    end
    local ok, value = pcall(chunk)
    if not ok then
      mod.log:error("%s failed to load: %s", label, tostring(value))
      return nil
    end
    return value
  end

  local icons = loadModule("icons.lua", "icon atlas metadata")
  local makePresentation = loadModule("screen.lua", "menu presentation")
  if type(icons) ~= "table" or type(makePresentation) ~= "function" then return end

  local made, presentation = pcall(makePresentation, mod, icons)
  if not made or type(presentation) ~= "table"
      or type(presentation.decorate) ~= "function" then
    mod.log:error("menu presentation factory failed: %s", tostring(presentation))
    return
  end

  local function decorate(menu, game, source)
    if type(menu) ~= "table" or menu.modernStartMenuUI then return menu end
    if type(menu.items) ~= "table" or type(menu.update) ~= "function"
        or type(menu.draw) ~= "function" then
      mod.log:warn("%s found an incompatible StartMenu controller; keeping it unchanged",
        source)
      return menu
    end
    local ok, decorated = pcall(presentation.decorate, menu, game or menu.game)
    if not ok then
      mod.log:error("could not decorate START menu through %s: %s",
        source, tostring(decorated))
      return menu
    end
    return type(decorated) == "table" and decorated or menu
  end

  mod.hooks:wrap("ui.start_menu.presentation",
    function(next, game, menu)
      local downstream = next(game, menu)
      if type(downstream) ~= "table" then return downstream end
      return decorate(downstream, game, "presentation hook")
    end, 1000)

  -- API 2 shipped screen lifecycle events before it shipped the dedicated
  -- ui.start_menu.presentation seam. Screens.push stamps screenId before
  -- screen.pushed fires, so this fallback receives the finished controller,
  -- including rows contributed by third-party mods. Decoration is in-place
  -- and idempotent, making this a no-op on engines that already ran the hook.
  mod.events:on("screen.pushed", function(event)
    local menu = type(event) == "table" and event.state or nil
    if type(menu) ~= "table" or menu.screenId ~= "StartMenu"
        or menu.modernStartMenuUI then return end
    decorate(menu, menu.game, "screen.pushed compatibility fallback")
  end, -1000)

  mod.exports.presentation = presentation
  mod.exports.decorate = decorate
  mod.log:info("phone-panel START menu enabled (mobile compatibility active)")
end
