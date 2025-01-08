local hud
local function init()
  ---Setup
  local io = require("filesystem").GetScript()
  local acclient = require("acclient")
  local _imgui = require("imgui")
  local ImGui = _imgui.ImGui
  local views = require("utilitybelt.views")

  
  local settingsFile = "hud_settings.json"
  local config = require("config.lua")
  local lastPosition = nil

  local corpseList = {}
  local blacklist = {}
  local shapes = {}
  local distances = {}
  local time = {}

  local sortColumn = 1
  local sortAscending = true
  local columnWidths = { 60, 200, 70 }     -- Default column widths
  local windowSize = Vector2.new(400, 300) -- Default size, adjust as needed
  local hkLockout = false
  local sortDirty = false

  local genericActionOpts=ActionOptions.new()
  ---@diagnostic disable
  genericActionOpts.MaxRetryCount=0
  genericActionOpts.TimeoutMilliseconds=1
  ---@diagnostic enable

  ----------------------------------------
  --- corpse handler
  ----------------------------------------

  -- Function to add a new corpse to the end of the list
  local function addCorpse(corpseId)
    for i,corpse in ipairs(corpseList) do
      if corpse==corpseId then
        return
      end
    end
    if blacklist[corpseId] then return end
    table.insert(corpseList, corpseId)
    local coords = acclient.Movement.GetPhysicsCoordinates(corpseId)
    shapes[corpseId] = acclient.DecalD3D.NewD3DObj()
    shapes[corpseId].SetShape(config.markerShape)
    shapes[corpseId].Anchor(coords.NS, coords.EW, coords.Z + config.shapeZOffset)
    if config.shapeOrientToPlayer then shapes[corpseId].OrientToPlayer(config.shapeVerticalTilt) end
    shapes[corpseId].Scale(config.shapeScale0to1)
    shapes[corpseId].Color = config.shapeColor0xAARRBBGG
    shapes[corpseId].Visible = true
    distances[corpseId] = acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(corpseId))
    time[corpseId] = os.clock()
    sortDirty = true
  end

  -- Function to remove a corpse from the list
  local function removeCorpse(corpseId)
    for i, id in ipairs(corpseList) do
      if id == corpseId then
        shapes[id].Dispose()
        shapes[id] = nil
        distances[id] = nil
        time[id] = nil
        table.remove(corpseList, i)
        break
      end
    end
  end

  -- Function to format elapsed time
  local function formatElapsedTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02d:%02d", minutes, remainingSeconds)
  end

  local function sortCorpses()
    table.sort(corpseList, function(a, b)
      local overLimitA = os.difftime(os.clock(), time[a]) > config.corpsePrioritySeconds
      local overLimitB = os.difftime(os.clock(), time[b]) > config.corpsePrioritySeconds

      -- Always prioritize corpses over the time limit
      if overLimitA and overLimitB then
        return time[a] < time[b] -- Sort by longest tracked (smallest timestamp first)
      elseif overLimitA then
        return true              -- Corpses over the limit come first
      elseif overLimitB then
        return false             -- Corpses under the limit come after
      end

      -- Regular sorting for corpses under the time limit
      local valueA, valueB
      if sortColumn == 1 then
        valueA, valueB = distances[a], distances[b]
      elseif sortColumn == 2 then
        valueA, valueB = game.World.Get(a).Name, game.World.Get(b).Name
      else
        valueA, valueB = time[a], time[b]
      end

      -- Apply ascending or descending sort only for corpses under the time limit
      if sortAscending then
        return valueA < valueB
      else
        return valueA > valueB
      end
    end)
  end

  -- Function to loot next corpse
  local function lootNextCorpse(corpseIndexOverride)
    local nextCorpseId = corpseList[corpseIndexOverride or 1]
    if nextCorpseId then
      if debug then print("Looting corpse: " .. nextCorpseId) end
      game.World.Get(nextCorpseId).Use(genericActionOpts)
    else
      if debug then print("No corpses to loot") end
    end
  end

  -- Watches for corpses to spawn.
  game.World.OnObjectCreated.Add(function(e)
    local corpse = game.World.Get(e.ObjectId)
    if not corpse or corpse.ObjectClass ~= ObjectClass.Corpse then return end

    game.Actions.ObjectAppraise(e.ObjectId, ActionOptions.new(), function(res)
      if (corpse.Value(StringId.LongDesc) == "Killed by " .. game.Character.Weenie.Name .. ".") then
        addCorpse(e.ObjectId)
        corpse.OnDestroyed.Once(function(evt) removeCorpse(e.ObjectId) end)
      end
    end)
  end)

  -- Watches for corpses to be opened.
  game.World.OnContainerOpened.Add(function(e)
    blacklist[e.Container.Id] = true
    removeCorpse(e.Container.Id)
  end)

  -- Updates distances when character moves.
  game.Character.Weenie.OnPositionChanged.Add(function(e)
    for _, corpse in ipairs(corpseList) do
      distances[corpse] = acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(corpse))
    end
    if sortColumn == 1 then
      sortCorpses()
    end
  end)


  local function getNextCombatTarget()
    local nearest = 99
    local candidate = nil
    game.World.GetAll(function(weenie)
      if weenie == game.World.Selected or weenie.ObjectClass ~= ObjectClass.Monster or weenie.Name == "" then return false end
      local candidateDistance = acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(weenie.Id))
      if candidateDistance < nearest then
        candidate = weenie
        nearest = candidateDistance
        return false
      end
    end)
    if candidate then
      game.Actions.ObjectSelect(candidate.Id)
    end
  end


  ----------------------------------------
  --- xp display
  ----------------------------------------

  local xp
  local xpRider = 0
  local function xpDispose(resetRider)
    if xp then
      xp.Dispose()
      xp=nil
    end
    if resetRider then
      xpRider=0
    end
  end

  game.Character.OnTotalExperienceChanged.Add(function(e)
    xpRider = xpRider + e.TotalExperience - e.OldTotalExperience
  end)

  game.Messages.Incoming.Combat_HandleVictimNotificationEventOther.Add(function(e)
    if game.World.Selected == nil or game.World.Selected.Container ~= nil then
      getNextCombatTarget()
    end

    sleep(300) -- allow for server assigned XP to come in
    if xpRider > 0 then
      xpDispose()
      xp = acclient.DecalD3D.MarkObjectWith3DText(game.Character.Weenie.Id, " +" .. tostring(xpRider) .. " xp", "Arial",
        0x00000000)
      xp.Color = config.xpColor0xAARRGGBB
      xp.Scale(config.xpScale0to1)
      xp.Anchor(game.CharacterId, 1.1, 0, 0, config.xpZOffset)
      xp.OrientToCamera(true)
      xp.Visible = true
      sleep(config.xpTimeoutSeconds*1000)
      xpDispose(true)
    end
  end)


  ----------------------------------------
  --- trophy
  ----------------------------------------

  local trophyOncer
  if config.trophyHander then
    local function handStuffIn(npc,trophyBag)
      local trophies = game.World.Get(trophyBag).AllItemIds
      local trophy = trophies[1]
      if not trophy then return end

      game.Messages.Incoming.Item_ServerSaysContainID.Once(function(serverContainEvent)
        game.Messages.Incoming.Item_CreateObject.Until(function(createdObjectEvent)
          if (createdObjectEvent.Data.ObjectId==serverContainEvent.Data.ObjectId and createdObjectEvent.Data.WeenieDesc.Name=="Pyreal") then
            local newPyreal=game.World.Get(createdObjectEvent.Data.ObjectId)
            local moneys=game.Character.GetInventory(ObjectClass.Money)
            for _,money in ipairs(moneys) do
              if money.Id~=newPyreal.Id and money.Name=="Pyreal" and (money.Value(IntId.StackSize)+newPyreal.Value(IntId.StackSize)<=money.Value(IntId.MaxStackSize)) then
                newPyreal.Move(money.ContainerId,0,true)
                break
              end
            end
            handStuffIn(npc,trophyBag)
            ---@diagnostic disable-next-line
            return true
          end
        end)
      end)
      
      trophyOncer=trophy
      game.World.OnConfirmationRequest.Once(function(e)
        local trophyWeenie=game.World.Get(trophyOncer)
        if not trophyWeenie then return end
        trophyOncer=nil
          
        e.ClickYes = true
      end)

      game.Actions.ObjectGive(trophy,npc,genericActionOpts)
    end

    game.World.OnChatInput.Add(function(chatinput)
      if chatinput.Text=="/trophy" then
        chatinput.Eat = true
        print("Run /trophy with the trophy bag selected, then select the Trophy Collector. Make sure you have the slots for pyreal")
    
        if game.World.Selected==nil or game.World.Selected.ObjectClass~=ObjectClass.Container then
          print("Trophy bag not selected. Try again")
        else
          local trophyBag=game.World.Selected.Id
          game.World.OnObjectSelected.Once(function(f)
            if game.World.Selected.ObjectClass==ObjectClass.Npc then
              handStuffIn(game.World.Selected.Id,trophyBag)
            end
          end)
        end
      end
    end)
  end


  ----------------------------------------
  --- window position saving/loading
  ----------------------------------------

  -- Function to load settings from a JSON file
  local function loadSettings()
    local files = io.FileExists(settingsFile)
    if files then
      local content = io.ReadText(settingsFile)
      local settings = json.parse(content)
      if settings and settings[game.ServerName] and settings[game.ServerName][game.Character.Weenie.Name] then
        local characterSettings = settings[game.ServerName][game.Character.Weenie.Name]
        if characterSettings.hudPosition then
          lastPosition = Vector2.new(characterSettings.hudPosition.X, characterSettings.hudPosition.Y)
        end
        if characterSettings.columnWidths then
          columnWidths = characterSettings.columnWidths
        end
        if characterSettings.windowSize then
          windowSize = Vector2.new(characterSettings.windowSize.X, characterSettings.windowSize.Y)
        end
      end
    end
  end

  -- Function to pretty-print JSON
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

  -- Function to save settings to a JSON file with prettification (indentation)
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

    settings[game.ServerName][game.Character.Weenie.Name] = {
      hudPosition = { X = ImGui.GetWindowPos().X, Y = ImGui.GetWindowPos().Y },
      columnWidths = columnWidths,
      windowSize = { X = windowSize.X, Y = windowSize.Y }
    }

    -- Use prettyPrintJSON directly on the settings table
    io.WriteText(settingsFile, prettyPrintJSON(settings))
  end

  -- Load settings when the script starts.
  loadSettings()


  ----------------------------------------
  --- ImGui display and xp coroutine
  ----------------------------------------

  hud = views.Huds.CreateHud("corpses")
  hud.WindowSettings = _imgui.ImGuiWindowFlags.NoTitleBar
  hud.Visible = true

  hud.OnPreRender.Add(function()
    ImGui.SetNextWindowSize(windowSize, _imgui.ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowPos(lastPosition or Vector2.new(100, 100), _imgui.ImGuiCond.FirstUseEver)
  end)

  hud.OnRender.Add(function()
    -- Calculate minimum widths for headers
    local distanceWidth = ImGui.CalcTextSize("Dist").X + 3 -- Add padding of 3
    --local nameWidth = ImGui.CalcTextSize("Name").X + 3      -- Add padding of 3
    local timeWidth = ImGui.CalcTextSize("Time").X + 3     -- Add padding of 3
    if ImGui.BeginTable("corpses", 3, _imgui.ImGuiTableFlags.SizingFixedFit + _imgui.ImGuiTableFlags.Sortable + _imgui.ImGuiTableFlags.Resizable + _imgui.ImGuiTableFlags.ScrollY) then
      ImGui.TableSetupScrollFreeze(0, 1)                   -- Freeze the header row

      -- Set up columns with calculated widths
      ImGui.TableSetupColumn("Dist", _imgui.ImGuiTableColumnFlags.WidthFixed, distanceWidth)
      ImGui.TableSetupColumn("Name", _imgui.ImGuiTableColumnFlags.WidthStretch)
      ImGui.TableSetupColumn("Time", _imgui.ImGuiTableColumnFlags.WidthFixed, timeWidth)
      ImGui.TableHeadersRow()

      -- Handle sorting in your ImGui render function
      local sortSpecs = ImGui.TableGetSortSpecs()
      if sortSpecs and (sortSpecs.SpecsDirty or sortDirty) then
        sortColumn = sortSpecs.Specs.ColumnIndex + 1
        sortAscending = (sortSpecs.Specs.SortDirection == _imgui.ImGuiSortDirection.Ascending)
        sortCorpses() -- Call your sorting function here with updated logic.
        sortSpecs.SpecsDirty = false
        sortDirty = false
      end

      -- Inside the hud.OnRender.Add(function() block, where you render rows:
      local mousePos = ImGui.GetMousePos()                   -- Get current mouse position
      local tableStartPos = ImGui.GetWindowPos()             -- Get the starting position of the table
      local rowHeight = ImGui.GetTextLineHeightWithSpacing() -- Get height of each row

      -- Get current scroll offset
      local scrollY = ImGui.GetScrollY()
      local header_height = ImGui.GetFrameHeight()

      for i, corpse in ipairs(corpseList) do
        ImGui.TableNextRow()

        -- First Column: Distance
        ImGui.TableSetColumnIndex(0)
        columnWidths[1] = ImGui.GetContentRegionAvail().X
        ImGui.Text(string.format("%.1f", distances[corpse]))

        -- Second Column: Name
        ImGui.TableSetColumnIndex(1)
        columnWidths[2] = ImGui.GetContentRegionAvail().X
        ImGui.Text(game.World.Get(corpse).Name)

        -- Third Column: Time
        ImGui.TableSetColumnIndex(2)
        columnWidths[3] = ImGui.GetContentRegionAvail().X
        local elapsedTime = os.difftime(os.clock(), time[corpse])
        ImGui.Text(formatElapsedTime(elapsedTime))

        -- Calculate if the current row is clicked considering scroll offset
        local rowYStart = tableStartPos.Y + (i - 1) * rowHeight - scrollY + header_height
        local rowYEnd = rowYStart + rowHeight + header_height

        if mousePos.X >= tableStartPos.X and mousePos.X <= tableStartPos.X + ImGui.GetWindowSize().X and
            mousePos.Y >= rowYStart and mousePos.Y <= rowYEnd and
            ImGui.IsMouseClicked(0) then -- Check if left mouse button is clicked
          lootNextCorpse(i)              -- Pass the index of the clicked corpse
        end
      end

      ImGui.EndTable()
    end

    -- Keypress handling
    if ImGui.IsKeyPressed(config.LOOTING_HOTKEY, false) and not hkLockout then
      hkLockout = true
      sortCorpses()
      lootNextCorpse()
    elseif hkLockout and not ImGui.IsKeyPressed(config.LOOTING_HOTKEY, false) then
      hkLockout = false
    end
    for _, key in ipairs(config.NOTARGETCAST) do
      if ImGui.IsKeyPressed(key, false) and (game.World.Selected == nil or game.World.Selected.Container ~= nil) then
        getNextCombatTarget()
      end
    end
    -- Check for changes in window position, size, or column widths
    local currentPosition = ImGui.GetWindowPos()
    local currentSize = ImGui.GetWindowSize()

    local shouldSave = false
    if not lastPosition or currentPosition.X ~= lastPosition.X or currentPosition.Y ~= lastPosition.Y then
      lastPosition = currentPosition
      shouldSave = true
    end

    if currentSize.X ~= windowSize.X or currentSize.Y ~= windowSize.Y then
      windowSize = currentSize
      shouldSave = true
    end

    for i = 1, 3 do
      if columnWidths[i] ~= (i == 2 and ImGui.GetContentRegionAvail().X or (i == 1 and distanceWidth or timeWidth)) then
        columnWidths[i] = (i == 2 and ImGui.GetContentRegionAvail().X or (i == 1 and distanceWidth or timeWidth))
        shouldSave = true
      end
    end

    if shouldSave then
      saveSettings()
    end
  end)
end


----------------------------------------
--- init
----------------------------------------

if game.State == ClientState.In_Game then
  init()
end

game.OnStateChanged.Add(function(state)
  if state.NewState == ClientState.In_Game then
    init()
  elseif hud then
    hud.Dispose()
  end
end)
