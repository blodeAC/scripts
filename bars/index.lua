local _imgui = require("imgui")
ImGui = _imgui.ImGui
local views = require("utilitybelt.views")
local io = require("filesystem").GetScript()
local settingsFile = "bar_settings.json"
local bars = require("bars")

---------------------------------------
--- icons
---------------------------------------

local textures = {}

---Get or create a managed texture for a world object
function GetOrCreateTexture(textureId)
  if textures[textureId] == nil then
    local texture ---@type ManagedTexture
    texture = views.Huds.GetIconTexture(textureId)
    textures[textureId] = texture
  end

  return textures[textureId]
end

function DrawIcon(bar, overrideId, size, func)
  if not size then
    size = ImGui.GetContentRegionAvail()
  end
  local bar_position = ImGui.GetCursorScreenPos().X .."-".. ImGui.GetCursorScreenPos().Y

  local texture = overrideId and GetOrCreateTexture(overrideId) or GetOrCreateTexture(bar.settings.icon_hex)
  if not texture then return false end
  
  if overrideId then
    if ImGui.TextureButton("##" .. bar_position .. overrideId, texture, size) then
      func()
    end
  elseif ImGui.TextureButton("##" .. bar_position, GetOrCreateTexture(bar.settings.icon_hex), size) then
    bar:func()
  end
  if ImGui.IsItemClicked(1) and bar.rightclick then
    bar:rightclick()
  end

  local drawlist = ImGui.GetWindowDrawList()
  local rectMin = ImGui.GetItemRectMin()
  local rectMax = ImGui.GetItemRectMax()

  local textSize = ImGui.CalcTextSize(bar.settings.label_str or " ")
  local startText = Vector2.new(
    rectMin.X + (rectMax.X - rectMin.X - textSize.X) / 2,
    rectMin.Y + (rectMax.Y - rectMin.Y - textSize.Y) / 2
  )
  if overrideId and bar.settings.label_str then
    drawlist.AddRectFilled(rectMin, rectMax, 0x88000000)
  end
  -- Draw text in white
  drawlist.AddText(startText, 0xFFFFFFFF, bar.settings.label_str or "")
  return true
end

----------------------------------------
--- Settings Saving/Loading
----------------------------------------

-- Load settings from a JSON file
local function loadSettings()
  local files = io.FileExists(settingsFile)
  if files then
    local content = io.ReadText(settingsFile)
    local settings = json.parse(content)
    if settings and settings[game.ServerName] and settings[game.ServerName][game.Character.Weenie.Name] then
      local characterSettings = settings[game.ServerName][game.Character.Weenie.Name]
      for i, bar in ipairs(bars) do
        if characterSettings[bar.name] then
          for key, value in pairs(characterSettings[bar.name]) do
            if type(value) == "table" and value.position and value.size then
              bar[key] = {}
              bar[key].position = Vector2.new(value.position.X, value.position.Y)
              bar[key].size = Vector2.new(value.size.X, value.size.Y)
            elseif key == "position" then
              bar[key] = Vector2.new(value.X, value.Y)
            elseif key == "size" then
              bar[key] = Vector2.new(value.X, value.Y)
            elseif key == "settings" then
              for nestedKey, nestedVal in pairs(value) do
                bar.settings[nestedKey] = nestedVal
              end
            else
              bar[key] = value
            end
          end
        end
      end
    end
  end
end

-- Function to pretty-print JSON (never omitted again!)
local function prettyPrintJSON(value, indent)
  local function wrapString(value)
    return '"' .. value:gsub('([\\"])', '\\%1'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
  end

  indent = indent or ""
  local indentNext = indent .. "  "
  local items = {}

  if type(value) == "table" then
    local isArray = #value > 0
    for k, v in pairs(value) do
      local formattedKey = isArray and "" or wrapString(k) .. ": "
      table.insert(items, indentNext .. formattedKey .. prettyPrintJSON(v, indentNext))
    end
    if isArray then
      return "[\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "]"
    else
      return "{\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
    end
  elseif type(value) == "string" then
    return wrapString(value)
  else
    return tostring(value)
  end
end

function SaveBarSettings(barSaving, ...)
  local args = table.pack(...)
  if args.n % 2 ~= 0 then
    print("Invalid number of arguments to save. Must be even")
    return
  end

  -- Read existing settings
  local settings = {}
  if io.FileExists(settingsFile) then
    local content = io.ReadText(settingsFile)
    settings = json.parse(content) or {}
  end

  -- Ensure server and character structure exists
  local server = game.ServerName
  local character = game.Character.Weenie.Name

  settings[server] = settings[server] or {}
  settings[server][character] = settings[server][character] or {}
  local charSettings = settings[server][character]

  -- Process arguments
  for i = 1, args.n, 2 do
    local keyPath = args[i]
    local value = args[i + 1]

    if type(keyPath) ~= "string" then
      print("Key must be a string")
      return
    end

    -- Split dot-separated keys
    local parts = {}
    for part in string.gmatch(keyPath, "[^.]+") do
      table.insert(parts, part)
    end

    -- Traverse and update the nested structure
    local current = charSettings[barSaving.name] or {}
    charSettings[barSaving.name] = current

    for j = 1, #parts - 1 do
      local key = parts[j]
      current[key] = current[key] or {}
      current = current[key]
    end

    -- Set the final key
    current[parts[#parts]] = value
  end

  -- Save back to the file
  io.WriteText(settingsFile, prettyPrintJSON(settings))
end

loadSettings()

----------------------------------------
--- ImGui Display Logic: Separate HUDs for Each Progress Bar
----------------------------------------

local function imguiAligner(bar, text, start, size)
  -- Default to current cursor position and content region if not provided
  start = start or ImGui.GetCursorScreenPos() or Vector2.new(0, 0)                                                                               -- Ensure it's not nil
  size = size or ImGui.GetContentRegionAvail()
  local textAlignment = bar.settings.textAlignment_combo and
  bar.settings.textAlignment_combo[bar.settings.textAlignment_combo[1] + 1] or "center"                                                          --+1 for self

  -- Calculate the size of the text to align
  local textSize = ImGui.CalcTextSize(text)
  for _ in string.gmatch(text, "%.") do
    textSize.X = textSize.X - ImGui.GetFontSize() / 2
  end

  -- Calculate the X position to center the text, and ensure it doesn't overflow
  local textX
  if textAlignment == "left" then
    textX = start.X -- Align text to the left
  elseif textAlignment == "center" or textAlignment == nil then
    -- Center the text horizontally, considering the available space
    textX = start.X + (size.X - textSize.X) / 2
    -- Ensure textX doesn't go below the start.X
    textX = math.max(textX, start.X)
  elseif textAlignment == "right" then
    textX = start.X + size.X - textSize.X -- Align text to the right
  end

  -- Calculate the Y position to center the text vertically
  local textY = start.Y + (size.Y - textSize.Y) / 2

  -- Set the cursor to the calculated position
  ImGui.SetCursorScreenPos(Vector2.new(textX, textY))
end

local settingsHud = views.Huds.CreateHud("Bar Settings")

---@type Hud[]
local huds = {}

local hudCreate = function(bar)
  local name = bar.name
  local i
  for j,test in ipairs(bars) do
    if test.name == name then
      i=j
      break
    end
  end

  if bar.settings and bar.settings.icon_hex then
    huds[name] = views.Huds.CreateHud(bar.name, bar.settings.icon_hex)
  else
    huds[name] = views.Huds.CreateHud(bar.name)
  end

  bar.hud = huds[name]

  -- Set HUD properties.
  huds[name].Visible = true
  huds[name].ShowInBar = true

  bar.imguiReset = true
  -- Pre-render setup for each HUD.
  huds[name].OnPreRender.Add(function()
    local zeroVector = Vector2.new(0, 0)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.WindowMinSize, Vector2.new(1, ImGui.GetFontSize()))
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.WindowPadding, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemSpacing, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, zeroVector)

    if bar.imguiReset then
      if bar.renderContext == nil then
        ImGui.SetNextWindowSize(bar.size and bar.size or Vector2.new(100, 100))
        ImGui.SetNextWindowPos(bar.position and bar.position or Vector2.new(100 + (i * 10), (i - 1) * 40))
      else
        ImGui.SetNextWindowSize(bar[bar.renderContext] and bar[bar.renderContext].size or Vector2.new(100, 100))
        ImGui.SetNextWindowPos(bar[bar.renderContext] and bar[bar.renderContext].position or
          Vector2.new(100 + (i * 10), (i - 1) * 40))
      end
      bar.imguiReset = false
    end

    -- Set flags to disable all unnecessary decorations.
    if ImGui.GetIO().KeyCtrl then
      huds[name].WindowSettings =
          _imgui.ImGuiWindowFlags.NoScrollbar +
          _imgui.ImGuiWindowFlags.NoCollapse
    else
      huds[name].WindowSettings =
          _imgui.ImGuiWindowFlags.NoTitleBar +
          _imgui.ImGuiWindowFlags.NoScrollbar + -- Prevent scrollbars explicitly.
          _imgui.ImGuiWindowFlags.NoMove +      -- Prevent moving unless Ctrl is pressed.
          _imgui.ImGuiWindowFlags.NoResize +    -- Prevent resizing unless Ctrl is pressed.
          _imgui.ImGuiWindowFlags.NoCollapse +
          (bar.windowSettings or 0)
    end
  end)

  -- Render directly into the parent HUD window using BeginChild to anchor progress bars.
  huds[name].OnRender.Add(function()
    if bar.init then
      bar:init()
      bar.init = nil
    end

    if ImGui.BeginChild(bar.name .. "##" .. name, Vector2.new(0, 0), false, huds[name].WindowSettings) then
      local fontScale = bar.settings.fontScale_flt or 1
      ImGui.SetWindowFontScale(fontScale)

      for _, style in ipairs(bar.styleVar or {}) do
        ImGui.PushStyleVar(style[1], type(style[2]) == "function" and style[2](bar) or style[2])
      end
      for _, color in ipairs(bar.styleColor or {}) do
        ImGui.PushStyleColor(color[1], type(color[2]) == "function" and color[2](bar) or color[2])
      end

      if bar.type == "progress" then
        ImGui.PushStyleColor(_imgui.ImGuiCol.PlotHistogram, bar.settings.color_col4 or 0xFFFFFFFF)

        -- Render the progress bar inside the HUD without default text.
        local progressBarSize = Vector2.new(ImGui.GetContentRegionAvail().X, ImGui.GetContentRegionAvail().Y)
        local progressFraction = bar.value() / bar.max()
        local progressBarStartPos = ImGui.GetCursorScreenPos()   -- Save the starting position of the progress bar
        ImGui.ProgressBar(progressFraction, progressBarSize, "") -- Render bar without default text

        -- Calculate and render custom text based on alignment setting
        local text = bar.text and bar:text() or string.format("%.0f%%%%", progressFraction * 100)

        imguiAligner(bar, text, progressBarStartPos, progressBarSize)
        ImGui.Text(text)

        ImGui.PopStyleColor() -- Ensure this matches PushStyleColor()
      elseif bar.type == "button" then
        if bar.settings.icon_hex then
          DrawIcon(bar)
        elseif ImGui.Button(bar.text and bar:text() or bar.settings.label_str or ("##" .. bar.name), ImGui.GetContentRegionAvail()) then
          bar:func()
        end
      elseif bar.type == "text" then
        ---@diagnostic disable-next-line
        local text = bar:text()
        imguiAligner(bar, text)
        ImGui.Text(text)
      elseif bar.render then
        bar.render(bar)
      end

      for _, __ in ipairs(bar.styleColor or {}) do
        ImGui.PopStyleColor()
      end
      for _, __ in ipairs(bar.styleVar or {}) do
        ImGui.PopStyleVar()
      end

      -- Save position/size when Ctrl is pressed.
      if ImGui.GetIO().KeyCtrl then
        local currentPos = ImGui.GetWindowPos() - Vector2.new(0, ImGui.GetFontSize() / fontScale)
        local currentContentSize = ImGui.GetWindowSize() - Vector2.new(0, -ImGui.GetFontSize() / fontScale)
        if currentPos.X ~= (bar.position and bar.position.X or -1) or
            currentPos.Y ~= (bar.position and bar.position.Y or -1) or
            currentContentSize.X ~= (bar.size and bar.size.X or -1) or
            currentContentSize.Y ~= (bar.size and bar.size.Y or -1) then
          bar.position = currentPos
          bar.size = currentContentSize
          if bar.renderContext ~= nil then
            bar[bar.renderContext] = {
              position = Vector2.new(bar.position.X, bar.position.Y),
              size = Vector2.new(
                bar.size.X, bar.size.Y)
            }
            SaveBarSettings(bar, bar.renderContext,
              { position = { X = bar.position.X, Y = bar.position.Y }, size = { X = bar.size.X, Y = bar.size.Y } })
          else
            SaveBarSettings(bar, "position", { X = bar.position.X, Y = bar.position.Y }, "size",
              { X = bar.size.X, Y = bar.size.Y })
          end
        end
      end
    end

    ImGui.EndChild()
    ImGui.PopStyleVar(5) --WindowMinSize,WindowPadding,FramePadding,ItemSpacing,ItemInnerSpacing
  end)
end

-- Create HUDs for each bar as invisible windows
for i, bar in ipairs(bars) do
  if bar.settings and bar.settings.enabled then
    hudCreate(bar)
  end
end


----------------------------------------
--- CREATE SETTINGS HUD
----------------------------------------


local function ColorConvertVector3ToU32(colorVector)
  -- Clamp values to [0, 1] range
  local r = math.max(0, math.min(1, colorVector.x))
  local g = math.max(0, math.min(1, colorVector.y))
  local b = math.max(0, math.min(1, colorVector.z))

  -- Convert to 0-255 range and round to nearest integer
  local r_int = math.floor(r * 255 + 0.5)
  local g_int = math.floor(g * 255 + 0.5)
  local b_int = math.floor(b * 255 + 0.5)

  -- Combine into a single U32 value (assuming ABGR format)
  return 0xFF000000 + (b_int * 65536) + (g_int * 256) + r_int
end

local function renderBars(bar)
  if bar.settingsTreeClose then
    ImGui.SetNextItemOpen(false)
    bar.settingsTreeClose=nil
  end
  if ImGui.CollapsingHeader(bar.name) then
    for settingName, setting in pairs(bar.settings) do
      ImGui.Text(settingName)
      ImGui.SameLine()
      local settingType = settingName:match(".*_(.*)$")

      if settingType == nil then
        local checked = setting
        local changed = ImGui.Checkbox("##" .. bar.name .. "_" .. settingName, checked)
        if changed then
          checked = not checked
          bar.settings[settingName] = checked
          if settingName == "enabled" then
            if checked then
              hudCreate(bar)
            else
              bar.settingsTreeClose = true
              bar.hud.Dispose()
              bar.hud = nil
            end
          end
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "col4" then
        local color = ImGui.ColorConvertU32ToFloat4(setting)
        ImGui.SetNextItemWidth(-1)
        local changed, changedColor = ImGui.ColorEdit4("##" .. bar.name .. "_" .. settingName, color)
        if changed then
          ---@diagnostic disable-next-line
          local newColor = ImGui.ColorConvertFloat4ToU32(changedColor)
          bar.settings[settingName] = newColor
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "col3" then
        local color = ImGui.ColorConvertU32ToFloat4(setting)
        local color3 = Vector3.new(color.X, color.Y, color.Z)
        ImGui.SetNextItemWidth(-1)
        local changed, changedColor = ImGui.ColorEdit3("##" .. bar.name .. "_" .. settingName, color3)
        if changed then
          ---@diagnostic disable-next-line
          local newColor = ColorConvertVector3ToU32(changedColor)
          bar.settings[settingName] = newColor
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "num" then
        local value = setting
        ImGui.SetNextItemWidth(-1)
        local changed, changedValue = ImGui.InputInt("##" .. bar.name .. "_" .. settingName, value, 1, 100)
        if changed then
          bar.settings[settingName] = changedValue
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "flt" then
        local value = setting
        ImGui.SetNextItemWidth(-1)
        local changed, changedValue = ImGui.InputFloat("##" .. bar.name .. "_" .. settingName, value, 0.1, 1)
        if changed then
          bar.settings[settingName] = changedValue
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "str" then
        local value = setting
        local valueBuffer = value
        ImGui.SetNextItemWidth(-1)
        local changed, changedValue = ImGui.InputTextMultiline("##" .. bar.name .. "_" .. settingName, valueBuffer, 256,Vector2.new(-1,(select(2, string.gsub(valueBuffer, "\n", "\n"))+1)*ImGui.GetTextLineHeightWithSpacing()+ImGui.GetStyle().FramePadding.Y))
        if changed then
          bar.settings[settingName] = changedValue
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "hex" then
        local value = string.format("0x%X", setting)
        local valueBuffer = value
        ImGui.SetNextItemWidth(-1)
        local changed, changedValue = ImGui.InputText("##" .. bar.name .. "_" .. settingName, valueBuffer, 256)
        if changed then
          bar.settings[settingName] = tonumber(changedValue)
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType == "combo" then
        ---@diagnostic disable-next-line
        local listItems = { unpack(setting, 2, #setting) }
        ImGui.SetNextItemWidth(-1)
        local changed, newIndex = ImGui.Combo("##" .. bar.name .. "_" .. settingName, setting[1] - 1, listItems,
          #listItems)                                                                                                   -- -1 for imgui
        if changed then
          bar.settings[settingName][1] = newIndex + 1                                                                   -- +1 for lua
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      elseif settingType=="pct" then
        local value = setting[1]
        local valueBuffer = value
        local min = setting[2]
        local max = setting[3]
        ImGui.SetNextItemWidth(-1)
        local changed, changedValue = ImGui.SliderFloat("##" .. bar.name .. "_" .. settingName,valueBuffer,min,max,"%.2f")
        if changed then
          bar.settings[settingName] = {changedValue, min, max}
          SaveBarSettings(bar, "settings." .. settingName, bar.settings[settingName])
        end
      else
        ImGui.Text(tostring(setting))
      end
    end
  end
end
settingsHud.OnRender.Add(function()
  ImGui.Text("Active Bars")
  for i, bar in ipairs(bars) do
    if bar.hud then
      renderBars(bar)
    end
  end
  ImGui.NewLine()
  ImGui.Text("Inactive Bars")
  for i, bar in ipairs(bars) do
    if bar.hud == nil then
      renderBars(bar)
    end
  end
end)
