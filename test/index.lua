local inspectedItems = {}
local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local views = require("utilitybelt.views")

local hud
local lootRuleHolder
local lootRules = {}
local filterCounter = 0
local lastFilterCount = 0

-----------------------------------------------------
--- enum stuff
-----------------------------------------------------

require("DaraletGlobals")

local allValueStrings = { "IntValues", "BoolValues", "DataValues", "Int64Values", "FloatValues", "StringValues" }
local allEnums = { "IntId", "BoolId", "DataId", "Int64Id", "FloatId", "StringId" }
local enumDefault = { 1, false, 1, 1, 1.0, "" }
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
      local wieldReq = WieldRequirements.GetValues()[item.IntValues["WieldRequirements"] + 1]
      if wieldReq ~= "Training" then
        return wieldReq
      end
    end
    return "SkillId"
  end,
  WieldSkilltype2 = function(item)
    if item.IntValues["WieldRequirements2"] then
      local wieldReq2 = WieldRequirements2.GetValues()[item.IntValues["WieldRequirements2"] + 1]
      if wieldReq2 ~= "Training" then
        return wieldReq2
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

local sortedEnums = {}
for _, enum in ipairs(allEnums) do
  local sorted = table.sort(_G[enum].GetValues(), function(a, b)
    return tostring(a) < tostring(b)
  end)
  table.insert(sortedEnums, sorted)
end

local function evaluateLoot(item)
  for i, ruleItem in ipairs(lootRules) do
    local lootable = true
    for _, keyValue in ipairs(allValueStrings) do
      if lootable then
        for j = #ruleItem.sorted[keyValue], 1, -1 do
          local key = ruleItem.sorted[keyValue][j]
          local keyForCompare = string.gsub(key, "^_+", "")
          local itemValue = item[keyValue][keyForCompare]
          if itemValue == nil then
            lootable = false -- If the item doesn't have the property, it doesn't match
          else
            local comparator = ruleItem.comparator[keyValue] and ruleItem.comparator[keyValue][key] or "=="
            local ruleValue = ruleItem[keyValue][key]

            if keyValue == "StringValues" and comparator == "==" then
              if not Regex.IsMatch(itemValue or "", ruleValue or "") and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
                lootable = false
              end
            elseif comparator == "==" and itemValue ~= ruleValue and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
              lootable = false
            elseif comparator == ">=" and itemValue < ruleValue and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
              lootable = false
            elseif comparator == "<=" and itemValue > ruleValue and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
              lootable = false
            elseif comparator == ">" and itemValue <= ruleValue and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
              lootable = false
            elseif comparator == "<" and itemValue >= ruleValue and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
              lootable = false
            elseif comparator == "!=" and itemValue == ruleValue and ((ruleItem.AndOr == nil or ruleItem.AndOr[key] == nil) and (ruleItem.AndOr["_" .. key] == nil or (ruleItem.AndOr["_" .. key] and ruleItem.AndOr["_" .. key] == "and")) or ruleItem.AndOr[key] == "and") then
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
    if ImGui.BeginCombo("##" .. key .. "_comparator", criteriaObject.comparator[valuesKey][key]) then -- should be unique since only one set of comparators showing at a time
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
  local keyForText = string.gsub(key, "^_+", "")

  local enumValues
  if valueTable == "IntValues" then
    enumValues = enumMasks[ExtraEnums.IntValues[keyForText]] or _G[tostring(keyForText)]
  else
    enumValues = enumMasks[tostring(keyForText)] or _G[tostring(keyForText)]
  end
  if type(enumValues) == "function" then
    local globalVal = enumValues(item)
    if globalVal then
      enumValues = _G[globalVal] or nil
    end
  end
  if enumValues ~= nil then
    ImGui.SetNextItemWidth(-1)
    local currentEnumName
    local unparsedEnum = enumValues[value] or enumValues.FromValue and enumValues.FromValue(value) or value
    if type(unparsedEnum) == "number" then
      currentEnumName = tostring(enumValues.GetValues()[unparsedEnum + 1]) --it is unreal how fucked i am doing this because i don't know how to recreate fromvalue/getvalues in lua
    else
      currentEnumName = tostring(unparsedEnum)                             --real, userdata-y enum
    end                                                                    --
    if ImGui.BeginCombo("##" .. key .. item.uid, currentEnumName) then
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

local underscore = string.byte("_")
local function copyAndSort(item)
  local comparator = (item.comparator and deepcopy(item.comparator)) or {}

  local newItem = deepcopy(item)
  newItem.uid = tostring(os.time()) .. tostring(os.clock()):gsub("%.", "")
  newItem.comparator = comparator
  newItem.spells = nil

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
        
        if string.sub(a,a_underscores+1)==string.sub(b,b_underscores+1) and a_underscores ~= b_underscores then
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
--- ImGui renders
-----------------------------------------------------

hud = views.Huds.CreateHud("LootInspect", 0x06001A8A)
hud.DontDrawDefaultWindow = true
hud.Visible = true
hud.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse

hud.OnPreRender.Add(function()
  ImGui.SetNextWindowSizeConstraints(Vector2.new(100, 100), Vector2.new(9999, 9999))
  hud.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse
end)

local function renderTab(item, disabled, criteriaObject, stretch)
  local disabled = disabled or false
  local drawlist = ImGui.GetWindowDrawList()
  local separators = {}
  local comparators
  if not disabled then
    comparators = { "==", ">=", "<=", ">", "<", "!=" }
  end

  local style = ImGui.GetStyle()
  local rowHeight = (ImGui.GetFontSize() + style.FramePadding.Y * 2) + style.ItemSpacing.Y + style.CellPadding.Y
  local childWindowGap = style.FramePadding.Y * 2 + style.WindowPadding.Y * 2
  local availableHeight = ImGui.GetContentRegionAvail().Y
  local cursorStartPos = ImGui.GetCursorScreenPos()
  local childMax
  if stretch then
    childMax = Vector2.new(-1, availableHeight - rowHeight)
  else
    local rowCount = 0
    for _, valuesKey in ipairs(allValueStrings) do
      rowCount = rowCount + #(item.sorted[valuesKey])
    end
    local innerHeight = (rowCount + (item.spells and 1 or 0)) * rowHeight
    childMax = Vector2.new(-1,
      math.min(innerHeight + childWindowGap, availableHeight - rowHeight * (1 + lastFilterCount) - style.ItemSpacing.Y))
  end

  if ImGui.BeginChild("TableRegion", childMax, true) then
    if ImGui.BeginTable("##table" .. item.uid, (comparators and 4 or 3), _imgui.ImGuiTableFlags.Resizable) then
      ImGui.TableSetupColumn("##loot" .. item.uid, _imgui.ImGuiTableColumnFlags.WidthFixed, 20)
      ImGui.TableSetupColumn("##lootkey" .. item.uid)
      if comparators then
        ImGui.TableSetupColumn("##comparators", _imgui.ImGuiTableColumnFlags.WidthFixed, 60)
      end

      for _, valuesKey in ipairs(allValueStrings) do
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
              elseif criteriaObject==item then
                local lastKey = key
                local nextKey = "_" .. key
                
                while criteriaObject[valuesKey][nextKey] ~= nil do
                  criteriaObject[valuesKey][lastKey]=criteriaObject[valuesKey][nextKey]
                  criteriaObject.AndOr[lastKey]=criteriaObject.AndOr[nextKey]
                  criteriaObject.comparator[valuesKey][lastKey] = criteriaObject.comparator[valuesKey][nextKey]
                  
                  lastKey = nextKey  
                  nextKey = "_" .. lastKey
                end
                
                criteriaObject[valuesKey][lastKey] = nil
              else
                criteriaObject[valuesKey][key] = nil
              end
            end
            ImGui.BeginDisabled(disabled)

            ImGui.TableSetColumnIndex(1)
            if keyForText ~= key then
              if criteriaObject.AndOr==nil then
                criteriaObject.AndOr={}
              end
              criteriaObject.AndOr[key] = criteriaObject.AndOr[key] or "and"
              ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding, Vector2.new(0, 0))
              if ImGui.Button(criteriaObject.AndOr[key] .. "##andOr" .. key, Vector2.new(24, 20)) then
                criteriaObject.AndOr[key] = criteriaObject.AndOr[key] == "and" and "or" or "and"
                print(criteriaObject.AndOr[key],key)
              end
              ImGui.PopStyleVar()
              ImGui.SameLine()
            end
            ImGui.Text(ExtraEnums[valuesKey][keyForText])
            ImGui.TableNextColumn()
            comparatorRender(comparators, criteriaObject, valuesKey, key)

            if enumCombo(item, valuesKey, key, value) then
            else
              ImGui.SetNextItemWidth(-1)
              local changed, newValue = imguiInputs[valuesKey](key, value, item)
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
            (style.FrameBorderSize * 2 - style.FramePadding.X * 3 - style.WindowPadding.X * 2) * (stretch and -1 or -1.5),
            0),
          0xAAAAAAAA)
      end
    end
  end
end

hud.OnRender.Add(function()
  if ImGui.Begin("Inspected Items", hud.WindowSettings) then
    if #inspectedItems == 0 then
      ImGui.Text("No items inspected yet.")
    else
      if ImGui.BeginTabBar("InspectedItemsTabs") then
        for i, item in ipairs(inspectedItems) do
          if ImGui.BeginTabItem(item.name .. "##" .. i) then
            renderTab(item, true, item.lootCriteria, true)

            if ImGui.Button("Template loot rule") then
              local itemCopy = copyAndSort(item)
              itemCopy.isShown = true
              for _i, _rule in ipairs(lootRules) do
                _rule.isShown = false
              end
              table.insert(lootRules, itemCopy)
            end

            ImGui.EndTabItem()
          end
        end
        ImGui.EndTabBar()
      end
    end
    ImGui.End()
  end
end)

lootRuleHolder = views.Huds.CreateHud("*LootRuleHolder")
lootRuleHolder.DontDrawDefaultWindow = true
lootRuleHolder.Visible = true
lootRuleHolder.WindowSettings = _imgui.ImGuiWindowFlags.NoCollapse

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
local function renderLootRule()
  lastFilterCount = filterCounter
  filterCounter = 0
  if ImGui.Begin("Loot Rules", lootRuleHolder.WindowSettings) then
    if ImGui.BeginTable("ListTable", 1, _imgui.ImGuiTableFlags.Borders) then
      -- Table header
      ImGui.TableSetupColumn("Name", _imgui.ImGuiTableColumnFlags.WidthStretch)
      --ImGui.TableSetupColumn("Description", _imgui.ImGuiTableColumnFlags.WidthStretch)
      ImGui.TableHeadersRow()

      ImGui.SetCursorScreenPos(Vector2.new(ImGui.GetItemRectMax().X - ImGui.CalcTextSize(hintText).X,
        ImGui.GetItemRectMin().Y + ImGui.GetStyle().FramePadding.Y))
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, 0x77777777)
      ImGui.Text(hintText)
      ImGui.PopStyleColor()
      if ImGui.IsItemHovered() then
        hintText = ""
      end

      for i, rule in ipairs(lootRules) do
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)

        -- Right-click detection for inline editing
        ImGui.Text(i .. ". ")
        ImGui.SameLine()

        local isClicked

        if rule.isRenaming then
          -- Get the current position of the text item
          local selectableStart = Vector2.new(ImGui.GetItemRectMax().X + ImGui.GetStyle().ItemInnerSpacing.X,
            ImGui.GetItemRectMax().Y - ImGui.GetItemRectSize().Y - ImGui.GetStyle().FramePadding.Y)
          local startPos = selectableStart

          -- Set the cursor to the position of the text
          ImGui.SetCursorScreenPos(startPos)

          -- Directly editing the name inline
          ImGui.SetKeyboardFocusHere()
          local changed, newValue = ImGui.InputText("##editLootRuleName" .. rule.uid, rule.name, 64,
            _imgui.ImGuiInputTextFlags.EnterReturnsTrue)
          if changed and newValue ~= "" then
            rule.name = newValue
          end

          -- When the user presses Enter, or if the input loses focus, stop editing
          if changed or ImGui.IsItemDeactivated() then
            rule.isRenaming = false
          end
        else
          local buttonSize = Vector2.new(20, 20)
          isClicked = ImGui.Selectable(rule.name .. "##" .. rule.uid, false, _imgui.ImGuiSelectableFlags.AllowOverlap,
            Vector2.new(ImGui.GetColumnWidth(), ImGui.GetFrameHeight()))

          if ImGui.IsItemHovered() and ImGui.IsMouseReleased(1) then -- 1 is the right-click button
            rule.isRenaming = true                                   -- Trigger the renaming mode
          elseif rule.isShown then
            local barOptions = Vector2.new(ImGui.GetItemRectMax().X - 3 * buttonSize.X - ImGui.GetStyle().FramePadding.X,
              ImGui.GetItemRectMax().Y - ImGui.GetItemRectSize().Y + ImGui.GetStyle().FramePadding.Y)
            ImGui.SetCursorScreenPos(barOptions)
            ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, Vector2.new(0, ImGui.GetStyle().ItemInnerSpacing.Y))
            ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemSpacing, Vector2.new(0, 0))

            DrawIcon(rule, 0x060028FC, buttonSize, function()
              moveElementUp(lootRules, i)
            end)

            ImGui.SameLine(0)
            DrawIcon(rule, 0x060028FD, buttonSize, function()
              moveElementDown(lootRules, i)
            end)

            if ImGui.GetIO().KeyCtrl then
              ImGui.SameLine(0)
              DrawIcon(rule, 0x0600606E, buttonSize, function()
                removeElement(lootRules, i)
              end)
            end

            ImGui.PopStyleVar(2)
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
          renderTab(rule, false, rule)

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
                  end                  
                end
                ImGui.EndCombo()
              end
            end
          end
        end
      end

      ImGui.EndTable()
    end
  end
  ImGui.End()
end


lootRuleHolder.OnRender.Add(renderLootRule)
