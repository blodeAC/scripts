local _imgui = require("imgui")
local ImGui = _imgui.ImGui

return {
  name = "HealkitCooldown",
  settings = {
    enabled = false,
    icon_hex = 0x060032E5,
    fontScale_flt = 2,
  },
  init = function(bar)
    game.Character.OnSharedCooldownsChanged.Add(function(cooldownChanged)
      local maybeKit = game.World.Get(cooldownChanged.Cooldown.ObjectId)
      if maybeKit ~= nil and maybeKit.ObjectClass == ObjectClass.HealingKit then
        bar.cooldown = cooldownChanged.Cooldown.ExpiresAt
      end
    end)
  end,
  render = function(bar)
    if bar.cooldown then
      local rem = (bar.cooldown - DateTime.UtcNow).TotalSeconds
      if rem > 0 then
        bar.settings.label_str = string.format("%.1f", rem)
      else
        bar.cooldown = nil
        bar.settings.label_str = nil
      end
    end
    DrawIcon(bar, bar.settings.icon_hex)
  end
}
