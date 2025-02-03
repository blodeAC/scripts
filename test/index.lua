local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local views = require("utilitybelt.views")
local io = require("filesystem").GetScript()

local inspectedItem
local inspectQueue = {}
local hud            -- main window
local lootRuleHolder --loot rule window

local copyAndSort

-----------------------------------------------------
--- enum stuff
-----------------------------------------------------

local allValueStrings = { "IntValues", "BoolValues", "DataValues", "Int64Values", "FloatValues", "StringValues" }
local allEnums = { "IntId", "BoolId", "DataId", "Int64Id", "FloatId", "StringId" }
local enumDefault = { 1, false, 1, 1, 1.0, "" }

require("DaraletGlobals")

local sortedEnums = {}
for _, enum in ipairs(allEnums) do
  local sorted = table.sort(_G[enum].GetValues(), function(a, b)
    return tostring(a) < tostring(b)
  end)
  for i, extra in ipairs(ExtraEnums[allValueStrings[_]]) do
    ---@diagnostic disable-next-line
    table.insert(sorted, extra)
  end
  table.insert(sortedEnums, sorted)
end


WieldRequirements = {
  Invalid = 0,
  Skill_DONOTUSE = 1,
  SkillId = 2,
  Attribute_DONOTUSE = 3,
  AttributeId = 4,
  VitalId_DONOTUSE = 5,
  VitalId = 6,
  Level = 7,
  Training = 8,
  IntId = 9,
  BoolId = 10,
  CreatureType = 11,
  HeritageGroup_BROKEN = 12
}
WieldRequirements.GetValues = function(value)
  if value then
    for name, enumVal in pairs(WieldRequirements) do
      if enumVal == value then
        return enumVal
      end
    end
  else
    return { "Invalid", "Skill_DONOTUSE", "SkillId", "Attribute_DONOTUSE", "AttributeId", "Vital_DONOTUSE",
      "VitalId", "Level", "Training", "IntId", "BoolId", "CreatureType", "HeritageGroup_BROKEN" }
  end
end
WieldRequirements.FromValue = function(value)
  ---@diagnostic disable-next-line
  return WieldRequirements.GetValues(value)
end

local enumMasks = {}
enumMasks = {
  ItemUseable = UsableType,
  HookObjectType = HookType,
  ClothingPriority = CoverageMask,
  RadarColor = RadarColor,
  RadarBehavior = RadarBehavior,
  Material = MaterialType,
  CurrentWieldedLocation = EquipMask,
  ValidWieldedLocations = EquipMask,
  ValidLocations = EquipMask,

  WieldSkilltype = function(item)
    if item.IntValues["WieldRequirements"] then
      local wieldReq = WieldRequirements.GetValues()[item.IntValues["WieldRequirements"] + 1]
      if wieldReq ~= "Training" then
        return wieldReq
      end
    end
    return "SkillId"
  end,
  WieldSkilltype2 = function(item)
    if item.IntValues["WieldRequirements2"] then
      local wieldReq = WieldRequirements.GetValues()[item.IntValues["WieldRequirements2"] + 1]
      if wieldReq ~= "Training" then
        return wieldReq
      end
    end
    return "SkillId"
  end,
  WieldSkilltype3 = function(item)
    if item.IntValues["WieldRequirements3"] then
      local wieldReq = WieldRequirements.GetValues()[item.IntValues["WieldRequirements3"] + 1]
      if wieldReq ~= "Training" then
        return wieldReq
      end
    end
    return "SkillId"
  end,
  WieldSkilltype4 = function(item)
    if item.IntValues["WieldRequirements4"] then
      local wieldReq = WieldRequirements.GetValues()[item.IntValues["WieldRequirements4"] + 1]
      if wieldReq ~= "Training" then
        return wieldReq
      end
    end
    return "SkillId"
  end,

  WieldDifficulty = function(item)
    if item.IntValues["WieldRequirements"] == 8 then
      return "SkillTrainingType"
    end
    return item.IntValues["WieldDifficulty"]
  end,
  WieldDifficulty2 = function(item)
    if item.IntValues["WieldRequirements2"] == 8 then
      return "SkillTrainingType"
    end
    return item.IntValues["WieldDifficulty2"]
  end,
  WieldDifficulty3 = function(item)
    if item.IntValues["WieldRequirements3"] == 8 then
      return "SkillTrainingType"
    end
    return item.IntValues["WieldDifficulty3"]
  end,
  WieldDifficulty4 = function(item)
    if item.IntValues["WieldRequirements4"] == 8 then
      return "SkillTrainingType"
    end
    return item.IntValues["WieldDifficulty4"]
  end,

  WieldRequirements2 = WieldRequirements,
  WieldRequirements3 = WieldRequirements,
  WieldRequirements4 = WieldRequirements,

  Training = WieldRequirements,

  AmmoType = AmmoType,
  ObjectType = ObjectType,
  TargetType = ObjectType,
  IconEffects = IconHighlight,
  CombatUse = WieldType,
  ObjectDescriptionFlag = ObjectDescriptionFlag,
  ContainerProperties = ContainerProperties,
  PhysicsState = PhysicsState,
  LastAppraisalResponse = DateTime,
  WeaponSkill = SkillId,

  D_SigilTrinketBonusStat = D_SigilTrinketBonusStat,
  D_ArmorWeightClass = D_ArmorWeightClass,
  D_ArmorStyle = D_ArmorStyle,
  D_WeaponSubtype = D_WeaponSubtype
}
-----------------------------------------------------
--- helpers
-----------------------------------------------------

local function moveElementUp(t, index)
  if index > 1 then -- Ensure it's not already at the top
    local temp = t[index - 1]
    t[index - 1] = t[index]
    t[index] = temp
  end
end

local function moveElementDown(t, index)
  if index < #t then -- Ensure it's not already at the bottom
    local temp = t[index + 1]
    t[index + 1] = t[index]
    t[index] = temp
  end
end

local function removeElement(t, index)
  for i = index, #t - 1 do
    t[i] = t[i + 1] -- Shift elements left
  end
  t[#t] = nil       -- Remove the last element
end

-----------------------------------------------------
--- events
-----------------------------------------------------

local lootRules = {}

local function evaluateLoot(item)
  for i, ruleItem in ipairs(lootRules) do
    if ruleItem.disabled then
      -- print("skipping "..ruleItem.name)
    else
      local lootable = true
      for _, keyValue in ipairs(allValueStrings) do
        if lootable then
          if not ruleItem.sorted then
            ruleItem = copyAndSort(ruleItem)
          end
          for j = #ruleItem.sorted[keyValue], 1, -1 do
            local key = ruleItem.sorted[keyValue][j]
            local keyForCompare = string.gsub(key, "^_+", "")
            local itemValue = item[keyValue][keyForCompare]
            if itemValue == nil then
              lootable = false -- If the item doesn't have the property, it doesn't match
            else
              local comparator = ruleItem.comparator[keyValue] and ruleItem.comparator[keyValue][key] or "=="
              local ruleValue = ruleItem[keyValue][key]
              local function andOrParser()
                return ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and
                  (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or
                  ruleItem.AndOr[key] == "and")
              end
              if keyValue == "StringValues" and comparator == "==" then
                if not Regex.IsMatch(itemValue or "", ruleValue or "") and andOrParser() then
                  lootable = false
                end
              elseif comparator == "==" and itemValue ~= ruleValue and andOrParser() then
                lootable = false
              elseif comparator == ">=" and itemValue < ruleValue and andOrParser() then
                lootable = false
              elseif comparator == "<=" and itemValue > ruleValue and andOrParser() then
                lootable = false
              elseif comparator == ">" and itemValue <= ruleValue and andOrParser() then
                lootable = false
              elseif comparator == "<" and itemValue >= ruleValue and andOrParser() then
                lootable = false
              elseif comparator == "!=" and itemValue == ruleValue and andOrParser() then
                lootable = false
              end
            end
          end
        end
      end
      if not Regex.IsMatch(item.spells or "", ruleItem.spells or "") then
        lootable = false
      end
      if lootable then
        return ruleItem.name
      end
    end
  end

  return false
end

game.Messages.Incoming.Item_SetAppraiseInfo.Add(function(e)
  local weenie = game.World.Get(e.Data.ObjectId)

  if not weenie then
    return
  end

  local itemData = {
    uid = tostring(os.time()) .. tostring(os.clock()):gsub("%.", ""),
    id = e.Data.ObjectId,
    name = weenie.Name,
    lootCriteria = {
      IntValues = {},
      BoolValues = {},
      DataValues = {},
      Int64Values = {},
      FloatValues = {},
      StringValues = {},
    },
    spells = "",
    AndOr = {}
  }

  if e.Data.SpellBook then
    for i, spellId in ipairs(game.World.Get(e.Data.ObjectId).SpellIds) do
      itemData.spells = (itemData.spells or "") .. game.Character.SpellBook.Get(spellId.Id).Name .. ","
    end
    if string.len(itemData.spells) > 0 then
      itemData.spells = string.sub(itemData.spells, 1, -2)
    end
  end

  for _, keytype in ipairs(allValueStrings) do
    itemData[keytype] = {}
    for k, v in pairs(weenie[keytype]) do
      itemData[keytype][tostring(k)] = v
    end
    local sortableTable = {}
    ---@diagnostic disable-next-line
    for n in pairs(itemData[keytype]) do
      table.insert(sortableTable, n)
    end
    itemData.sorted = itemData.sorted or {}
    itemData.sorted[keytype] = table.sort(sortableTable, function(a, b)
      return a > b
    end)
  end

  if (game.World.Selected ~= nil and game.World.Selected.Id == e.Data.ObjectId) then
    inspectedItem = itemData
  end

  for l=#inspectQueue,1,-1 do
    if inspectQueue[l] == itemData.id then
      local winningLootRule=evaluateLoot(itemData)
      if winningLootRule then
        game.Actions.ObjectMove(itemData.id,game.CharacterId,0,false,ActionOptions.new(),function()
          if weenie.Value(BoolId.Inscribable) then
            weenie.Inscribe(winningLootRule)
          end
        end)
      end
      removeElement(inspectQueue,l)
    end
  end
end)

game.World.OnContainerOpened.Add(function(containerOpenedEvent)
  if containerOpenedEvent.Container.ObjectClass==ObjectClass.Corpse or containerOpenedEvent.Container.Name=="Corpse" then
    local weenie = game.World.Get(containerOpenedEvent.Container.Id)
    for i,itemid in ipairs(weenie.AllItemIds) do
      table.insert(inspectQueue,itemid)
      game.Actions.ObjectAppraise(itemid)
    end
  end
end)

-----------------------------------------------------
--- Profile Saving
-----------------------------------------------------

local function deepcopy(orig, copies)
  copies = copies or {} -- Keep track of already-copied tables to avoid infinite loops
  if type(orig) ~= 'table' then
    return orig         -- Directly return non-table types
  elseif copies[orig] then
    return copies[orig] -- Return already copied table
  end

  local copy = {}
  copies[orig] = copy -- Store the copy reference for circular reference handling

  for key, value in pairs(orig) do
    copy[deepcopy(key, copies)] = deepcopy(value, copies) -- Recursively copy keys and values
  end
  return copy
end

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
    if items~={} then
      
      if isArray then
        return "[\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "]"
      else
        return "{\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
      end
    end
  elseif type(value) == "string" then
    return wrapString(value)
  else
    return tostring(value)
  end
end

local windowData = {} -- Stores window states
local saveFilePath = "window_config.json"
local windows

-- Load previous window data
local function loadWindowData()
  windows = {hud=hud, lootRuleHolder=lootRuleHolder}
  local files = io.FileExists(saveFilePath)
  if files then
    local content = io.ReadText(saveFilePath)
    windowData = json.parse(content) or {}
    for key,window in pairs(windowData) do
      if not window.isVisible then
        windows[key].Visible = false
      end
      local prerender
      function prerender()
        ImGui.SetNextWindowPos(Vector2.new(window.posX,window.posY))
        ImGui.SetNextWindowSize(Vector2.new(window.sizeX,window.sizeY))
        windows[key].OnPreRender.Remove(prerender)
      end
      windows[key].OnPreRender.Add(prerender)
    end
  end
end

-- Save updated window data
local function saveWindowData()
  --local files = io.FileExists(saveFilePath)
  --if files then
    io.WriteText(saveFilePath, prettyPrintJSON(windowData))
  --end
end

-- Track window state (call after ImGui.Begin)
local function trackWindowState(windowName)
  local isVisible = windows[windowName].Visible

  if not isVisible then
    windowData[windowName].isVisible = false
    saveWindowData()
  else
    local posX = ImGui.GetWindowPos().X
    local posY = ImGui.GetWindowPos().Y
    local sizeX = ImGui.GetWindowSize().X
    local sizeY = ImGui.GetWindowSize().Y

    local prevState = windowData[windowName] or {}

    -- Check for changes
    if prevState.posX ~= posX or prevState.posY ~= posY or
        prevState.sizeX ~= sizeX or prevState.sizeY ~= sizeY or
        prevState.isVisible ~= isVisible then
      windowData[windowName] = {
        posX = posX,
        posY = posY,
        sizeX = sizeX,
        sizeY = sizeY,
        isVisible = isVisible
      }
      saveWindowData()
    end
  end
end

local lootSaveFile = "loot.json"

local function loadLootProfile(server,character)
  if server or character then
    if not server or not character then
      return "Invalid character or server"
    end
  end
  server = server or game.ServerName
  character = character or game.Character.Weenie.Name
  local function importSave(bar,key,value)
    if server~=game.ServerName or character~=game.Character.Weenie.Name then
      saveLootProfile(bar,key,value)
    end
  end
  local files = io.FileExists(lootSaveFile)
  if files then
    local content = io.ReadText(lootSaveFile)
    local settings = json.parse(content)
    if settings and settings[server] and settings[server][character] then
      lootRules = settings[server][character]

      for i,rule in ipairs(lootRules) do
        lootRules[i] = copyAndSort(rule)
      end
    else 
      return "No settings found for server or character. Capitalization matters"
    end
  end
end

local function saveLootProfile()
  -- Read existing settings
  local lootProfiles = {}
  if io.FileExists(lootSaveFile) then
    local content = io.ReadText(lootSaveFile)
    lootProfiles = json.parse(content) or {}
  end

  -- Ensure server and character structure exists
  local server = game.ServerName
  local character = game.Character.Weenie.Name

  lootProfiles[server] = lootProfiles[server] or {}
  lootProfiles[server][character] = deepcopy(lootRules) or {}
  for i,rule in ipairs(lootRules) do
    lootProfiles[server][character][i].sorted = nil
    for _,key in ipairs(allValueStrings) do
      lootProfiles[server][character][i][key]=nil
    end
    for _,key in ipairs(allEnums) do
      lootProfiles[server][character][i][key]=nil
    end
    lootProfiles[server][character][i].isRenaming=nil
  end
  
  -- Save back to the file
  io.WriteText(lootSaveFile, prettyPrintJSON(lootProfiles))
end

-----------------------------------------------------
--- ImGui helpers
-----------------------------------------------------

local function comparatorRender(comparators, criteriaObject, valuesKey, key)
  local changeMonitor = false
  if comparators then
    if criteriaObject.comparator == nil then
      criteriaObject.comparator = {}
    end
    if criteriaObject.comparator[valuesKey] == nil then
      criteriaObject.comparator[valuesKey] = {}
    end
    if criteriaObject.comparator[valuesKey][key] == nil then
      criteriaObject.comparator[valuesKey][key] = "=="
    end
    ImGui.SetNextItemWidth(60)
    if ImGui.BeginCombo("##" .. key .. "_comparator", criteriaObject.comparator[valuesKey][key]) then
      for _, comparator in ipairs(comparators) do
        local isSelected = (criteriaObject.comparator == comparator)
        if ImGui.Selectable(comparator, isSelected) then
          criteriaObject.comparator[valuesKey][key] = comparator
          changeMonitor=true
        end
        if isSelected then
          ImGui.SetItemDefaultFocus()
        end
      end
      ImGui.EndCombo()
    end
    ImGui.TableNextColumn()
  end
  return changeMonitor
end

local bit = require("bit")
local function enumCombo(item, valueTable, key, value)
  ---@diagnostic disable:undefined-field
  local keyForText = string.gsub(key, "^_+", "")

  local changeMonitor=false
  local enum
  if valueTable == "IntValues" then
    enum = enumMasks[ExtraEnums.IntValues[keyForText] ] or _G[tostring(keyForText)]
  else
    enum = enumMasks[tostring(keyForText)] or _G[tostring(keyForText)]
  end
  if type(enum) == "function" then
    local globalVal = enum(item)
    if globalVal then
      enum = _G[globalVal] or nil
    end
  end
  if enum ~= nil then
    ImGui.SetNextItemWidth(-1)
    local currentEnumName
    local unparsedEnum = (type(enum) ~= "function" and enum[value]) or
      (enum.FromValue and enum.FromValue(value)) or value
    if type(unparsedEnum) == "number" then
      currentEnumName = tostring(enum.GetValues()[unparsedEnum + 1]) -- mine, so fake. all have to have None or fake None in slot 1, hence +1
    else
      currentEnumName = tostring(unparsedEnum)
    end

    local enumValues = enum.GetValues()
    local enumSize = #enumValues
    local bitmaskOffset = 1

    local isMask = false
    for i, mask in ipairs({ "EquipMask", "AttributeMask", "AttributeMask", "ClothingPriority", "DamageType", "ValidLocations", "CurrentWieldedLocation" }) do
      if keyForText == mask then
        isMask = true
        break
      end
    end
    -- this is the old way of doing bitmasks but it has some issues because a lot of times they will put bitmask values on a nonmaskable
--    local lastEnumVal=enum[tostring(enumValues[enumSize])]

--    if enumSize>6 and enumSize<32 and ((type(lastEnumVal)=="userdata" and lastEnumVal.ToNumber()~=2^enumSize)  or (type(lastEnumVal)=="number" and lastEnumVal~=2^enumSize)) then
--      isMask=true
--    end

    if isMask then
      for j=1,enumSize do
        if enum.FromValue(j)==enumValues[1] then
          bitmaskOffset=j
          break
        end
      end
    end

    if ImGui.BeginCombo("##" .. key .. item.uid, currentEnumName) then
      local currentValue = type(item[valueTable][key]) == "userdata" and (item[valueTable][key]).ToNumber() or
          item[valueTable][key]
      for i = bitmaskOffset, enumSize do
        if isMask then
          local enumValue = 2 ^ (i - 1)
          local enumName = enum.FromValue(enumValue)
          local isSelected = bit.band(currentValue, enumValue) ~= 0

          if ImGui.Selectable(tostring(enumName), isSelected) then
            if isSelected then
              currentValue = bit.band(currentValue, bit.bnot(enumValue))
            else
              currentValue = bit.bor(currentValue, enumValue)
            end

            item[valueTable][key] = currentValue
            changeMonitor=true
          end
        else
          local enumName = enumValues[i]
          local isSelected = (currentEnumName == tostring(enumName))
          if ImGui.Selectable(tostring(enumName), isSelected) then
            item[valueTable][key] = enum[tostring(enumName)]
            changeMonitor=true
          end
          if isSelected then
            ImGui.SetItemDefaultFocus()
          end
        end
      end
      ImGui.EndCombo()
    end
    return true,changeMonitor
  end
  --local changeMonitor=false
  return false, changeMonitor
  ---@diagnostic enable:undefined-field
end

copyAndSort = function(item)
  print("copying and sorting")
  local comparator = (item.comparator and deepcopy(item.comparator)) or {}

  local newItem = deepcopy(item)
  newItem.uid = tostring(os.time()) .. tostring(os.clock()):gsub("%.", "")
  newItem.comparator = comparator

  newItem.sorted = {}
  for valuesKey, values in pairs(newItem.lootCriteria) do
    if valuesKey == "spells" then
      newItem.spells = values
    else
      newItem[valuesKey] = values

      local sortableTable = {}
      for n in pairs(newItem[valuesKey]) do
        table.insert(sortableTable, n)
      end
      newItem.sorted[valuesKey] = table.sort(sortableTable, function(a, b)
        local a_underscores = string.len(string.match(a, "^(_*)"))
        local b_underscores = string.len(string.match(b, "^(_*)"))

        if string.sub(a, a_underscores + 1) == string.sub(b, b_underscores + 1) and a_underscores ~= b_underscores then
          return a_underscores > b_underscores
        else
          return string.gsub(a, "^_+", "") > string.gsub(b, "^_+", "")
        end
      end)
    end
  end
  return newItem
end

local imguiInputs = {
  IntValues = function(key, value, item)
    return ImGui.InputInt("##" .. key .. item.uid, value, 1, 10)
  end,
  BoolValues = function(key, value, item)
    return ImGui.Checkbox("##" .. key .. item.uid, value)
  end,
  DataValues = function(key, value, item)
    return ImGui.InputInt("##" .. key .. item.uid, value)
  end,
  Int64Values = function(key, value, item)
    return ImGui.InputDouble("##" .. key .. item.uid, value, 10, 100, "%.0f")
  end,
  FloatValues = function(key, value, item)
    return ImGui.InputFloat("##" .. key .. item.uid, value, .01, 0.1)
  end,
  StringValues = function(key, value, item)
    return ImGui.InputText("##" .. key .. item.uid, value, 64)
  end
}

-----------------------------------------------------
--- ImGui renders
-----------------------------------------------------

hud = views.Huds.CreateHud("LootInspect", 0x06001A8A)
hud.DontDrawDefaultWindow = true
hud.Visible = true
hud.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse
hud.OnHide.Add(function()
  trackWindowState("hud")
end)
hud.OnPreRender.Add(function()
  ImGui.SetNextWindowSizeConstraints(Vector2.new(100, 100), Vector2.new(9999, 9999))
  hud.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse
end)

local filterCounter = 0
local lastFilterCount = 0

local function renderTab(item, disabled, criteriaObject, stretch)
  disabled = disabled or false
  local drawlist = ImGui.GetWindowDrawList()
  local separators = {}
  local comparators
  if not disabled then
    comparators = { "==", ">=", "<=", ">", "<", "!=" }
  end
  
  local changeMonitor=false

  local style = ImGui.GetStyle()
  local rowHeight = (ImGui.GetFontSize() + style.FramePadding.Y * 2) + style.ItemSpacing.Y + style.CellPadding.Y
  local childWindowGap = style.FramePadding.Y * 2 + style.WindowPadding.Y
  local availableHeight = ImGui.GetContentRegionAvail().Y
  local cursorStartPos = ImGui.GetCursorScreenPos()
  local childMax
  local rowCount = 0
  local separatorPadding = 0

  for _, valuesKey in ipairs(allValueStrings) do
    rowCount = rowCount + #(item.sorted[valuesKey])
    if #(item.sorted[valuesKey]) > 0 then
      separatorPadding = separatorPadding + style.SeparatorTextPadding.Y
    end
  end
  if stretch then
    childMax = Vector2.new(-1, availableHeight - rowHeight)
  else
    local innerHeight = (rowCount + (item.spells and 1 or 0)) * rowHeight
    childMax = Vector2.new(-1,
      math.min(innerHeight + childWindowGap + separatorPadding,
        availableHeight - rowHeight * (1 + lastFilterCount) - style.ItemSpacing.Y))
  end

  if ImGui.BeginChild("TableRegion", childMax, true) then
    if ImGui.BeginTable("##table" .. item.uid, (comparators and 4 or 3), _imgui.ImGuiTableFlags.Resizable) then
      ImGui.TableSetupColumn("##loot" .. item.uid, _imgui.ImGuiTableColumnFlags.WidthFixed, 20)
      ImGui.TableSetupColumn("##lootkey" .. item.uid)
      if comparators then
        ImGui.TableSetupColumn("##comparators", _imgui.ImGuiTableColumnFlags.WidthFixed, 60)
      end

      --local totalSoFar=0
      for _, valuesKey in ipairs(allValueStrings) do
        --totalSoFar=totalSoFar+1
        for i = #item.sorted[valuesKey], 1, -1 do
          local key = item.sorted[valuesKey][i]
          local keyForText = string.gsub(key, "^_+", "")
          local value = item[valuesKey][key]

          if value == nil then
            removeElement(item.sorted[valuesKey], i)
          else
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)

            local changed, newValue = ImGui.Checkbox("##lootCriteria" .. key .. i,
              criteriaObject[valuesKey][key] ~= nil or false)
            if changed then
              if newValue == true then
                criteriaObject[valuesKey][key] = value
              elseif criteriaObject == item then
                local lastKey = key
                local nextKey = "_" .. key

                while criteriaObject[valuesKey][nextKey] ~= nil do
                  criteriaObject[valuesKey][lastKey] = criteriaObject[valuesKey][nextKey]
                  criteriaObject.AndOr[lastKey] = criteriaObject.AndOr[nextKey]
                  criteriaObject.comparator[valuesKey][lastKey] = criteriaObject.comparator[valuesKey][nextKey]

                  lastKey = nextKey
                  nextKey = "_" .. lastKey
                end

                criteriaObject[valuesKey][lastKey] = nil
              else
                criteriaObject[valuesKey][key] = nil
              end
              changeMonitor=true
            end
            ImGui.BeginDisabled(disabled)

            ImGui.TableSetColumnIndex(1)
            if keyForText ~= key then
              if criteriaObject.AndOr == nil then
                criteriaObject.AndOr = {}
              end
              criteriaObject.AndOr[key] = criteriaObject.AndOr[key] or "and"
              ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding, Vector2.new(0, 0))
              if ImGui.Button(criteriaObject.AndOr[key] .. "##andOr" .. key, Vector2.new(24, 20)) then
                criteriaObject.AndOr[key] = criteriaObject.AndOr[key] == "and" and "or" or "and"
                changeMonitor=true
              end
              ImGui.PopStyleVar()
              ImGui.SameLine()
            end
            ImGui.Text(ExtraEnums[valuesKey][keyForText])
            ImGui.TableNextColumn()
            changeMonitor = comparatorRender(comparators, criteriaObject, valuesKey, key) or changeMonitor

            local combo,enumChange = enumCombo(item, valuesKey, key, value)
            if combo then
              changeMonitor = changeMonitor or enumChange
            else
              ImGui.SetNextItemWidth(-1)
              local changed, newValue = imguiInputs[valuesKey](key, value, item)
              if changed then
                criteriaObject[valuesKey][key] = newValue
                changeMonitor=true
              end
            end
            ImGui.EndDisabled()
          end
        end

        if #item.sorted[valuesKey] > 0 then
          ImGui.TableNextRow()
          ImGui.TableSetColumnIndex(0)
          local linePos = ImGui.GetCursorScreenPos()
          if linePos.Y < (cursorStartPos.Y + childMax.Y) and linePos.Y > cursorStartPos.Y then
            table.insert(separators, ImGui.GetCursorScreenPos())
          end
        end
      end

      --spells
      if item.spells then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)

        local changed, newValue = ImGui.Checkbox("##spells_lootCriteria" .. item.uid, criteriaObject.spells ~= nil)
        if changed then
          if newValue == true then
            criteriaObject.spells = item.spells
          else
            criteriaObject.spells = nil
          end
        end
        ImGui.BeginDisabled(disabled)

        ImGui.TableSetColumnIndex(1)
        ImGui.Text("Spells")
        ImGui.TableNextColumn()
        if not disabled then        -- we're in the lootEditor
          ImGui.Text("         ==") -- i'm lazy
          ImGui.TableNextColumn()
        end

        ImGui.SetNextItemWidth(-1)
        local changed, newValue = ImGui.InputText("##spells" .. item.uid, item.spells or "", 64)
        if changed then
          criteriaObject.spells = newValue
          changeMonitor=true
        end
        ImGui.EndDisabled()
      end
      ImGui.EndTable()
      local scrollbarY = ImGui.GetScrollMaxY() > 0
      ImGui.EndChild()

      local style = ImGui.GetStyle()
      for i, cursor in ipairs(separators) do
        drawlist.AddLine(cursor,
          cursor +
          Vector2.new(
            ImGui.GetWindowWidth() - (scrollbarY and style.ScrollbarSize or 0) -
            (style.FrameBorderSize * 2 - style.FramePadding.X * 3 - style.WindowPadding.X * 2) * (stretch and -1 or -1.5), -- i don't remember. seems to work. maybe clean up one day
            0),
          0xAAAAAAAA)
      end
    end
  end
  return changeMonitor
end

hud.OnRender.Add(function()
  if ImGui.Begin("Last Inspected Item", hud.WindowSettings) then

    if inspectedItem == nil then
      ImGui.Text("No items inspected yet.")
    else
      if ImGui.BeginTabBar("InspectedItemTabs") then
        if ImGui.BeginTabItem(inspectedItem.name) then
          renderTab(inspectedItem, true, inspectedItem.lootCriteria, true)
          if ImGui.Button("Template loot rule") then
            local itemCopy = copyAndSort(inspectedItem)
            itemCopy.isShown = true
            for _i, _rule in ipairs(lootRules) do
              _rule.isShown = false
            end
            table.insert(lootRules, itemCopy)
            saveLootProfile()
          end
          ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
      end
    end
    trackWindowState("hud")
    ImGui.End()
  end
end)

lootRuleHolder = views.Huds.CreateHud("*LootRuleHolder")
lootRuleHolder.DontDrawDefaultWindow = true
lootRuleHolder.Visible = true
lootRuleHolder.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse
lootRuleHolder.OnHide.Add(function()
  trackWindowState("lootRuleHolder")
end)

lootRuleHolder.OnPreRender.Add(function()
  ImGui.SetNextWindowSizeConstraints(Vector2.new(100, 100), Vector2.new(9999, 9999))
end)

local textures = {}
function GetOrCreateTexture(textureId)
  if textures[textureId] == nil then
    local texture ---@type ManagedTexture
    texture = views.Huds.GetIconTexture(textureId)
    textures[textureId] = texture
  end

  return textures[textureId]
end

function DrawIcon(item, iconId, size, func)
  local bar_position = ImGui.GetCursorScreenPos().X .. "-" .. ImGui.GetCursorScreenPos().Y

  local texture = GetOrCreateTexture(iconId)
  if not texture then return false end

  if iconId then
    if ImGui.TextureButton("##" .. bar_position .. iconId, texture, size) then
      func()
    end
  end

  return true
end

local hintText = "Right-click to rename"
lootRuleHolder.OnRender.Add(function()
  lastFilterCount = filterCounter
  filterCounter = 0
  if ImGui.Begin("Loot Rules", lootRuleHolder.WindowSettings) then
    if ImGui.BeginTable("ListTable", 1, _imgui.ImGuiTableFlags.Borders) then
      -- Table header
      ImGui.TableSetupColumn("Name", _imgui.ImGuiTableColumnFlags.WidthStretch)
      ImGui.TableHeadersRow()

      ImGui.SetCursorScreenPos(Vector2.new(ImGui.GetItemRectMax().X - ImGui.CalcTextSize(hintText).X,
        ImGui.GetItemRectMin().Y + ImGui.GetStyle().FramePadding.Y))
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, 0x77777777)
      ImGui.Text(hintText)
      ImGui.PopStyleColor()
      if ImGui.IsItemHovered() then
        hintText = ""
      end
      local changeMonitor=false
      for i, rule in ipairs(lootRules) do
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)

        local cursorPos = ImGui.GetCursorScreenPos()
        local isClicked

        if rule.isRenaming then
          -- Directly editing the name inline
          ImGui.SetKeyboardFocusHere()
          local changed, newValue = ImGui.InputText("##editLootRuleName" .. rule.uid, rule.name, 64,
            _imgui.ImGuiInputTextFlags.EnterReturnsTrue)
          if changed and newValue ~= "" then
            rule.name = newValue
            changeMonitor=true
          end

          -- When the user presses Enter, or if the input loses focus, stop editing
          if changed or ImGui.IsItemDeactivated() then
            rule.isRenaming = false
          end
        else
          local buttonSize = Vector2.new(18, 18)
          isClicked = ImGui.Selectable(rule.name .. "##" .. rule.uid, false, _imgui.ImGuiSelectableFlags.AllowOverlap,
            Vector2.new(ImGui.GetColumnWidth(), ImGui.GetFrameHeight()))

          if ImGui.IsItemHovered() and ImGui.IsMouseReleased(_imgui.ImGuiMouseButton.Right) then -- 1 is the right-click button
            rule.isRenaming = true                                   -- Trigger the renaming mode
          elseif ImGui.IsItemHovered() and ImGui.IsMouseReleased(_imgui.ImGuiMouseButton.Middle) then
            rule.disabled = not rule.disabled
          elseif rule.isShown then
            local barOptions = Vector2.new(ImGui.GetItemRectMax().X - 3 * buttonSize.X - ImGui.GetStyle().FramePadding.X,
              ImGui.GetItemRectMax().Y - ImGui.GetItemRectSize().Y + ImGui.GetStyle().FramePadding.Y)
            ImGui.SetCursorScreenPos(barOptions)
            ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, Vector2.new(0, ImGui.GetStyle().ItemInnerSpacing.Y))
            ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemSpacing, Vector2.new(0, 0))

            DrawIcon(rule, 0x060028FC, buttonSize, function()
              moveElementUp(lootRules, i)
              changeMonitor=true
            end)

            ImGui.SameLine(0)
            DrawIcon(rule, 0x060028FD, buttonSize, function()
              moveElementDown(lootRules, i)
              changeMonitor=true
            end)

            if ImGui.GetIO().KeyCtrl then
              ImGui.SameLine(0)
              DrawIcon(rule, 0x0600606E, buttonSize, function()
                removeElement(lootRules, i)
                changeMonitor=true
              end)
            else
              ImGui.SameLine(0)
              DrawIcon(rule, 0x060069EA, buttonSize, function()
                local ruleCopy = copyAndSort(rule)
                ruleCopy.isShown = true
                for _i, _rule in ipairs(lootRules) do
                  _rule.isShown = false
                end
                table.insert(lootRules, ruleCopy)
                changeMonitor=true
              end)
            end

            ImGui.PopStyleVar(2)
          end
          if rule.disabled then
            local textStart = Vector2.new(cursorPos.X,cursorPos.Y + ImGui.GetFontSize()/2)
            local textEnd = Vector2.new(textStart.X+ImGui.CalcTextSize(rule.name).X,textStart.Y)
            ImGui.GetWindowDrawList().AddLine(textStart,textEnd,0xFFFFFFFF)
          end
        end

        -- If clicked or rule is shown, render the content
        if isClicked then
          rule.isShown = not rule.isShown
          if rule.isShown then
            for _i, _rule in ipairs(lootRules) do
              if _rule ~= rule then
                _rule.isShown = false
              end
            end
          end
        end
        if rule.isShown then
          local tabChange = renderTab(rule, false, rule)
          changeMonitor = changeMonitor or tabChange

          rule.filter = rule.filter or "" -- Initialize filter
          local changed, newValue = ImGui.InputText("Search enums", rule.filter, 64)
          if changed then
            rule.filter = newValue
          end

          -- Loop through each ComboBox
          for idx, itemList in ipairs(sortedEnums) do
            local enumName = allEnums[idx]
            local valuesKey = allValueStrings[idx]
            local defaultValue = enumDefault[idx]
            -- Set default if rule[enumName] doesn't exist
            rule[enumName] = rule[enumName] or 1 -- Default to 1 if not set, or another fallback value

            -- Filter items based on the rule.filter
            local filteredItems = {}
            for e, item in ipairs(itemList) do
              if string.match(string.lower(tostring(item)), string.lower(rule.filter)) then
                table.insert(filteredItems, item)
              end
            end

            -- Only render the ComboBox if there are any matching items
            if #filteredItems > 0 then
              filterCounter = filterCounter + 1

              -- Ensure the selected item is valid in the filtered list
              local selectedIdx = rule[enumName]
              if selectedIdx < 1 then selectedIdx = 1 end
              if selectedIdx > #filteredItems then selectedIdx = #filteredItems end

              -- Begin ComboBox with the selected item
              if ImGui.BeginCombo(enumName .. "##" .. idx, filteredItems[selectedIdx]) then
                for e, item in ipairs(filteredItems) do
                  local isSelected = (selectedIdx == e)
                  if ImGui.Selectable(item, isSelected) then
                    rule[enumName] = e -- Update rule[enumName] to the selected index
                    local key = tostring(item)
                    if lootRules[i][valuesKey][key] == nil then
                      lootRules[i][valuesKey][key] = defaultValue
                    else
                      -- Find the next available underscored key
                      local nextKey = key
                      while lootRules[i][valuesKey][nextKey] ~= nil do
                        nextKey = "_" .. nextKey
                      end
                      lootRules[i][valuesKey][nextKey] = deepcopy(lootRules[i][valuesKey][key])
                    end
                    lootRules[i] = copyAndSort(lootRules[i])
                    changeMonitor=true
                  end
                end
                ImGui.EndCombo()
              end
            end
          end
        end
      end
      if changeMonitor then
        saveLootProfile()
      end
      ImGui.EndTable()
    end
  end
  trackWindowState("lootRuleHolder")
  ImGui.End()
end)

loadWindowData()
loadLootProfile()
