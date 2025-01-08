local _imgui = require("imgui")
ImGui = _imgui.ImGui
local views = require("utilitybelt.views")
local io = require("filesystem").GetScript()
local settingsFile = "bar_settings.json"

local bars = require("bars")

local borderColor = 0xFF000000 -- Black color for borders
local borderSize = 0         -- Thickness of the border; 0 to disable

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

function DrawIcon(bar)
  local size=bar.size
  if not bar.size then size=Vector2.new(24,24) end
  if ImGui.TextureButton(tostring(bar.id), GetOrCreateTexture(bar.icon), size) then
    bar:func()
  end
  
  local drawlist=ImGui.GetWindowDrawList()
  local rectMin = ImGui.GetItemRectMin()
  local rectMax = ImGui.GetItemRectMax()
  
  -- Draw a semi-transparent background
  drawlist.AddRectFilled(rectMin, rectMax, 0x66000000)
  
  local textSize=ImGui.CalcTextSize(bar.label)
  local startText=Vector2.new(
    rectMin.X + (rectMax.X - rectMin.X - textSize.X) / 2,
    rectMin.Y + (rectMax.Y - rectMin.Y - textSize.Y) / 2
  )
  
  -- Draw text in white
  drawlist.AddText(startText, 0xFFFFFFFF, bar.label)
end

----------------------------------------
--- Settings Saving/Loading
----------------------------------------
local barPositions = {}
local barSizes = {}

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
          barPositions[i] = Vector2.new(characterSettings[bar.name].position.X, characterSettings[bar.name].position.Y)
          barSizes[i] = Vector2.new(characterSettings[bar.name].size.X, characterSettings[bar.name].size.Y)
        end
      end
    end
  end
end

-- Function to pretty-print JSON (never omitted again!)
local function prettyPrintJSON(value, indent)
  local function wrapString(value)
    return '"' .. value:gsub('"', '\\"') .. '"'
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

-- Save settings to a JSON file with prettification (indentation)
local function saveSettings()
    local settings = {}
    local files = io.FileExists(settingsFile)
    if files then
        local content = io.ReadText(settingsFile)
        settings = json.parse(content) or {}
    end

    if not settings[game.ServerName] then
        settings[game.ServerName] = {}
    end
    if not settings[game.ServerName][game.Character.Weenie.Name] then
        settings[game.ServerName][game.Character.Weenie.Name] = {}
    end

    for i, bar in ipairs(bars) do
        if barPositions[i] and barSizes[i] then
            settings[game.ServerName][game.Character.Weenie.Name][bar.name] = {
                position = { X = barPositions[i].X, Y = barPositions[i].Y },
                size = { X = barSizes[i].X, Y = barSizes[i].Y }
            }
        end
    end

    io.WriteText(settingsFile, prettyPrintJSON(settings))
end

-- Load settings when the script starts.
loadSettings()

----------------------------------------
--- ImGui Display Logic: Separate HUDs for Each Progress Bar
----------------------------------------

local function imguiAligner(bar, text, start, size)
  -- Default to current cursor position and content region if not provided
  start = start or ImGui.GetCursorScreenPos() or Vector2.new(0, 0)  -- Ensure it's not nil
  size = size or ImGui.GetContentRegionAvail()

  -- Calculate the size of the text to align
  local textSize = ImGui.CalcTextSize(text)
  for _ in string.gmatch(text, "%.") do
    textSize.X=textSize.X-ImGui.GetFontSize()/2
  end
  
  
  -- Calculate the X position to center the text, and ensure it doesn't overflow
  local textX
  if bar.textAlignment == "left" then
    textX = start.X  -- Align text to the left
  elseif bar.textAlignment == "center" or bar.textAlignment==nil then
    -- Center the text horizontally, considering the available space
    textX = start.X + (size.X - textSize.X) / 2
    -- Ensure textX doesn't go below the start.X
    textX = math.max(textX, start.X)
  elseif bar.textAlignment == "right" then
    textX = start.X + size.X - textSize.X  -- Align text to the right
  end

  -- Calculate the Y position to center the text vertically
  local textY = start.Y + (size.Y - textSize.Y) / 2

  -- Set the cursor to the calculated position
  ImGui.SetCursorScreenPos(Vector2.new(textX, textY))
end

local huds = {} -- Initialize the huds table

-- Create HUDs for each bar as invisible windows
for i, bar in ipairs(bars) do
  huds[i] = views.Huds.CreateHud(bar.name)

  -- Set HUD properties.
  huds[i].Visible = true
  huds[i].ShowInBar = false

  local firstUse=true
  -- Pre-render setup for each HUD.
  huds[i].OnPreRender.Add(function()
    local zeroVector = Vector2.new(0,0) 
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.WindowMinSize, Vector2.new(1, ImGui.GetFontSize()))
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.WindowPadding, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemSpacing, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, zeroVector)
    if firstUse then
      ImGui.SetNextWindowSize(barSizes[i] or Vector2.new(200, 30))
      ImGui.SetNextWindowPos(barPositions[i] or Vector2.new(100 + (i * 10), (i - 1) * (30 + 10)))
      firstUse=false
    end

    -- Set flags to disable all unnecessary decorations.
    if ImGui.GetIO().KeyCtrl then
      huds[i].WindowSettings =
          _imgui.ImGuiWindowFlags.NoScrollbar 
    else
      huds[i].WindowSettings =
          _imgui.ImGuiWindowFlags.NoTitleBar +
          _imgui.ImGuiWindowFlags.NoScrollbar + -- Prevent scrollbars explicitly.
          _imgui.ImGuiWindowFlags.NoMove +      -- Prevent moving unless Ctrl is pressed.
          _imgui.ImGuiWindowFlags.NoResize +  -- Prevent resizing unless Ctrl is pressed.
          (bar.windowSettings or 0)
    end
  end)

  -- Render directly into the parent HUD window using BeginChild to anchor progress bars.
  huds[i].OnRender.Add(function()
    if ImGui.BeginChild(bar.name .. "##" .. i, Vector2.new(0, 0), false, huds[i].WindowSettings) then

      local fontScale = bar.fontScale or 1
      ImGui.SetWindowFontScale(fontScale)
      
      -- Apply border styles conditionally based on the setting at the top of the script.
      if borderSize > 0 then
        ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FrameBorderSize, borderSize)
        ImGui.PushStyleColor(_imgui.ImGuiCol.Border, borderColor)
      end
      for stylevar,style in ipairs(bar.stylevar or {}) do
        ImGui.PushStyleVar(stylevar,style)
      end

      if bar.init then
        bar.init(bar)
      end
      if bar.type == "progress" then
        ImGui.PushStyleColor(_imgui.ImGuiCol.PlotHistogram, bar.color)

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
        if bar.id then
          if bar.icon then
            DrawIcon(bar)
          end
        elseif ImGui.Button(bar.text and bar:text() or bar.label,ImGui.GetContentRegionAvail()) then
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
      
      for stylevar,style in ipairs(bar.stylevar or {}) do
        ImGui.PopStyleVar()
      end
      if borderSize > 0 then
        ImGui.PopStyleVar()
        ImGui.PopStyleColor()
      end

      -- Save position/size when Ctrl is pressed.
      if ImGui.GetIO().KeyCtrl then
        local currentPos = ImGui.GetWindowPos()-Vector2.new(0,ImGui.GetFontSize()) 
        local currentContentSize = ImGui.GetWindowSize()-Vector2.new(0,-ImGui.GetFontSize()) 

        if currentPos.X ~= (barPositions[i] and barPositions[i].X or -1) or
            currentPos.Y ~= (barPositions[i] and barPositions[i].Y or -1) or
            currentContentSize.X ~= (barSizes[i] and barSizes[i].X or -1) or
            currentContentSize.Y ~= (barSizes[i] and barSizes[i].Y or -1) then
          barPositions[i] = currentPos
          barSizes[i] = Vector2.new(currentContentSize.X, currentContentSize.Y)

          saveSettings()
        end
      end
    end

    ImGui.EndChild()
    ImGui.PopStyleVar(5) --WindowMinSize,WindowPadding,FramePadding,ItemSpacing,ItemInnerSpacing
  end)
end