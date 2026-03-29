local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local common = require("bar_common")

local function shallowcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else
    copy = orig
  end
  return copy
end

return {
  name = "equipmentManager",
  settings = {
    enabled = false,
    icon_hex = 0x060018FA,
  },
  styleVar = {
    { _imgui.ImGuiStyleVar.FramePadding, Vector2.new(2, 2) },
    { _imgui.ImGuiStyleVar.ItemSpacing,  Vector2.new(2, 2) }
  },
  shallowcopy = shallowcopy,
  init = function(bar)
    function table.contains(tbl, value)
      for _, v in pairs(tbl) do
        if v == value then return true end
      end
      return false
    end

    bar.GetItemTypeUnderlay = function(wo)
      local underlay = (wo.DataValues[DataId.IconUnderlay] or 0)
      if underlay ~= 0 then return underlay
      elseif wo.ObjectType == ObjectType.MeleeWeapon then return 0x060011CB
      elseif wo.ObjectType == ObjectType.Armor then return 0x060011CF
      elseif wo.ObjectType == ObjectType.Clothing then return 0x060011F3
      elseif wo.ObjectType == ObjectType.Container then return 0x060011CE
      elseif wo.ObjectType == ObjectType.Creature then return 0x060011D1
      elseif wo.ObjectType == ObjectType.Food then return 0x060011CC
      elseif wo.ObjectType == ObjectType.Gem then return 0x060011D3
      elseif wo.ObjectType == ObjectType.Jewelry then
        if (wo.IntValues[IntId.SharedCooldown] or 0) > 0 then return 0x060011CF end
        return 0x060011D5
      elseif wo.ObjectType == ObjectType.Money then return 0x060011F4
      elseif wo.ObjectType == ObjectType.MissileWeapon then return 0x060011D2
      elseif wo.ObjectType == ObjectType.Useless then return 0x060011D0
      elseif wo.ObjectType == ObjectType.SpellComponents then return 0x060011CD
      elseif wo.ObjectType == ObjectType.Service then return 0x06005E23
      else return 0x060011D4
      end
    end

    bar.equipMask = {}
    table.insert(bar.equipMask, 1, "Necklace")
    table.insert(bar.equipMask, 2, "Trinket")
    table.insert(bar.equipMask, 3, "LeftBracelet")
    table.insert(bar.equipMask, 4, "LeftRing")
    table.insert(bar.equipMask, 5, "Shield")
    table.insert(bar.equipMask, 6, "None")
    table.insert(bar.equipMask, 7, "UpperArms")
    table.insert(bar.equipMask, 8, "LowerArms")
    table.insert(bar.equipMask, 9, "Hands")
    table.insert(bar.equipMask, 10, "None")
    table.insert(bar.equipMask, 11, "Head")
    table.insert(bar.equipMask, 12, "Chest")
    table.insert(bar.equipMask, 13, "Abdomen")
    table.insert(bar.equipMask, 14, "None")
    table.insert(bar.equipMask, 15, "None")
    table.insert(bar.equipMask, 16, "BlueAetheria")
    table.insert(bar.equipMask, 17, "None")
    table.insert(bar.equipMask, 18, "UpperLegs")
    table.insert(bar.equipMask, 19, "LowerLegs")
    table.insert(bar.equipMask, 20, "Feet")
    table.insert(bar.equipMask, 21, "YellowAetheria")
    table.insert(bar.equipMask, 22, "None")
    table.insert(bar.equipMask, 23, "RightBracelet")
    table.insert(bar.equipMask, 24, "RightRing")
    table.insert(bar.equipMask, 25, "Wand")
    table.insert(bar.equipMask, 26, "RedAetheria")
    table.insert(bar.equipMask, 27, "None")
    table.insert(bar.equipMask, 28, "ChestUnderwear")
    table.insert(bar.equipMask, 29, "UpperLegsUnderwear")
    table.insert(bar.equipMask, 30, "Ammunition")

    bar.slots = {}
    bar.rememberedSlots = {}
    bar.profiles = bar.profiles or {}

    bar.scan = function(bar)
      bar.slots = {}
      local filledSlots = shallowcopy(bar.equipMask)
      for _, equipment in ipairs(game.Character.Equipment) do
        for i, slot in ipairs(bar.equipMask) do
          if slot ~= "None" and equipment.CurrentWieldedLocation + EquipMask[slot] == equipment.CurrentWieldedLocation then
            bar.slots[slot] = equipment
            filledSlots[i] = "FILLED"
          elseif i == 25 then
            if equipment.CurrentWieldedLocation + EquipMask["MeleeWeapon"] == equipment.CurrentWieldedLocation then
              bar.slots["MeleeWeapon"] = equipment
              filledSlots[i] = "FILLED"
            elseif equipment.CurrentWieldedLocation + EquipMask["MissileWeapon"] == equipment.CurrentWieldedLocation then
              bar.slots["MissileWeapon"] = equipment
              filledSlots[i] = "FILLED"
            end
          end
        end
      end
      for i, slot in ipairs(filledSlots) do
        if filledSlots[i] ~= "FILLED" then
          bar.slots[filledSlots[i]] = filledSlots[i]
        end
      end

      if bar.activeProfile then
        for slot, gear in pairs(bar.activeProfile.gear) do
          if bar.slots[slot] == nil or bar.slots[slot].Id ~= gear then
            bar.activeProfile = nil
            break
          end
        end
      end
    end
    bar:scan()

    bar.watcher = function(updateInstance)
      local objectId = updateInstance.Data.ObjectId
      local weenie = game.World.Get(objectId)
      if not weenie then return end
      if updateInstance.Data.Key == InstanceId.Container and updateInstance.Data.Value == game.CharacterId then
        for _ in game.ActionQueue.ImmediateQueue do return end
        for _ in game.ActionQueue.Queue do return end
        sleep(333)
        bar:scan()
      elseif updateInstance.Data.Key == InstanceId.Wielder then
        for _ in game.ActionQueue.ImmediateQueue do return end
        for _ in game.ActionQueue.Queue do return end
        sleep(333)
        bar:scan()
      end
    end
    game.Messages.Incoming.Qualities_UpdateInstanceID.Add(bar.watcher)
  end,

  resetRemembered = function(bar)
    bar.rememberedSlots = {}
  end,

  showGear = function(bar)
    local style = ImGui.GetStyle()
    local miscPadding = style.CellPadding + style.FramePadding + style.ItemSpacing + style.WindowPadding

    for _, profile in ipairs(bar.profiles) do
      if profile.name == bar.profileName then
        if not profile.gear then
          bar:resetRemembered()
        else
          bar.rememberedSlots = profile.gear
          bar.dontSave = bar.dontSave or shallowcopy(profile.gear)
        end
      end
    end

    local windowPos = ImGui.GetWindowPos()
    local shiftStart = { 5, 1, 1, 2, 5, 5 }
    local contentSpace = ImGui.GetContentRegionAvail() - Vector2.new(0, ImGui.GetTextLineHeight() + miscPadding.Y)
    local cellSize = Vector2.new(contentSpace.X / 6, contentSpace.Y / 5.5)
    local drawlist = ImGui.GetWindowDrawList()

    for x = 1, 6, 1 do
      for y = 1, 5, 1 do
        local index = (x - 1) * 5 + y
        local startX = windowPos.X + (x - 1) * cellSize.X
        local startY = windowPos.Y + (y - 1) * cellSize.Y + (y >= shiftStart[x] and cellSize.Y / 2 or 0)
        local start = Vector2.new(startX, startY)
        local slot = bar.equipMask[index]

        if index == 25 and bar.slots[slot] == nil then
          if bar.slots["MeleeWeapon"] ~= nil then slot = "MeleeWeapon"
          elseif bar.slots["MissileWeapon"] ~= nil then slot = "MissileWeapon" end
        end

        if slot ~= "None" then drawlist.AddRect(start, start + cellSize, 0xFFFFFFFF) end
        drawlist.AddRectFilled(start, start + cellSize, 0x88000000)

        local slottedItem = bar.slots[slot] or
          (slot == "MeleeWeapon" and (bar.slots["Wand"] or bar.slots["MissileWeapon"])) or
          (slot == "MissileWeapon" and (bar.slots["Wand"] or bar.slots["MeleeWeapon"]))

        if slottedItem and slottedItem ~= slot then
          ImGui.SetCursorScreenPos(start)
          DrawIcon(bar, bar.GetItemTypeUnderlay(slottedItem), cellSize, function()
            if bar.rememberedSlots[slot] == slottedItem.Id then
              if not (string.find(slot, "Ring") or string.find(slot, "Bracelet") or string.find(slot, "Weapon") or string.find(slot, "Shield")) then
                for i, eqslot in ipairs(bar.equipMask) do
                  if eqslot ~= "None" and (slottedItem.IntValues[IntId.ValidLocations] or 0) + EquipMask[eqslot] == (slottedItem.IntValues[IntId.ValidLocations] or 0) then
                    bar.rememberedSlots[eqslot] = nil
                  end
                end
              else
                bar.rememberedSlots[slot] = nil
              end
            else
              if not (string.find(slot, "Ring") or string.find(slot, "Bracelet") or string.find(slot, "Weapon") or string.find(slot, "Shield")) then
                for i, eqslot in ipairs(bar.equipMask) do
                  if eqslot ~= "None" and (slottedItem.IntValues[IntId.ValidLocations] or 0) + EquipMask[eqslot] == (slottedItem.IntValues[IntId.ValidLocations] or 0) then
                    bar.rememberedSlots[eqslot] = slottedItem.Id
                  end
                end
              else
                bar.rememberedSlots[slot] = slottedItem.Id
              end
            end
          end)
          ImGui.SetCursorScreenPos(start)
          DrawIcon(bar, (bar.slots[slot].DataValues[DataId.Icon] or 0), cellSize)

          if bar.rememberedSlots[slot] == slottedItem.Id then
            drawlist.AddRectFilled(start, start + cellSize, 0x8800FF00)
          elseif (bar.rememberedSlots[slot] and slottedItem.Id ~= bar.rememberedSlots[slot]) or
              (({ Wand = true, MissileWeapon = true, MeleeWeapon = true })[slot] and
              ((bar.rememberedSlots["Wand"] and bar.rememberedSlots["Wand"] ~= slottedItem.Id) or
              (bar.rememberedSlots["MeleeWeapon"] and bar.rememberedSlots["MeleeWeapon"] ~= slottedItem.Id) or
              (bar.rememberedSlots["MissileWeapon"] and bar.rememberedSlots["MissileWeapon"] ~= slottedItem.Id))) then
            drawlist.AddRectFilled(start, start + cellSize, 0x880000FF)
          end
        elseif bar.rememberedSlots[slot] and bar.rememberedSlots[slot] ~= slot then
          drawlist.AddRectFilled(start, start + cellSize, 0x880000FF)
        elseif slottedItem == slot and slot ~= "None" then
          ImGui.SetCursorScreenPos(start)
          local mouse = ImGui.GetMousePos()
          local isHovered = mouse.X >= start.X and mouse.X <= start.X + cellSize.X and
              mouse.Y >= start.Y and mouse.Y <= start.Y + cellSize.Y

          if isHovered and ImGui.IsMouseClicked(0) then
            if bar.rememberedSlots[slot] == slot then
              bar.rememberedSlots[slot] = nil
            else
              bar.rememberedSlots[slot] = slot
            end
          end

          if bar.rememberedSlots[slot] == slot then
            drawlist.AddRectFilled(start, start + cellSize, 0x8800FF00)
          elseif bar.rememberedSlots[slot] ~= nil then
            drawlist.AddRectFilled(start, start + cellSize, 0x880000FF)
          end
          ImGui.InvisibleButton("##" .. slot, cellSize)
        end
      end
    end

    ImGui.SetCursorScreenPos(windowPos + Vector2.new(0, cellSize.Y * 5.5))
    if ImGui.Button("Save Gear", Vector2.new(ImGui.GetWindowWidth() / 3 - miscPadding.X, ImGui.GetTextLineHeight()) + miscPadding) then
      for _, profile in ipairs(bar.profiles) do
        if profile.name == bar.profileName then bar.profiles[_] = nil end
      end
      local profile = { name = bar.profileName, gear = bar.rememberedSlots }
      table.insert(bar.profiles, profile)
      bar.activeProfile = profile
      SaveBarSettings(bar, "profiles", bar.profiles)
      bar.dontSave = nil
      bar:resetRemembered()
      bar.imguiReset = true
      bar.renderContext = "showProfilesCtx"
      bar.profileName = ""
      bar.render = bar.showProfiles
    end

    ImGui.SameLine()
    if ImGui.Button("Don't Save", Vector2.new(ImGui.GetWindowWidth() / 3 - miscPadding.X, ImGui.GetTextLineHeight()) + miscPadding) then
      for _, profile in ipairs(bar.profiles) do
        if profile.name == bar.profileName then profile.gear = bar.dontSave end
      end
      bar.dontSave = nil
      bar:resetRemembered()
      bar.imguiReset = true
      bar.renderContext = "showProfilesCtx"
      bar.profileName = ""
      bar.render = bar.showProfiles
    end

    ImGui.SameLine()
    if ImGui.Button("Delete", Vector2.new(ImGui.GetWindowWidth() / 3 - miscPadding.X, ImGui.GetTextLineHeight()) + miscPadding) then
      local profilesCopy = {}
      for _, profile in ipairs(bar.profiles) do
        if profile.name ~= bar.profileName then table.insert(profilesCopy, profile) end
      end
      bar.profiles = profilesCopy
      SaveBarSettings(bar, "profiles", bar.profiles)
      bar.dontSave = nil
      bar:resetRemembered()
      bar.imguiReset = true
      bar.renderContext = "showProfilesCtx"
      bar.profileName = ""
      bar.render = bar.showProfiles
    end
  end,

  showProfiles = function(bar)
    local windowSize = ImGui.GetContentRegionAvail()
    local style = ImGui.GetStyle()
    local miscPadding = style.CellPadding + style.FramePadding + style.ItemSpacing + style.WindowPadding

    ImGui.PushItemWidth(-1)
    local inputChanged
    inputChanged, bar.profileName = ImGui.InputText("##ProfileName", bar.profileName or "", 12, _imgui.ImGuiInputTextFlags.None)
    ImGui.PopItemWidth()

    local isInputActive = ImGui.IsItemActive()
    if bar.profileName == "" and not isInputActive then
      local inputPos = ImGui.GetItemRectMin()
      local textSize = ImGui.CalcTextSize("Profile Name")
      local textPos = Vector2.new(inputPos.X + 5, inputPos.Y + (ImGui.GetItemRectSize().Y - textSize.Y) * 0.5)
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, 0xFF888888)
      ImGui.SetCursorScreenPos(textPos)
      ImGui.Text("Profile Name")
      ImGui.PopStyleColor()
      ImGui.SetCursorPosY(ImGui.GetCursorPosY() - ImGui.GetTextLineHeight())
    end

    if not isInputActive and bar.profileName == "" then ImGui.NewLine() end

    ImGui.PushStyleColor(_imgui.ImGuiCol.Button, 0xFF333333)
    if ImGui.Button((bar.edit or "Create Profile") .. "##attemptNewProfile", Vector2.new(windowSize.X, ImGui.GetTextLineHeight()) + miscPadding) then
      if bar.profileName ~= "" then
        bar.imguiReset = true
        bar.renderContext = "showGearCtx"
        bar:scan()
        bar.render = bar.showGear
      else
        print("Invalid profile name")
      end
    end
    ImGui.PopStyleColor()

    bar.edit = "Create Profile"
    for _, profile in ipairs(bar.profiles) do
      if profile.name == bar.profileName then
        bar.edit = "Edit Profile"
        break
      end
    end

    for _, profile in ipairs(bar.profiles) do
      local screenPos = ImGui.GetCursorScreenPos()
      if ImGui.Button(profile.name .. "##profile" .. tostring(_), Vector2.new(windowSize.X, ImGui.GetTextLineHeight()) + miscPadding) then
        bar:scan()
        bar.activeProfile = profile
        for slot, gearId in pairs(profile.gear) do
          if gearId ~= slot then
            local profileEquipment = game.World.Get(gearId)
            if profileEquipment ~= nil then
              local slotMask = EquipMask[slot]
              local wieldedItem = bar.slots[slot]
              if wieldedItem ~= nil and wieldedItem.Id ~= profileEquipment.Id then
                if not (string.find(slot, "Ring") or string.find(slot, "Bracelet") or string.find(slot, "Weapon") or string.find(slot, "Shield")) then
                  for i, eqslot in ipairs(bar.equipMask) do
                    if eqslot ~= "None" and (profileEquipment.IntValues[IntId.ValidLocations] or 0) + EquipMask[eqslot] == (profileEquipment.IntValues[IntId.ValidLocations] or 0) then
                      if bar.slots[eqslot] ~= eqslot and bar.slots[eqslot].Id ~= profileEquipment.Id then
                        game.Actions.ObjectMove(bar.slots[eqslot].Id, game.CharacterId, 0, false, common.equipmentActionOpts, common.genericActionCallback)
                      end
                    end
                  end
                end
                game.Actions.ObjectWield(profileEquipment.Id, slotMask, common.equipmentActionOpts, function(objectWield)
                  if not objectWield.Success and objectWield.Error ~= ActionError.ItemAlreadyWielded then
                    print("Fail! " .. objectWield.ErrorDetails)
                  end
                end)
              else
                game.Actions.ObjectWield(profileEquipment.Id, slotMask, common.equipmentActionOpts, common.genericActionCallback)
              end
            else
              print("Can't find " .. gearId .. " for slot " .. bar.equipMask[slot])
            end
          else
            local wieldedItem = bar.slots[slot]
            if wieldedItem ~= slot then
              game.Actions.ObjectMove(wieldedItem.Id, game.CharacterId, 0, false, common.equipmentActionOpts, common.genericActionCallback)
            end
          end
        end
        game.Messages.Incoming.Qualities_UpdateInstanceID.Add(bar.watcher)
      end

      if ImGui.IsItemClicked(1) then
        bar.profileName = profile.name
        bar.imguiReset = true
        bar.renderContext = "showGearCtx"
        bar:scan()
        bar.render = bar.showGear
      end

      if bar.activeProfile == profile then
        ImGui.GetWindowDrawList().AddRect(
          screenPos + Vector2.new(1, 0),
          screenPos + Vector2.new(windowSize.X, ImGui.GetTextLineHeight() + miscPadding.Y) - Vector2.new(1, 0),
          0xFF00FF00)
      end
    end
  end,

  render = function(bar)
    bar.renderContext = "showProfilesCtx"
    SaveBarSettings(bar, "renderContext", bar.renderContext)
    bar.render = bar.showProfiles
  end
}
