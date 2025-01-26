local inspectedItems = {}
local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local views = require("utilitybelt.views")
local hud = views.Huds.CreateHud("LootInspect")
hud.DontDrawDefaultWindow=true

local lootEditor --looteditorhudholder
local itemBeingEdited

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
  LastAppraisalResponse = DateTime,
  WeaponSkill = SkillId
}

-- Event handler for Item_SetAppraiseInfo
game.Messages.Incoming.Item_SetAppraiseInfo.Add(function(e)
  if (game.World.Selected==nil or game.World.Selected.Id~=e.Data.ObjectId) then return end
  
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
      StringValues = {}
    }
  }

  for _, keytype in ipairs({ "IntValues", "BoolValues", "DataValues", "Int64Values", "FloatValues", "StringValues" }) do
    ---@type table[string]
    itemData[keytype]={}
    for k, v in pairs(weenie[keytype]) do
      itemData[keytype][tostring(k)]=v
    end
    local sortableTable = {}
    for n in pairs(itemData[keytype]) do 
      table.insert(sortableTable, n)
    end
    itemData.sorted = itemData.sorted or {}
    itemData.sorted[keytype] = table.sort(sortableTable,function(a,b)
      return a>b
    end)
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

local function enumCombo(item,valueTable,key,value)
  local enumValues = enumMasks[tostring(key)] or _G[tostring(key)]
  if enumValues ~= nil then
    ImGui.TableSetColumnIndex(1)
    ImGui.Text(key)
    ImGui.TableSetColumnIndex(2)
    ImGui.SetNextItemWidth(-1)
    local currentEnumName = tostring(enumValues[value] or enumValues.FromValue and enumValues.FromValue(value) or value) --
    if ImGui.BeginCombo("##"..key, currentEnumName) then
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
  if itemBeingEdited~=item.id then
    itemBeingEdited=shallowcopy(item)

    itemBeingEdited.sorted={}
    for valuesKey,values in pairs(itemBeingEdited.lootCriteria) do
      itemBeingEdited[valuesKey]=values

      local sortableTable = {}
      for n in pairs(itemBeingEdited[valuesKey]) do 
        table.insert(sortableTable, n)
      end
      itemBeingEdited.sorted[valuesKey] = table.sort(sortableTable,function(a,b)
        return a>b
      end)
    end
  end
end
local function renderTab(item,disabled,criteriaObject)
  local disabled=disabled or false
  local drawlist=ImGui.GetWindowDrawList()
  local separators = {}

  ImGui.SetNextItemWidth(-1)
  if ImGui.BeginTable("##"..item.id, 3,_imgui.ImGuiTableFlags.Resizable) then
    ImGui.TableSetupColumn("##loot",_imgui.ImGuiTableColumnFlags.WidthFixed,20)

    for i=#item.sorted.IntValues,1,-1 do
      local key=item.sorted.IntValues[i]
      local value=item.IntValues[key]
      if value==nil then
        item.sorted.BoolValues[i]=nil
      else    
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local changed,newValue=ImGui.Checkbox("##"..key.."_lootCriteria",criteriaObject.IntValues[key]~=nil or false)
        if changed then
          if newValue==true then
            criteriaObject.IntValues[key]=value
          else
            criteriaObject.IntValues[key]=nil
          end
          sortLootEditor(item)
        end
        ImGui.BeginDisabled(disabled)
        if enumCombo(item,"IntValues",key,value) then
        else
          ImGui.TableSetColumnIndex(1)
          ImGui.Text(key)
          ImGui.TableSetColumnIndex(2)
          ImGui.SetNextItemWidth(-1)
          local changed,newValue = ImGui.InputInt("##"..key, value,1,10)
          if changed then
            criteriaObject.IntValues[key]=newValue
          end
        end
        ImGui.EndDisabled()
      end
    end
    
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    table.insert(separators,ImGui.GetCursorScreenPos())

    for i=#item.sorted.BoolValues,1,-1 do
      local key=item.sorted.BoolValues[i]
      local value=item.BoolValues[key]
      
      if value==nil then
        item.sorted.BoolValues[i]=nil
      else    
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local changed,newValue=ImGui.Checkbox("##"..key.."_lootCriteria",criteriaObject.BoolValues[key]~=nil or false)
        if changed then
          if newValue==true then
            criteriaObject.BoolValues[key]=true
          else
            criteriaObject.BoolValues[key]=nil
          end
          sortLootEditor(item)
        end
        ImGui.BeginDisabled(disabled)
        if enumCombo(item,"BoolValues",key,value) then
        else
          ImGui.TableSetColumnIndex(1)
          ImGui.Text(key)
          ImGui.TableSetColumnIndex(2)
          ImGui.SetNextItemWidth(-1)
          local changed,newValue = ImGui.Checkbox("##"..key, value)
          if changed then
            criteriaObject.BoolValues[key]=newValue
          end
        end
        ImGui.EndDisabled()
      end
    end
    
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    table.insert(separators,ImGui.GetCursorScreenPos())

    for i=#item.sorted.DataValues,1,-1 do
      local key=item.sorted.DataValues[i]
      local value=item.DataValues[key]
      if value==nil then
        item.sorted.DataValues[i]=nil
      else
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local changed,newValue=ImGui.Checkbox("##"..key.."_lootCriteria",criteriaObject.DataValues[key]~=nil or false)
        if changed then
          if newValue==true then
            criteriaObject.DataValues[key]=value
          else
            criteriaObject.DataValues[key]=nil
          end
          sortLootEditor(item)
        end    
        ImGui.BeginDisabled(disabled)
        if enumCombo(item,"DataValues",key,value) then
        else
          ImGui.TableSetColumnIndex(1)
          ImGui.Text(key)
          ImGui.TableSetColumnIndex(2)
          ImGui.SetNextItemWidth(-1)
          local changed,newValue = ImGui.InputInt("##"..key,value) 
          if changed then
            criteriaObject.DataValues[key]=newValue
          end
        end
        ImGui.EndDisabled()
      end
    end
    
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    table.insert(separators,ImGui.GetCursorScreenPos())

    for i=#item.sorted.Int64Values,1,-1 do
      local key=item.sorted.Int64Values[i]
      local value=item.Int64Values[key]
      if value==nil then
        item.sorted.Int64Values[i]=nil
      else
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local changed,newValue=ImGui.Checkbox("##"..key.."_lootCriteria",criteriaObject.Int64Values[key]~=nil or false)
        if changed then
          if newValue==true then
            criteriaObject.Int64Values[key]=value
          else
            criteriaObject.Int64Values[key]=nil
          end
          sortLootEditor(item)
        end
        ImGui.BeginDisabled(disabled)
        if enumCombo(item,"Int64Values",key,value) then
        else
          ImGui.TableSetColumnIndex(1)
          ImGui.Text(key)
          ImGui.TableSetColumnIndex(2)
          ImGui.SetNextItemWidth(-1)
          local changed,newValue = ImGui.InputDouble("##"..key,value,10,100)
          if changed then
            criteriaObject.Int64Values[key]=newValue
          end
        end
        ImGui.EndDisabled()
      end
    end
    
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    table.insert(separators,ImGui.GetCursorScreenPos())

    for i=#item.sorted.FloatValues,1,-1 do
      local key=item.sorted.FloatValues[i]
      local value=item.FloatValues[key]
      if value==nil then
        item.sorted.FloatValues[i]=nil
      else
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        local changed,newValue=ImGui.Checkbox("##"..key.."_lootCriteria",criteriaObject.FloatValues[key]~=nil or false)
        if changed then
          if newValue==true then
            criteriaObject.FloatValues[key]=value
          else
            criteriaObject.FloatValues[key]=nil
          end
          sortLootEditor(item)
        end
        ImGui.BeginDisabled(disabled)
        if enumCombo(item,"FloatValues",key,value) then
        else
          ImGui.TableSetColumnIndex(1)
          ImGui.Text(key)
          ImGui.TableSetColumnIndex(2)
          ImGui.SetNextItemWidth(-1)
          local changed,newValue =ImGui.InputFloat("##"..key,value,.01,0.1)
          if changed then
            criteriaObject.FloatValues[key]=newValue
          end
        end
        ImGui.EndDisabled()
      end
    end

    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    table.insert(separators,ImGui.GetCursorScreenPos())

    for i=#item.sorted.StringValues,1,-1 do
      local key=item.sorted.StringValues[i]
      local value=item.StringValues[key]     
      if value==nil then
        item.sorted.StringValues[i]=nil
      else
        if key~="HeritageGroup" then
          ImGui.TableNextRow()
          ImGui.TableSetColumnIndex(0)
          local changed,newValue=ImGui.Checkbox("##"..key.."_lootCriteria",criteriaObject.StringValues[key]~=nil or false)
          if changed then
            if newValue==true then
              criteriaObject.StringValues[key]=value
            else
              criteriaObject.StringValues[key]=nil
            end
            sortLootEditor(item)
          end
          ImGui.BeginDisabled(disabled)
          if enumCombo(item,"StringValues",key,value) then
          else
            ImGui.TableSetColumnIndex(1)
            ImGui.Text(key)
            ImGui.TableSetColumnIndex(2)
            ImGui.SetNextItemWidth(-1)
            local changed,newValue = ImGui.InputText("##"..key,value,20)
            if changed then
              criteriaObject.StringValues[key]=newValue
            end
          end
          ImGui.EndDisabled()
        end
      end
    end
    ImGui.EndTable()

    for i,cursor in ipairs(separators) do
      drawlist.AddLine(cursor,cursor+Vector2.new(ImGui.GetWindowWidth(),0),0xAAAAAAAA)
    end
  end
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
            renderTab(item,true,item.lootCriteria)

            if ImGui.Button("Template loot rule") then
              sortLootEditor(item)
              if lootEditor then lootEditor.Dispose() end
              lootEditor=views.Huds.CreateHud("LootEditor")
              lootEditor.DontDrawDefaultWindow = true
              lootEditor.Visible = true
              lootEditor.OnRender.Add(function()
                renderTab(itemBeingEdited,false,itemBeingEdited)
              end)
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