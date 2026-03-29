local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local acclient = require("acclient")

return {
  name = "^mobPointer",
  settings = {
    enabled = false,
    fontScale_flt = 1,
    icon_hex = 0x060069F6,
    mobToSearch = ""
  },
  init = function(bar)
    bar.settings.mobToSearch = bar.settings.mobToSearch or ""
    bar.mobIndex = 1

    bar.findMobByName = function(name)
      local matchingMobs = {}
      if name ~= "" then
        for _, object in ipairs(game.World.GetLandscape()) do
          if object ~= game.Character.Weenie then
            if string.find(string.lower(object.Name), string.lower(name)) then
              table.insert(matchingMobs, {
                Id = object.Id,
                Name = object.Name,
                Distance = function() return acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(object.Id)) end,
              })
            end
          end
        end
        table.sort(matchingMobs, function(a, b) return a.Distance() < b.Distance() end)
      end
      return matchingMobs
    end

    bar.insertMob = function(newMobId, attempt)
      bar.removeMob(newMobId)
      local weenie = game.World.Get(newMobId)
      if not weenie then
        attempt = attempt and attempt + 1 or 2
        if attempt and attempt <= 3 then
          game.OnTick.Once(function() bar.insertMob(newMobId, attempt) end)
        end
        return
      end
      local newMob = {
        Id = weenie.Id,
        Name = weenie.Name,
        Distance = function() return acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(weenie.Id)) end,
      }

      if #bar.currentMobs == 0 then
        table.insert(bar.currentMobs, newMob)
      else
        for i, mob in ipairs(bar.currentMobs) do
          if newMob.Distance() < mob.Distance() then
            table.insert(bar.currentMobs, i, newMob)
            if i <= bar.mobIndex then bar.mobIndex = bar.mobIndex + 1 end
            break
          end
        end
      end
    end

    bar.renderArrowToMob = function(distance)
      local currentMob = bar.currentMobs[bar.mobIndex]
      local angleToMob = math.rad(acclient.Coordinates.Me.HeadingTo(acclient.Movement.GetPhysicsCoordinates(currentMob.Id)))
      local relativeAngle = angleToMob - math.rad(acclient.Movement.Heading - 270)

      if relativeAngle < 0 then relativeAngle = relativeAngle + 2 * math.pi
      elseif relativeAngle > 2 * math.pi then relativeAngle = relativeAngle - 2 * math.pi end

      local windowPos = ImGui.GetWindowPos()
      local drawList = ImGui.GetWindowDrawList()
      local windowSize = ImGui.GetWindowSize()
      local previousElementsHeight = 50
      local centerX = windowPos.X + windowSize.X / 2
      local centerY = windowPos.Y + previousElementsHeight + (windowSize.Y - previousElementsHeight) / 2
      local arrowLength = math.min(windowSize.Y - previousElementsHeight, windowSize.X) * 0.8
      local arrowWidth = arrowLength * 0.8

      local tipX = centerX + math.cos(relativeAngle) * (arrowLength / 2)
      local tipY = centerY + math.sin(relativeAngle) * (arrowLength / 2)
      local baseAngle1 = relativeAngle + math.pi * 5 / 6
      local baseAngle2 = relativeAngle - math.pi * 5 / 6
      local baseX1 = centerX + math.cos(baseAngle1) * (arrowWidth / 2)
      local baseY1 = centerY + math.sin(baseAngle1) * (arrowWidth / 2)
      local baseX2 = centerX + math.cos(baseAngle2) * (arrowWidth / 2)
      local baseY2 = centerY + math.sin(baseAngle2) * (arrowWidth / 2)

      local minX = math.min(tipX, baseX1, baseX2)
      local minY = math.min(tipY, baseY1, baseY2)
      local maxX = math.max(tipX, baseX1, baseX2)
      local maxY = math.max(tipY, baseY1, baseY2)

      ImGui.SetCursorScreenPos(Vector2.new(minX, minY))
      ImGui.InvisibleButton("ArrowClick", Vector2.new(maxX - minX, maxY - minY))
      if ImGui.IsItemClicked() then
        game.Actions.ObjectSelect(currentMob.Id)
      end

      local function interpolateColor(dist)
        local r, g = 255, 0
        if dist > 80 then dist = 80 elseif dist < 5 then dist = 5 end
        if dist > 40 then
          local factor = (dist - 40) / 40
          g = math.floor(255 * (1 - factor))
        else
          local factor = dist / 40
          r = math.floor(255 * factor)
          g = 255
        end
        return 0xFF000000 + (r * 0x1) + (g * 0x100)
      end

      local arrowColor = interpolateColor(distance)
      drawList.AddTriangleFilled(Vector2.new(tipX, tipY), Vector2.new(baseX1, baseY1), Vector2.new(baseX2, baseY2), arrowColor)
      drawList.AddTriangle(Vector2.new(tipX, tipY), Vector2.new(baseX1, baseY1), Vector2.new(baseX2, baseY2), 0xFFFFFFFF, 1.0)
    end

    bar.removeMob = function(removeMobId)
      for i, mob in ipairs(bar.currentMobs) do
        if removeMobId == mob.Id then
          bar.currentMobs[i] = nil
          break
        end
      end
    end

    game.World.OnObjectCreated.Add(function(e)
      if bar.settings.mobToSearch ~= "" and game.World.Get(e.ObjectId).Container == nil and
          string.find(string.lower(game.World.Get(e.ObjectId).Name), string.lower(bar.settings.mobToSearch)) then
        if game.Character.InPortalSpace then
          game.Character.OnPortalSpaceExited.Once(function() bar.insertMob(e.ObjectId) end)
        else
          bar.insertMob(e.ObjectId)
        end
      end
    end)

    game.Messages.Incoming.Inventory_PickupEvent.Add(function(e) bar.removeMob(e.Data.ObjectId) end)
    game.World.OnObjectReleased.Add(function(e) bar.removeMob(e.ObjectId) end)

    game.Character.Weenie.OnPositionChanged.Add(function(e)
      if bar.currentMobs and bar.currentMobs[bar.mobIndex] then
        local myMobId = bar.currentMobs[bar.mobIndex].Id
        if #bar.currentMobs > 1 then
          table.sort(bar.currentMobs, function(a, b) return a.Distance() < b.Distance() end)
          for i, mob in ipairs(bar.currentMobs) do
            if mob.Id == myMobId then bar.mobIndex = i; break end
          end
        end
      end
    end)

    if game.Character.InPortalSpace then
      game.Character.OnPortalSpaceExited.Once(function()
        bar.currentMobs = bar.findMobByName(bar.settings.mobToSearch)
      end)
    else
      bar.currentMobs = bar.findMobByName(bar.settings.mobToSearch)
    end
  end,

  render = function(bar)
    ImGui.Text("  ")
    ImGui.SameLine()

    ImGui.PushItemWidth(-1)
    local inputChanged, newMobName = ImGui.InputText("###MobNameInput", bar.settings.mobToSearch, 24, _imgui.ImGuiInputTextFlags.None)
    ImGui.PopItemWidth()

    local isInputActive = ImGui.IsItemActive()

    if bar.settings.mobToSearch == "" and not isInputActive then
      local inputPos = ImGui.GetItemRectMin()
      local textSize = ImGui.CalcTextSize("Mob Name")
      local textPos = Vector2.new(inputPos.X + 5, inputPos.Y + (ImGui.GetItemRectSize().Y - textSize.Y) * 0.5)
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, 0xFF888888)
      ImGui.SetCursorScreenPos(textPos)
      ImGui.Text("Mob Name")
      ImGui.PopStyleColor()
      ImGui.SetCursorPosY(ImGui.GetCursorPosY() - ImGui.GetTextLineHeight())
    end

    if inputChanged and ImGui.IsKeyPressed(_imgui.ImGuiKey.Enter) then
      bar.settings.mobToSearch = newMobName or ""
      SaveBarSettings(bar, "settings.mobToSearch", bar.settings.mobToSearch)
      bar.currentMobs = bar.findMobByName(bar.settings.mobToSearch)
    end

    if not isInputActive and (bar.settings.mobToSearch == nil or bar.settings.mobToSearch == "") then
      ImGui.Text(" ")
    end

    if bar.currentMobs ~= nil and #bar.currentMobs > 0 then
      if bar.mobIndex > #bar.currentMobs then bar.mobIndex = #bar.currentMobs end
      local distance = acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(bar.currentMobs[bar.mobIndex].Id))
      ImGui.Text(string.format("  %s (%.2f m)", bar.currentMobs[bar.mobIndex].Name, distance))
      bar.renderArrowToMob(distance)
    else
      ImGui.Text("  No matching mob detected")
    end

    if bar.currentMobs ~= nil and #bar.currentMobs > 1 then
      local buttonSize = Vector2.new(ImGui.GetTextLineHeight(), ImGui.GetTextLineHeight())
      local buttonY = ImGui.GetWindowContentRegionMax().Y - ImGui.GetTextLineHeightWithSpacing()
      ImGui.SetCursorPos(Vector2.new(ImGui.GetWindowContentRegionMin().X, buttonY))
      if ImGui.Button("-##mobIndexLessOne", buttonSize) then
        bar.mobIndex = bar.mobIndex - 1
        if bar.mobIndex == 0 then bar.mobIndex = #bar.currentMobs end
      end

      local displayText = tostring(bar.mobIndex) .. " / " .. tostring(#bar.currentMobs)
      ImGui.SetCursorPos(Vector2.new((ImGui.GetWindowContentRegionMax().X - ImGui.GetWindowContentRegionMin().X) / 2 - ImGui.CalcTextSize(displayText).X / 2, buttonY + ImGui.GetStyle().CellPadding.Y))
      ImGui.Text(displayText)

      ImGui.SetCursorPos(Vector2.new(ImGui.GetWindowContentRegionMax().X - buttonSize.X - ImGui.GetStyle().FramePadding.X, buttonY))
      if ImGui.Button("+##mobIndexPlusOne", Vector2.new(ImGui.GetTextLineHeight(), ImGui.GetTextLineHeight())) then
        bar.mobIndex = bar.mobIndex + 1
        if bar.mobIndex > #bar.currentMobs then bar.mobIndex = 1 end
      end
    end
  end
}
