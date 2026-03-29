local _imgui = require("imgui")
local common = require("bar_common")

return {
  name = "OneTouchHeal",
  settings = {
    enabled = false,
    useHotkey = false,
    icon_hex = 0x060032F3,
    fontScale_flt = 2.0,
    hotkey_combo = { 87, table.unpack(common.imguiHotkeys) }
  },
  init = function(bar)
    game.Character.OnSharedCooldownsChanged.Add(function(cooldownEvent)
      local maybeKit = game.World.Get(cooldownEvent.Cooldown.ObjectId)
      if maybeKit and maybeKit.ObjectClass == ObjectClass.HealingKit then
        bar.cooldown = cooldownEvent.Cooldown.ExpiresAt
      end
    end)
  end,
  healfunc = function()
    local bestKit, bestMod = nil, -1
    local hasUsableKit = false

    for i, kit in ipairs(game.Character.GetInventory(ObjectClass.HealingKit) or {}) do
      if not kit.HasAppraisalData then
        await(kit.Appraise())
      end

      local mod = kit.FloatValues[FloatId.HealkitMod] or 0.0
      local structure = kit.IntValues[IntId.Structure] or 0

      if structure > 0 then
        if not hasUsableKit or mod > bestMod then
          bestKit, bestMod = kit, mod
          hasUsableKit = true
        end
      elseif not hasUsableKit and mod > bestMod then
        bestKit, bestMod = kit, mod
      end
    end

    if not bestKit then
      print("No healing kits")
    else
      game.Actions.ObjectUse(bestKit.Id, game.CharacterId, common.genericActionOpts)
    end
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

    DrawIcon(bar, bar.settings.icon_hex, false, bar.healfunc)

    if bar.settings.useHotkey and _imgui.ImGui.IsKeyPressed(_imgui.ImGuiKey[bar.settings.hotkey_combo[bar.settings.hotkey_combo[1] + 1]], false) then
      game.OnRender2D.Once(bar.healfunc)
    end
  end
}
