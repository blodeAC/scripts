local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local views = require("utilitybelt.views")
local io = require("filesystem").GetScript()

local inspectedItem
local inspectQueue = {}
local hud            -- main window
local lootRuleHolder --loot rule window
local testMode = false
local appraisedItems = setmetatable({}, {
  __index = function(t, k)
    return rawget(t, k)  -- Ensures retrieval works
  end
})

local buildItem
local copyAndSort

local function scanInventory()
  for i,invItem in ipairs(game.Character.Inventory) do
    if not invItem.HasAppraisalData then
      if not appraisedItems[invItem.Id] then
        appraisedItems[invItem.Id]={}
        game.Actions.ObjectAppraise(invItem.Id)
      end
    elseif appraisedItems[invItem]==nil then
      buildItem(invItem.Id)
    end
  end
end

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

local function generateUid()
  return tostring(os.time()) .. string.gsub(tostring(os.clock()), "%.", "")
end

-----------------------------------------------------
--- enum stuff
-----------------------------------------------------

local allValueStrings = { "IntValues", "BoolValues", "DataValues", "Int64Values", "FloatValues", "StringValues" }
local allEnums = { "IntId", "BoolId", "DataId", "Int64Id", "FloatId", "StringId" }
local enumDefault = { 1, false, 1, 1, 1.0, "" }

require("DaraletGlobals")


-- List of all available values loot can be qualified by
local sortedEnums = {}
for i, enum in ipairs(allEnums) do
  local sorted = table.sort(_G[enum].GetValues(), function(a, b)
    return tostring(a) < tostring(b)
  end)
  for _, extra in ipairs(ExtraEnums[allValueStrings[i]]) do
    ---@diagnostic disable-next-line
    table.insert(sorted, extra)
  end
  table.insert(sortedEnums, sorted)
end
for i,val in ipairs(sortedEnums[6]) do
  if val=="HeritageGroup" then
    removeElement(sortedEnums[6],i)
    break
  end
end
-- Definition for different values of WieldRequirements
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
        return name
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

-- Keys that can be presented as ImGui ComboBox entries
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
--- events
-----------------------------------------------------

local lootRules = {}

-- Test inspected item against rules generated by user
local function evaluateLoot(item,lootRuleOverride)
  for i, ruleItem in ipairs(lootRuleOverride or lootRules) do
    if ruleItem.disabled then
      -- print("skipping "..ruleItem.name)
    else
      local lootable = true
      for _, keyValue in ipairs(allValueStrings) do
        if lootable then
          if not ruleItem.sorted then
            ruleItem = copyAndSort(ruleItem)
          end
          local failedOrs = {}
          for j = #ruleItem.sorted[keyValue], 1, -1 do
            local key = ruleItem.sorted[keyValue][j]
            local keyForCompare = string.gsub(key, "^_+", "")
            local itemValue = item[keyValue][keyForCompare]
            if itemValue == nil then
              lootable = false -- If the item doesn't have the property, it doesn't match
            else
              local comparator = ruleItem.comparator[keyValue] and ruleItem.comparator[keyValue][key] or "=="
              local ruleValue = ruleItem[keyValue][key]
              local function andOrParser() -- if we're here, it failed this and/or condition
                if ruleItem.AndOr[keyForCompare]=="or" then
                  failedOrs[keyForCompare]=(failedOrs[keyForCompare] or 0) + 1
                end
                if ruleItem.AndOr[keyForCompare]==nil then -- no and/or, so failure
                  return true
                elseif ruleItem.AndOr[keyForCompare]=="or" and not ruleItem.comparator[keyValue]["_"..key] then
                  local len = string.len(string.match(key, "^(_*)"))
                  if failedOrs[keyForCompare] and failedOrs[keyForCompare]-len==1 then
                    return true
                  end
                elseif ruleItem.AndOr[keyForCompare]=="and" then
                  return true
                end
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
      if ruleItem.spells~="" and not Regex.IsMatch(item.spells or "", ruleItem.spells or "") then
        lootable = false
      end
      if lootable then
        if ruleItem.keepCount and ruleItem.keepCount>-1 and not lootRuleOverride then
          local count=0
          for i,invItem in ipairs(game.Character.Inventory) do
            count = count + (evaluateLoot(appraisedItems[invItem.Id],{ruleItem})~=false and 1 or 0)
          end
          print(count)
          if count>=ruleItem.keepCount then
            return false
          end
        end
        return ruleItem
      end
    end
  end

  return false
end

local lootActionOptions = ActionOptions.new()
lootActionOptions.MaxRetryCount = 10
lootActionOptions.SkipChecks = true

local function loot(itemData,winningLootRule,weenie)
  local actionQueueCount=0
  for _ in game.ActionQueue.ImmediateQueue do
    actionQueueCount = actionQueueCount+1
  end
  for _ in game.ActionQueue.Queue do
    actionQueueCount = actionQueueCount+1
  end

  lootActionOptions.TimeoutMilliseconds = actionQueueCount*1000
  game.Actions.ObjectMove(itemData.id, game.CharacterId, 0, true, lootActionOptions, 
  function(objectMoveAction)
    if objectMoveAction.Success then
      if weenie.Value(BoolId.Inscribable) then
        weenie.Inscribe(winningLootRule.name)
      end
      winningLootRule.totalFound = (winningLootRule.totalFound or 0)+ 1
    else
      print("Failed to loot \"" .. weenie.Nameo .. "\":"..objectMoveAction.ErrorDetails)
    end
  end)
end

-- Generate itemdata for each inspected object and loot, if on opened corpse
function buildItem(e)
  local objectId = type(e)~="number" and e.Data.ObjectId or e
  
  local weenie = game.World.Get(objectId)

  if not weenie then
    return
  end

  local itemData = {
    uid = generateUid(),
    id = objectId,
    name = weenie.Name,
    lootCriteria = {
      IntValues = {},
      BoolValues = {},
      DataValues = {},
      Int64Values = {},
      FloatValues = {},
      StringValues = {},
    },
    AndOr = {}
  }

  for i, spellId in ipairs(weenie.SpellIds) do
    itemData.spells = (itemData.spells or "") .. game.Character.SpellBook.Get(spellId.Id).Name .. ","
  end
  if itemData.spells~=nil and string.len(itemData.spells) > 0 then
    itemData.spells = string.sub(itemData.spells, 1, -2)
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
  itemData.StringValues["HeritageGroup"]=nil

  appraisedItems[objectId]=itemData

  if (game.World.Selected ~= nil and game.World.Selected.Id == objectId) then
    inspectedItem = itemData
    if testMode then
      local winningLootRule = evaluateLoot(itemData)
      if winningLootRule then
        print(weenie.Name .. " will be looted by rule: " .. winningLootRule.name)
      else
        print(weenie.Name .. " won't be looted: no matching rule")
      end
    end
  end

  for l = #inspectQueue, 1, -1 do
    if inspectQueue[l] == itemData.id then
      local winningLootRule = evaluateLoot(itemData)
      if winningLootRule then
        loot(itemData,winningLootRule,weenie)
      end
      removeElement(inspectQueue, l)
    end
  end
end
game.Messages.Incoming.Item_SetAppraiseInfo.Add(buildItem)

game.World.OnContainerOpened.Add(function(containerOpenedEvent)
  if containerOpenedEvent.Container.ObjectClass == ObjectClass.Corpse or containerOpenedEvent.Container.Name == "Corpse" then
    local weenie = game.World.Get(containerOpenedEvent.Container.Id)
    for i, itemid in ipairs(weenie.AllItemIds) do
      table.insert(inspectQueue, itemid)
      game.Actions.ObjectAppraise(itemid)
    end
  end
end)


-----------------------------------------------------
--- Profile Saving
-----------------------------------------------------

local windowData = {} -- Stores window states
local windows         -- Store windows (later)
local windowSaveFile = "window_config.json"
local lootSaveFile = "loot.json"

-- Deepcopy item to maintain inspected state for reference
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

-- Prettyprint JSON before saving to file
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
    if items ~= {} then
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

-- Load previous window data
local function loadWindowData()
  windows = { hud = hud, lootRuleHolder = lootRuleHolder }
  local files = io.FileExists(windowSaveFile)
  if files then
    local content = io.ReadText(windowSaveFile)
    windowData = json.parse(content) or {}
    for key, window in pairs(windowData) do
      if not window.isVisible then
        windows[key].Visible = false
      end
      local prerender
      function prerender()
        ImGui.SetNextWindowPos(Vector2.new(window.posX, window.posY))
        ImGui.SetNextWindowSize(Vector2.new(window.sizeX, window.sizeY))
        windows[key].OnPreRender.Remove(prerender)
      end

      windows[key].OnPreRender.Add(prerender)
    end
  end
end

-- Save updated window data
local function saveWindowData()
  io.WriteText(windowSaveFile, prettyPrintJSON(windowData))
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

-- Load loot rules based on charactername and server
local function loadLootProfile(server, character)
  server = server or game.ServerName
  character = character or game.Character.Weenie.Name

  local files = io.FileExists(lootSaveFile)
  if files then
    local content = io.ReadText(lootSaveFile)
    local settings = json.parse(content)
    if settings and settings[server] and settings[server][character] then
      lootRules = settings[server][character]

      for i, rule in ipairs(lootRules) do
        lootRules[i] = copyAndSort(rule)
      end
    else
      return "No settings found for server or character."
    end
  end
end

-- Save loot profile when change to lootrules object detected
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
  
  for i, _ in ipairs(lootProfiles[server][character]) do
    local rule = lootProfiles[server][character][i] 
    rule.sorted = nil
    for _, key in ipairs(allValueStrings) do
      rule[key] = nil
    end
    for _, key in ipairs(allEnums) do
      rule[key] = nil
    end
    rule.isRenaming = nil
    rule.isShown = nil
    rule.filter = nil
  end

  -- Save back to the file
  io.WriteText(lootSaveFile, prettyPrintJSON(lootProfiles))
end

-----------------------------------------------------
--- ImGui helpers
-----------------------------------------------------
local bit = require("bit")
local enumCache = {}
local enumValuesCache = {}

-- Render comparators for a given loot rule
local function comparatorRender(comparators, criteriaObject, valuesKey, key)
  local changeMonitor = false
  if comparators then
    if criteriaObject[valuesKey] and criteriaObject[valuesKey][key] then
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
            changeMonitor = true
          end
          if isSelected then
            ImGui.SetItemDefaultFocus()
          end
        end
        ImGui.EndCombo()
      end
      ImGui.TableNextColumn()
    end
  end
  return changeMonitor
end

-- Cache enum.GetValues() calls
local function getEnumValues(enum)
  if not enumValuesCache[enum] then
    enumValuesCache[enum] = enum.GetValues()
  end
  return enumValuesCache[enum]
end

-- Cache combobox enums
local function getEnum(valueTable, keyForText, item)
  local cacheKey = valueTable .. "_" .. keyForText .. "_" .. item.uid
  if not enumCache[cacheKey] then
    local enum
    if valueTable == "IntValues" then
      enum = enumMasks[ExtraEnums.IntValues[keyForText]] or _G[tostring(keyForText)]
    else
      enum = enumMasks[tostring(keyForText)] or _G[tostring(keyForText)]
    end

    if type(enum) == "function" then
      local globalVal = enum(item)
      if globalVal then
        enum = _G[globalVal] or nil
      end
    end
    enumCache[cacheKey] = enum
  end
  return enumCache[cacheKey]
end

-- Determine if a key is contains selectable enum properties (e.g. ObjectType)
local function enumCombo(item, valueTable, key, value)
  local keyForText = string.gsub(key, "^_+", "")
  local changeMonitor = false

  local enum = getEnum(valueTable, keyForText, item)

  if enum ~= nil then
    ImGui.SetNextItemWidth(-1)
    local currentEnumName = tostring((type(enum) ~= "function" and enum[value]) or
      (enum.FromValue and enum.FromValue(value)) or value)

    local enumValues = getEnumValues(enum)
    local enumSize = #enumValues
    local bitmaskOffset = 1

    local isMask = false
    for _, mask in ipairs({ "EquipMask", "AttributeMask", "AttributeMask", "ClothingPriority", "DamageType", "ValidLocations", "CurrentWieldedLocation" }) do
      if keyForText == mask then
        isMask = true
        break
      end
    end

    if isMask then
      for j = 1, enumSize do
        if enum.FromValue(j) == enumValues[1] then
          bitmaskOffset = j
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
            changeMonitor = true
          end
        else
          local enumName = enumValues[i]
          local isSelected = (currentEnumName == tostring(enumName))
          if ImGui.Selectable(tostring(enumName), isSelected) then
            local ev = enum[tostring(enumName)]
            item[valueTable][key] = type(ev)=="userdata" and ev.ToNumber() or ev
            changeMonitor = true
          end
          if isSelected then
            ImGui.SetItemDefaultFocus()
          end
        end
      end
      ImGui.EndCombo()
    end
    return true, changeMonitor
  end

  return false, changeMonitor
end

-- Reinitiale saved loot rules or convert templated item to loot rule
copyAndSort = function(item)
  local comparator = (item.comparator and deepcopy(item.comparator)) or {}

  local newItem = deepcopy(item)
  newItem.uid = generateUid()
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

-- ImGui input type determined by value type
local imguiInputs = {
  IntValues = function(key, value, item, disabled)
    return ImGui.InputInt("##" .. key .. item.uid, value, 1, 10)
  end,
  BoolValues = function(key, value, item, disabled)
    return ImGui.Checkbox("##" .. key .. item.uid, value)
  end,
  DataValues = function(key, value, item, disabled)
    return ImGui.InputInt("##" .. key .. item.uid, value)
  end,
  Int64Values = function(key, value, item, disabled)
    return ImGui.InputDouble("##" .. key .. item.uid, value, 10, 100, "%.0f")
  end,
  FloatValues = function(key, value, item, disabled)
    return ImGui.InputFloat("##" .. key .. item.uid, value, .01, 0.1)
  end,
  StringValues = function(key, value, item, disabled)
    if disabled then
      local availX = ImGui.GetWindowContentRegionMax().X
      ImGui.PushTextWrapPos(availX)
      ImGui.TextWrapped(string.gsub(value,"%%","%%%%"))
      ImGui.PopTextWrapPos()
      return false, false
    else
      return ImGui.InputText("##" .. key .. item.uid,value,144)
    end
  end
}

-----------------------------------------------------
--- ImGui renders
-----------------------------------------------------

-- Create main inspection window
hud = views.Huds.CreateHud("LootInspect", 0x06001A8A)
hud.Visible = true
hud.OnHide.Add(function()
  trackWindowState("hud")
end)
hud.OnPreRender.Add(function()
  ImGui.SetNextWindowSizeConstraints(Vector2.new(100, 100), Vector2.new(9999, 9999))
end)


local filterCounter = 0
local lastFilterCount = 0

-- Render inspected item or loot rule. disabled = true for inspected item, nil for loot rule
local function renderTab(item, criteriaObject, disabled)
  disabled = disabled or false
  local drawlist = ImGui.GetWindowDrawList()
  local separators = {}
  local comparators = not disabled and { "==", ">=", "<=", ">", "<", "!=" }
  local changeMonitor = false

  local style = ImGui.GetStyle()
  local rowHeight = (ImGui.GetFontSize() + style.FramePadding.Y * 2) + style.ItemSpacing.Y + style.CellPadding.Y
  local childWindowGap = style.WindowPadding.Y
  local availableHeight = ImGui.GetContentRegionAvail().Y
  local cursorStartPos = ImGui.GetCursorScreenPos()
  local childMax
  local childScreenMax

  local rowCount = 0
  local separatorPadding = 0
  for _, valuesKey in ipairs(allValueStrings) do
    rowCount = rowCount + #(item.sorted[valuesKey])
    if #(item.sorted[valuesKey]) > 0 then
      separatorPadding = separatorPadding + style.SeparatorTextPadding.Y
    end
  end

  if item.spells then
    rowCount = rowCount + 1
  end

  if disabled then
    childMax = Vector2.new(-1, availableHeight - rowHeight)
  else
    local innerHeight = rowCount * rowHeight
    childMax = Vector2.new(-1,
      math.min(innerHeight + childWindowGap + style.ItemSpacing.Y,
        availableHeight - rowHeight * (1 + lastFilterCount) - style.ItemSpacing.Y))
    if childMax.Y<0 then 
      childMax.Y=1
    end
  end

  if ImGui.BeginChild("TableRegion", childMax, true) then
    childScreenMax = ImGui.GetWindowContentRegionMax()

    ImGui.Dummy(Vector2.new(0, (rowCount - 1) * rowHeight)) -- Maintain scroll height
    local scrollY = ImGui.GetScrollY()
    local visibleStartRow = math.max(0, math.floor(scrollY / rowHeight))
    local visibleEndRow = math.min(rowCount, visibleStartRow + math.ceil(availableHeight / rowHeight))
    ImGui.SetCursorPosY(visibleStartRow * rowHeight + style.ItemSpacing.Y)

    if ImGui.BeginTable("##table" .. item.uid, (comparators and 4 or 3), _imgui.ImGuiTableFlags.Resizable) then
      ImGui.TableSetupColumn("##loot" .. item.uid, _imgui.ImGuiTableColumnFlags.WidthFixed, 20)
      ImGui.TableSetupColumn("##lootkey" .. item.uid)
      if comparators then
        ImGui.TableSetupColumn("##comparators", _imgui.ImGuiTableColumnFlags.WidthFixed, 60)
      end

      local currentRow = 0

      for _, valuesKey in ipairs(allValueStrings) do
        local isFirstInCategory = true
        for i = #item.sorted[valuesKey], 1, -1 do
          if currentRow >= visibleStartRow and currentRow <= visibleEndRow then
            local key = item.sorted[valuesKey][i]
            local keyForText = string.gsub(key, "^_+", "")
            local value = item[valuesKey][key]

            if value ~= nil then
              if isFirstInCategory and #item.sorted[valuesKey] > 0 then
                if currentRow > 0 then
                  ImGui.TableNextRow()
                  ImGui.TableSetColumnIndex(0)
                  local linePos = ImGui.GetCursorScreenPos()
                  if linePos.Y < (cursorStartPos.Y + childMax.Y) and linePos.Y > cursorStartPos.Y then
                    table.insert(separators, ImGui.GetCursorScreenPos())
                  end
                end
                isFirstInCategory = false
              end

              ImGui.TableNextRow()
              ImGui.TableSetColumnIndex(0)
              local changed, newValue = ImGui.Checkbox("##lootCriteria" .. key .. i,
                criteriaObject[valuesKey][key] ~= nil or false)
              if changed then
                if newValue then
                  criteriaObject[valuesKey][key] = value
                elseif criteriaObject==item then
                  local lastKey = key
                  local nextKey = "_" .. key
                  
                  while criteriaObject[valuesKey][nextKey] ~= nil do
                    criteriaObject[valuesKey][lastKey]=criteriaObject[valuesKey][nextKey]
                    --criteriaObject.AndOr[lastKey]=criteriaObject.AndOr[nextKey]
                    criteriaObject.comparator[valuesKey][lastKey] = criteriaObject.comparator[valuesKey][nextKey]
                    
                    lastKey = nextKey  
                    nextKey = "_" .. lastKey
                  end
                  
                  criteriaObject[valuesKey][lastKey] = nil
                  --criteriaObject.AndOr[lastKey] = nil
                  criteriaObject.comparator[valuesKey][lastKey] = nil                  
                else
                  criteriaObject[valuesKey][key] = nil
                  if comparators then
                    criteriaObject.comparator[valuesKey][key] = nil
                  end
                end
                changeMonitor = true
              end

              ImGui.BeginDisabled(disabled)
              ImGui.TableSetColumnIndex(1)

              if keyForText ~= key and criteriaObject[valuesKey][key] then
                criteriaObject.AndOr[keyForText] = criteriaObject.AndOr[keyForText] or "and"
                ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding, Vector2.new(0, 0))
                if ImGui.Button(criteriaObject.AndOr[keyForText] .. "##andOr" .. key, Vector2.new(24, 20)) then
                  criteriaObject.AndOr[keyForText] = criteriaObject.AndOr[keyForText] == "and" and "or" or "and"
                  changeMonitor = true
                end
                ImGui.PopStyleVar()
                ImGui.SameLine()
              end

              ImGui.Text(ExtraEnums[valuesKey][keyForText])
              ImGui.TableNextColumn()
              changeMonitor = comparatorRender(comparators, criteriaObject, valuesKey, key) or changeMonitor

              local combo, enumChange = enumCombo(item, valuesKey, key, value)
              if combo then
                changeMonitor = changeMonitor or enumChange
              else
                ImGui.SetNextItemWidth(-1)
                local changed, newValue = imguiInputs[valuesKey](key, value, item, disabled)
                if changed then
                  criteriaObject[valuesKey][key] = newValue
                  changeMonitor = true
                end
              end
              ImGui.EndDisabled()
            else
              removeElement(item.sorted[valuesKey], i)
            end
          end
          currentRow = currentRow + 1
        end
      end

      if item.spells and currentRow >= visibleStartRow and currentRow <= visibleEndRow then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local changed, newValue = ImGui.Checkbox("##spells_lootCriteria" .. item.uid, criteriaObject.spells~=nil)
        if changed then
          if newValue == true then
            criteriaObject.spells = item.spells or ""
          else
            criteriaObject.spells = nil
          end
          changeMonitor = true
        end

        ImGui.BeginDisabled(disabled)
        ImGui.TableSetColumnIndex(1)
        ImGui.Text("Spells")
        ImGui.TableNextColumn()

        if not disabled then 
          ImGui.Text("         ==")
          ImGui.TableNextColumn()
        end

        ImGui.SetNextItemWidth(-1)
        local changed, newValue = ImGui.InputText("##spells" .. item.uid, item.spells or "", 144)
        if changed then
          criteriaObject.spells = newValue
          changeMonitor = true
        end
        ImGui.EndDisabled()
      end

      ImGui.EndTable()
      ImGui.EndChild()

      local style = ImGui.GetStyle()
      for i, cursor in ipairs(separators) do
        drawlist.AddLine(Vector2.new(cursor.X - style.WindowPadding.X, cursor.Y),
          cursor + Vector2.new(childScreenMax.X, 0), 0xAAAAAAAA)
      end
    end
  end
  return changeMonitor
end

local importIndex=0
local importProfile

---@type string[]
local availableToImport={}

local function populateImport()
  local files = io.FileExists(lootSaveFile)
  if files then
    local content = io.ReadText(lootSaveFile)
    local settings = json.parse(content)
    for server,characterTable in pairs(settings) do
      for name,charSettings in pairs(characterTable) do
        table.insert(availableToImport,server .. " > " .. name)
        if name == game.Character.Weenie.Name then
          importIndex = #availableToImport-1
        end
      end
    end
  end
end
populateImport()

-- Render main inspection window
hud.OnRender.Add(function()
  if inspectedItem == nil then
    ImGui.Text("No items inspected yet.")
  else
    if ImGui.BeginTabBar("InspectedItemTabs") then
      local start = ImGui.GetWindowPos()+ImGui.GetWindowContentRegionMin()

      local checkBoxSize = Vector2.new(18, 18)
      local testModeLabelText = "TestMode"
      ImGui.SetCursorScreenPos(start + Vector2.new(ImGui.GetContentRegionMax().X-checkBoxSize.X*2-ImGui.CalcTextSize(testModeLabelText).X,0))

      if ImGui.Checkbox(testModeLabelText, testMode) then
        testMode = not testMode
        if testMode then
          print("TestMode enabled. Selected inspection item will print matching rule.")
        else
          print("TestMode disabled.")
        end
      end
      if ImGui.BeginTabItem(inspectedItem.name) then
        renderTab(inspectedItem, inspectedItem.lootCriteria, true)
        if ImGui.Button("Template loot rule") then
          local itemCopy = copyAndSort(inspectedItem)
          itemCopy.isShown = true
          for _i, _rule in ipairs(lootRules) do
            _rule.isShown = false
          end
          itemCopy.uid = generateUid()
          table.insert(lootRules, itemCopy)
          saveLootProfile()
        end
        local buttonSize=ImGui.GetItemRectSize()
        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX()+buttonSize.X)
        ImGui.SetNextItemWidth(ImGui.GetContentRegionMax().X - (ImGui.GetCursorScreenPos().X-ImGui.GetWindowPos().X)*2.5)
        local changed,newCharIndex = ImGui.Combo("##importServerCharacter",importIndex,availableToImport,#availableToImport)
        if changed then
          importIndex=newCharIndex or 0 --??
          importProfile=string.gsub(availableToImport[newCharIndex+1]," > ",",")
        end
        ImGui.SameLine()
        if ImGui.Button("Import Settings##importsettings",buttonSize) then
          local server, character = importProfile:match("([^,]+),([^,]+)")
          loadLootProfile(server,character)
          saveLootProfile()
        end

        ImGui.EndTabItem()
      end
      ImGui.EndTabBar()
    end

  end
  trackWindowState("hud")
end)

-- Create loot rules window
lootRuleHolder = views.Huds.CreateHud("*LootRuleHolder")
lootRuleHolder.Visible = true
lootRuleHolder.OnHide.Add(function()
  trackWindowState("lootRuleHolder")
end)

lootRuleHolder.OnPreRender.Add(function()
  local style = ImGui.GetStyle()
  local rowHeight = (ImGui.GetFontSize() + style.FramePadding.Y * 2) + style.ItemSpacing.Y + style.CellPadding.Y
  ImGui.SetNextWindowSizeConstraints(Vector2.new(100, 100+rowHeight*#lootRules), Vector2.new(9999, 9999))
end)

local textures = {}
-- Cache textures for loot rule buttons
function GetOrCreateTexture(textureId)
  if textures[textureId] == nil then
    local texture ---@type ManagedTexture
    texture = views.Huds.GetIconTexture(textureId)
    textures[textureId] = texture
  end

  return textures[textureId]
end

-- Draw texture for loot rule buttons
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

local lastFilterSet = {}  -- Cache filters to reduce looping through all enums
local hintText = "Right-click to rename"
lootRuleHolder.OnRender.Add(function()
  lastFilterCount = filterCounter
  filterCounter = 0
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
    local changeMonitor = false
    for i, rule in ipairs(lootRules) do
      ImGui.TableNextRow()
      ImGui.TableSetColumnIndex(0)

      local cursorPos = ImGui.GetCursorScreenPos()
      local isClicked

      local barOptions
      if rule.isRenaming then
        -- Directly editing the name inline
        ImGui.SetKeyboardFocusHere()
        local changed, newValue = ImGui.InputText("##editLootRuleName" .. rule.uid, rule.name, 64,
          _imgui.ImGuiInputTextFlags.EnterReturnsTrue)
        if changed and newValue ~= "" then
          rule.name = newValue
          changeMonitor = true
        end

        -- When the user presses Enter, or if the input loses focus, stop editing
        if changed or ImGui.IsItemDeactivated() then
          rule.isRenaming = false
        end
      else
        
        local buttonSize = Vector2.new(18, 18)
        isClicked = ImGui.Selectable(rule.name .. "##" .. i, false, _imgui.ImGuiSelectableFlags.AllowOverlap,
          Vector2.new(ImGui.GetColumnWidth(), ImGui.GetFrameHeight()))

        if ImGui.IsItemHovered() and ImGui.IsMouseReleased(_imgui.ImGuiMouseButton.Right) then -- 1 is the right-click button
          rule.isRenaming = true                                                               -- Trigger the renaming mode
        elseif ImGui.IsItemHovered() and ImGui.IsMouseReleased(_imgui.ImGuiMouseButton.Middle) then
          rule.disabled = not rule.disabled
          changeMonitor = true
        elseif rule.isShown then
          barOptions = Vector2.new(ImGui.GetItemRectMax().X - 3 * buttonSize.X - ImGui.GetStyle().FramePadding.X,
            ImGui.GetItemRectMax().Y - ImGui.GetItemRectSize().Y + ImGui.GetStyle().FramePadding.Y)
          
          local keepPosition = barOptions - Vector2.new(ImGui.CalcTextSize("Keep").X+50+15,0)
          ImGui.SetCursorScreenPos(keepPosition)
          ImGui.Text("Keep")
          ImGui.SameLine()

          ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding,Vector2.new(1,1))
          ImGui.SetNextItemWidth(25)
          local changed, newValue = ImGui.InputText("##keep"..i,tostring(rule.keepCount or -1),3,_imgui.ImGuiInputTextFlags.CharsDecimal + _imgui.ImGuiInputTextFlags.EnterReturnsTrue)
          if changed then
            if tonumber(newValue) then
              rule.keepCount = tonumber(newValue)
            else
              rule.keepCount = rule.keepCount or -1
            end
          end
          ImGui.PopStyleVar()

          ImGui.SetCursorScreenPos(barOptions)
          ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, Vector2.new(0, ImGui.GetStyle().ItemInnerSpacing.Y))
          ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemSpacing, Vector2.new(0, 0))

          DrawIcon(rule, 0x060028FC, buttonSize, function()
            moveElementUp(lootRules, i)
            changeMonitor = true
          end)

          ImGui.SameLine(0)
          DrawIcon(rule, 0x060028FD, buttonSize, function()
            moveElementDown(lootRules, i)
            changeMonitor = true
          end)

          if ImGui.GetIO().KeyCtrl then
            ImGui.SameLine(0)
            DrawIcon(rule, 0x0600606E, buttonSize, function()
              removeElement(lootRules, i)
              changeMonitor = true
            end)
          else
            ImGui.SameLine(0)
            DrawIcon(rule, 0x060069EA, buttonSize, function()
              local ruleCopy = copyAndSort(rule)
              ruleCopy.isShown = true
              for _i, _rule in ipairs(lootRules) do
                _rule.isShown = false
              end
              ruleCopy.uid = tostring(os.time()) .. tostring(os.clock()):gsub("%.", "")
              table.insert(lootRules, ruleCopy)
              changeMonitor = true
            end)
          end

          ImGui.PopStyleVar(2)
        end
        if rule.disabled then
          local textStart = Vector2.new(cursorPos.X, cursorPos.Y + ImGui.GetFontSize() / 2)
          local textEnd = Vector2.new(textStart.X + ImGui.CalcTextSize(rule.name).X, textStart.Y)
          ImGui.GetWindowDrawList().AddLine(textStart, textEnd, 0xFFFFFFFF)
        end
      end
      
      if rule.totalFound==nil then rule.totalFound=0 end
      if not rule.isShown then
        ImGui.SetCursorScreenPos(cursorPos+Vector2.new(ImGui.GetColumnWidth()-ImGui.CalcTextSize(tostring(rule.totalFound)).X,0))
        ImGui.Text(tostring(rule.totalFound))
      elseif barOptions~=nil then
        ImGui.SetCursorScreenPos(barOptions-Vector2.new(ImGui.CalcTextSize(tostring(rule.totalFound)).X+5,0))
        ImGui.Text(tostring(rule.totalFound))
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
        local tabChange = renderTab(rule, rule, false)   -- render loot rule with item and criteriaObject as same
        changeMonitor = changeMonitor or tabChange

        if ImGui.Button("Add Spells") then
          rule.spells=""
        end
        ImGui.SameLine()

        rule.filter = rule.filter or "" -- Initialize filter
        local changed, newValue = ImGui.InputText("Search enums", rule.filter, 64)
        if changed then
          rule.filter = newValue
          lastFilterSet = {}
          for idx, itemList in ipairs(sortedEnums) do
            local enumId = allEnums[idx]
            -- Set default if rule[enumName] doesn't exist
            rule[enumId] = rule[enumId] or 1 -- Default to 1 if not set, or another fallback value, this is the sort index

            table.insert(lastFilterSet,{})
            -- Filter items based on the rule.filter
            for e, enumInList in ipairs(itemList) do
              if string.match(string.lower(tostring(enumInList)), string.lower(rule.filter)) then
                table.insert(lastFilterSet[idx], enumInList)
              end
            end
          end
        end

        if rule.filter ~= "" then
          -- Loop through each ComboBox
          for idx, itemList in ipairs(sortedEnums) do
            local enumName = allEnums[idx]
            local valuesKey = allValueStrings[idx]
            local defaultValue = enumDefault[idx]

            -- Only render the ComboBox if there are any matching items
            if lastFilterSet[idx] and  #lastFilterSet[idx] > 0 then
              filterCounter = filterCounter + 1

              -- Ensure the selected item is valid in the filtered list
              local selectedIdx = rule[enumName]
              if selectedIdx == nil or selectedIdx < 1 then selectedIdx = 1 end
              if selectedIdx > #lastFilterSet[idx] then selectedIdx = #lastFilterSet[idx] end

              -- Begin ComboBox with the selected item
              if ImGui.BeginCombo(enumName .. "##" .. idx, lastFilterSet[idx][selectedIdx]) then
                for e, item in ipairs(lastFilterSet[idx]) do
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
                    changeMonitor = true
                  end
                end
                ImGui.EndCombo()
              end
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

  trackWindowState("lootRuleHolder")
end)

local lastInventoryCount=0
game.OnRender3D.Add(function()
  if #game.Character.Inventory~=lastInventoryCount then
    lastInventoryCount=#game.Character.Inventory
    scanInventory()
  end
end)

loadWindowData()
loadLootProfile()
