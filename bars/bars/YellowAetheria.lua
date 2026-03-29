local _imgui = require("imgui")

return {
  name = "YellowAetheria",
  settings = {
    enabled = false,
    icon_hex = 0x060067A2,
    fontScale_flt = 2,
  },
  init = function(bar)
    if game.ServerName ~= "Daralet" then
      print(bar.name .. " disabled due to unusability when not on Daralet")
      bar.render = function() end
      return
    end
    local function scan()
      for _, item in ipairs(game.Character.Equipment) do
        bar.id = nil
        if (item.IntValues[IntId.CurrentWieldedLocation] or 0) == EquipMask[bar.name] then
          bar.id = item.Id
          break
        end
      end
    end
    scan()

    game.Character.OnSharedCooldownsChanged.Add(function(cooldownChanged)
      if bar.id and cooldownChanged.Cooldown.ObjectId == bar.id then
        bar.cooldown = cooldownChanged.Cooldown.ExpiresAt
      end
    end)

    game.Messages.Incoming.Qualities_UpdateInstanceID.Add(function(updateInstance)
      local objectId = updateInstance.Data.ObjectId
      local weenie = game.World.Get(objectId)
      if not weenie or (weenie.IntValues[IntId.ValidLocations] or 0) ~= EquipMask[bar.name] then return end
      if updateInstance.Data.Key == InstanceId.Container and updateInstance.Data.Value == game.CharacterId then
        sleep(333); scan()
      elseif updateInstance.Data.Key == InstanceId.Wielder and updateInstance.Data.Value == 0 then
        sleep(333); scan()
      end
    end)
  end,
  render = function(bar)
    if bar.id and game.World.Exists(bar.id) then
      if bar.cooldown then
        local rem = (bar.cooldown - DateTime.UtcNow).TotalSeconds
        if rem > 0 then
          bar.settings.label_str = string.format("%.1f", rem)
        else
          bar.cooldown = nil
          bar.settings.label_str = nil
        end
      end
      local aetheria = game.World.Get(bar.id)
      local underlay = (aetheria.DataValues[DataId.IconUnderlay] or 0)
      if underlay ~= 0 then
        local cursorPos = require("imgui").ImGui.GetCursorScreenPos()
        DrawIcon(bar, underlay)
        require("imgui").ImGui.SetCursorScreenPos(cursorPos)
      end
      DrawIcon(bar, (aetheria.DataValues[DataId.Icon] or 0))
    else
      DrawIcon(bar, 0x06006C0A)
    end
  end
}
