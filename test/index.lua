local inspectedItems = {}
local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local views = require("utilitybelt.views")

local lootEditor     --looteditorhudholder
local lootRuleHolder --guess
local itemBeingEdited
local lootRules = {}


-----------------------------------------------------
--- enum stuff
-----------------------------------------------------

require("DaraletGlobals")

local enumMasks = {
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
      local wieldReq = WieldRequirements.GetValues()[item.IntValues["WieldRequirements"]+1]
      if wieldReq~="Training" then
        return wieldReq
      end
    end
    return "SkillId"
  end,
  WieldSkilltype2 =  function(item)
    if item.IntValues["WieldRequirements2"] then
      local wieldReq2 = WieldRequirements2.GetValues()[item.IntValues["WieldRequirements2"]+1]
      if wieldReq2~="Training" then
        return wieldReq2
      end
    end
    return "SkillId"
  end,
  WieldDifficulty = function(item)
    if item.IntValues["WieldRequirements"]==8 then
      return "SkillTrainingType"
    end
    return item.IntValues["WieldDifficulty"]
  end,
  WieldDifficulty2 = function(item)
    if item.IntValues["WieldRequirements2"]==8 then
      return "SkillTrainingType"
    end
    return item.IntValues["WieldDifficulty2"]
  end,
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
local allValueStrings = { "IntValues", "BoolValues", "DataValues", "Int64Values", "FloatValues", "StringValues" }

local function evaluateLoot(item)
  for i, ruleItem in ipairs(lootRules) do
    local lootable = true
    for _, keyValue in ipairs(allValueStrings) do
      if lootable then
        for key, value in pairs(ruleItem[keyValue]) do
          local itemValue = item[keyValue][key]
          if itemValue == nil then
            lootable = false -- If the item doesn't have the property, it doesn't match
          else
            local comparator = ruleItem.comparator[keyValue] and ruleItem.comparator[keyValue][key] or "=="
            local ruleValue = value

            if keyValue=="StringValues" and comparator=="==" then
              if not Regex.IsMatch(itemValue,ruleValue) then
                lootable = false
              end
            elseif comparator == "==" and itemValue ~= ruleValue then
              lootable = false
            elseif comparator == ">=" and itemValue < ruleValue then
              lootable = false
            elseif comparator == "<=" and itemValue > ruleValue then
              lootable = false
            elseif comparator == ">" and itemValue <= ruleValue then
              lootable = false
            elseif comparator == "<" and itemValue >= ruleValue then
              lootable = false
            elseif comparator == "!=" and itemValue == ruleValue then
              lootable = false
            end
          end
        end
      end
    end
    if lootable then 
      return true 
    end
  end

  return false
end

game.Messages.Incoming.Item_SetAppraiseInfo.Add(function(e)
  if (game.World.Selected == nil or game.World.Selected.Id ~= e.Data.ObjectId) then return end

  ---@type table<string, any>
  local weenie = game.World.Get(e.Data.ObjectId)

  if not weenie then
    return
  end

  local itemData = {
    id = e.Data.ObjectId,
    name = weenie.Name,
    lootCriteria = {
      IntValues = {},
      BoolValues = {},
      DataValues = {},
      Int64Values = {},
      FloatValues = {},
      StringValues = {},
      Spells = {}
    },
    spells = {}
  }

  if e.Data.SpellBook then
    for i,spellId in ipairs(game.World.Get(e.Data.ObjectId).SpellIds) do
      table.insert(itemData.spells,game.Character.SpellBook.Get(spellId.Id).Name)
    end
  end

  for _, keytype in ipairs(allValueStrings) do
    ---@type table<string, table<string, any>>
    itemData[keytype] = {}
    for k, v in pairs(weenie[keytype]) do
      itemData[keytype][tostring(k)] = v
    end
    local sortableTable = {}
    for n in pairs(itemData[keytype]) do
      table.insert(sortableTable, n)
    end
    itemData.sorted = itemData.sorted or {}
    itemData.sorted[keytype] = table.sort(sortableTable, function(a, b)
      return a > b
    end)
  end

  local existingIndex = nil
  for i, item in ipairs(inspectedItems) do
    if item.id == itemData.id then
      existingIndex = i
      break
    end
  end

  if existingIndex then
    inspectedItems[existingIndex] = itemData
  else
    table.insert(inspectedItems, itemData)
  end
  if #lootRules > 0 then
    print(tostring(evaluateLoot(itemData)) .. " to looting " .. weenie.Name)
  end
end)


-----------------------------------------------------
--- ImGui helpers
-----------------------------------------------------

local function comparatorRender(comparators, criteriaObject, valuesKey, key)
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

local function enumCombo(item, valueTable, key, value)
  ---@diagnostic disable:undefined-field
  local enumValues
  if valueTable=="IntValues" then
    enumValues = enumMasks[ExtraEnums.IntValues[key]] or _G[tostring(key)]
  else
    enumValues = enumMasks[tostring(key)] or _G[tostring(key)]
  end
  if type(enumValues)=="function" then
    local globalVal = enumValues(item)
    if globalVal then
      enumValues = _G[globalVal] or nil
    end
  end
  if enumValues ~= nil then
    ImGui.SetNextItemWidth(-1)
    local currentEnumName
    local unparsedEnum = enumValues[value] or enumValues.FromValue and enumValues.FromValue(value) or value
    if type(unparsedEnum)=="number" then
      currentEnumName=tostring(enumValues.GetValues()[unparsedEnum+1]) --it is unreal how fucked i am doing this because i don't know how to recreate fromvalue/getvalues in lua
    else
      currentEnumName=tostring(unparsedEnum)  --real, userdata-y enum
    end--
    if ImGui.BeginCombo("##" .. key, currentEnumName) then
      for _, enumName in ipairs(enumValues.GetValues()) do
        local isSelected = (currentEnumName == enumName)
        if ImGui.Selectable(enumName, isSelected) then
          item[valueTable][key] = enumValues.FromValue(enumName)
        end
        if isSelected then
          ImGui.SetItemDefaultFocus()
        end
      end
      ImGui.EndCombo()
    end
    return true
  end
  return false
  ---@diagnostic enable:undefined-field
end

local function shallowcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

local function sortLootEditor(item)
  local comparator = (itemBeingEdited and itemBeingEdited.comparator and shallowcopy(itemBeingEdited.comparator)) or {}

  itemBeingEdited = shallowcopy(item)
  itemBeingEdited.comparator = comparator

  itemBeingEdited.sorted = {}
  for valuesKey, values in pairs(itemBeingEdited.lootCriteria) do
    itemBeingEdited[valuesKey] = values

    local sortableTable = {}
    for n in pairs(itemBeingEdited[valuesKey]) do
      table.insert(sortableTable, n)
    end
    itemBeingEdited.sorted[valuesKey] = table.sort(sortableTable, function(a, b)
      return a > b
    end)
  end
end

local imguiInputs = {
  IntValues = function(key,value)
    return ImGui.InputInt("##" .. key, value, 1, 10)
  end,
  BoolValues = function(key,value)
    return ImGui.Checkbox("##" .. key, value)
  end,
  DataValues = function(key,value)
    return ImGui.InputInt("##" .. key, value)
  end,
  Int64Values = function(key,value)
    return ImGui.InputDouble("##" .. key, value, 10, 100,"%.0f")
  end,
  FloatValues = function(key,value)
    return ImGui.InputFloat("##" .. key, value, .01, 0.1)
  end,
  StringValues = function(key,value)
    return ImGui.InputText("##" .. key, value, 64)
  end  
}

-----------------------------------------------------
--- ImGui renders
-----------------------------------------------------

local hud = views.Huds.CreateHud("LootInspect",0x06001A8A)
hud.DontDrawDefaultWindow = true
hud.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse

local function renderTab(item, disabled, criteriaObject)
  local disabled = disabled or false
  local drawlist = ImGui.GetWindowDrawList()
  local separators = {}
  local comparators
  if not disabled then
    comparators = { "==", ">=", "<=", ">", "<", "!=" }
  end

  local buttonHeight = ImGui.GetTextLineHeightWithSpacing()+ImGui.GetStyle().FramePadding.Y*2
  local availableHeight = ImGui.GetContentRegionAvail().Y
  local cursorStartPos = ImGui.GetCursorScreenPos()
  local childMax = Vector2.new(-1,availableHeight - buttonHeight)
  ImGui.BeginChild("TableRegion", childMax, true)
  if ImGui.BeginTable("##" .. item.id, (comparators and 4 or 3), _imgui.ImGuiTableFlags.Resizable) then
    ImGui.TableSetupColumn("##loot", _imgui.ImGuiTableColumnFlags.WidthFixed, 20)
    ImGui.TableSetupColumn("##lootkey")
    if comparators then
      ImGui.TableSetupColumn("##comparators",_imgui.ImGuiTableColumnFlags.WidthFixed,60)
    end
    
    for _,valuesKey in ipairs(allValueStrings) do
      for i = #item.sorted[valuesKey], 1, -1 do
        local key = item.sorted[valuesKey][i]
        local value = item[valuesKey][key]

        if value == nil then
          item.sorted[valuesKey][i] = nil
        else
          ImGui.TableNextRow()
          ImGui.TableSetColumnIndex(0)
          
          local changed, newValue = ImGui.Checkbox("##" .. key .. "_lootCriteria",
          criteriaObject[valuesKey][key] ~= nil or false)
          if changed then
            if newValue == true then
              criteriaObject[valuesKey][key] = value
            else
              criteriaObject[valuesKey][key] = nil
            end
            sortLootEditor(item)
          end
          ImGui.BeginDisabled(disabled)

          ImGui.TableSetColumnIndex(1)
          ImGui.Text(ExtraEnums[valuesKey][key])
          ImGui.TableNextColumn()
          comparatorRender(comparators, criteriaObject, valuesKey, key)

          if enumCombo(item, valuesKey, key, value) then
          else
            ImGui.SetNextItemWidth(-1)
            local changed, newValue = imguiInputs[valuesKey](key,value)
            if changed then
              criteriaObject[valuesKey][key] = newValue
            end
          end
          ImGui.EndDisabled()
        end
      end

      if #item.sorted[valuesKey] > 0 then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local linePos = ImGui.GetCursorScreenPos()
        if linePos.Y<(cursorStartPos.Y+childMax.Y) and linePos.Y>cursorStartPos.Y then
          table.insert(separators, ImGui.GetCursorScreenPos())
        end
      end
    end

    ImGui.EndTable()
    local scrollbarY = ImGui.GetScrollMaxY()>0
    ImGui.EndChild()
    
    local style=ImGui.GetStyle()
    for i, cursor in ipairs(separators) do
      drawlist.AddLine(cursor, cursor + Vector2.new(ImGui.GetWindowWidth()-(scrollbarY and style.ScrollbarSize or 0)-style.FrameBorderSize*2-style.FramePadding.X*3-style.WindowPadding.X*2,0), 0xAAAAAAAA)
    end
  end
end

local renderLootEditor
local function renderLootRule()
  if ImGui.Begin("Loot Rules") then
    if ImGui.BeginTable("ListTable", 1, _imgui.ImGuiTableFlags.Borders + _imgui.ImGuiTableFlags.RowBg) then
      -- Table header
      ImGui.TableSetupColumn("Name", _imgui.ImGuiTableColumnFlags.WidthStretch)
      --ImGui.TableSetupColumn("Description", _imgui.ImGuiTableColumnFlags.WidthStretch)
      ImGui.TableHeadersRow()

      for i, rule in ipairs(lootRules) do
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)

        -- Highlight the row on hover
        local isClicked = ImGui.Selectable(rule.name, false, _imgui.ImGuiSelectableFlags.SpanAllColumns)

        -- Handle row click
        if isClicked then
          sortLootEditor(rule)
          renderLootEditor()
        end
      end

      ImGui.EndTable()
    end
  end
  ImGui.End()
end

function renderLootEditor()
  if lootEditor then lootEditor.Dispose() end
  lootEditor = views.Huds.CreateHud("LootEditor")
  lootEditor.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse
  lootEditor.Visible = true
  lootEditor.OnRender.Add(function()
    renderTab(itemBeingEdited, false, itemBeingEdited)
    local lootRuleName = itemBeingEdited.name
    local changed,newValue=ImGui.InputText("##saveLootRuleName",lootRuleName,64)
    if changed then
      if newValue~="" then
        itemBeingEdited.name=newValue
      end
    end
    ImGui.SameLine()
    if ImGui.Button("Save loot rule") then
      table.insert(lootRules, itemBeingEdited)
      if not lootRuleHolder then
        lootRuleHolder = views.Huds.CreateHud("*LootRuleHolder")
        lootRuleHolder.Visible = true
        lootRuleHolder.DontDrawDefaultWindow = true
        lootRuleHolder.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse
        lootRuleHolder.OnRender.Add(renderLootRule)
      end
      lootEditor.Dispose()
    end
  end)
end

-- ImGui render function
local function renderInspectedItems()
  if ImGui.Begin("Inspected Items") then
    if #inspectedItems == 0 then
      ImGui.Text("No items inspected yet.")
    else
      if ImGui.BeginTabBar("InspectedItemsTabs") then
        for i, item in ipairs(inspectedItems) do
          if ImGui.BeginTabItem(item.name .. "##" .. i) then
            renderTab(item, true, item.lootCriteria)

            if ImGui.Button("Template loot rule") then
              sortLootEditor(item)
              renderLootEditor()
            end

            ImGui.EndTabItem()
          end
        end
        ImGui.EndTabBar()
      end
    end
    ImGui.End()
  end
end

-- Add the render function to your game's render loop
hud.OnRender.Add(renderInspectedItems)
