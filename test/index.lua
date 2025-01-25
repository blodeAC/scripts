local inspectedItems = {}
local _imgui = require("imgui")
local ImGui = _imgui.ImGui

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
  WieldSkilltype = AttributeId,
  AmmoType = AmmoType,
  ObjectType = ObjectType,
  TargetType = ObjectType,
  IconEffects = IconHighlight,
  CombatUse = WieldType,
  ObjectDescriptionFlag = ObjectDescriptionFlag,
  ContainerProperties = ContainerProperties,
  PhysicsState = PhysicsState,
  LastAppraisalResponse = DateTime
}

-- Event handler for Item_SetAppraiseInfo
game.Messages.Incoming.Item_SetAppraiseInfo.Add(function(e)
  local weenie = game.World.Get(e.Data.ObjectId)

  if not weenie then
    return
  end

  local itemData = {
    id = e.Data.ObjectId,
    name = weenie.Name,
    values = {}
  }

  for _, keytype in ipairs({ "IntValues", "BoolValues", "DataValues", "Int64Values", "FloatValues", "StringValues" }) do
    for k, v in pairs(weenie[keytype]) do
      table.insert(itemData.values, { type = keytype, key = k, value = v })
    end
  end

  -- Update existing item or add new one
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
end)

-- ImGui render function
local function renderInspectedItems()
  if ImGui.Begin("Inspected Items") then
    if #inspectedItems == 0 then
      ImGui.Text("No items inspected yet.")
    else
      if ImGui.BeginTabBar("InspectedItemsTabs") then
        for i, item in ipairs(inspectedItems) do
          if ImGui.BeginTabItem(item.name .. "##" .. i) then
            ImGui.Text("Name: " .. item.name)
            ImGui.Separator()
            for _, value in ipairs(item.values) do
              -- Check if the value is an enum
              ---@type EnumConst[]
              local enumValues = enumMasks[tostring(value.key)] or _G[tostring(value.key)]
              if enumValues ~= nil then
                if not (tostring(value.key)=="HeritageGroup" and value.type=="StringValues") then --ambiguous enum, same for int and string (???? weird ACE implementation)
                  local currentEnumName = tostring(enumValues[value.value] or enumValues.FromValue and enumValues.FromValue(value.value) or value.value)--
                  if ImGui.BeginCombo(value.key, currentEnumName) then
                    for _, enumName in ipairs(enumValues.GetValues()) do
                      local isSelected = (currentEnumName == enumName)
                      if ImGui.Selectable(enumName, isSelected) then
                        -- Handle selection if needed
                      end
                      if isSelected then
                        ImGui.SetItemDefaultFocus()
                      end
                    end
                    ImGui.EndCombo()
                  end
                end
              else
                local valueStr = tostring(value.value):gsub("%%", "%%%%")
                ImGui.Text(tostring(value.key) .. " = " .. valueStr)
              end
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

local hud = require("utilitybelt.views").Huds.CreateHud("iteminfo")
-- Add the render function to your game's render loop
hud.OnRender.Add(renderInspectedItems)