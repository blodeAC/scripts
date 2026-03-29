local _imgui = require("imgui")
local common = require("bar_common")

return {
  name = "debuffs",
  settings = {
    enabled = false,
    icon_hex = 0x06005E6A,
    growAxis_str = "X",
    growAlignmentFlip = true,
    growReverse = false,
    bufferRectX_num = 10,
    bufferRectY_num = 5,
    iconSpacing_num = 10,
    expiryMaxSeconds_num = 9999,
    spellLevelDisplay = true,
    spellLevelColor_col4 = 0xBBBBBBBB,
    buffBorder = true,
    buffBorderColor_col4 = 0x99000099,
    buffBorderThickness_num = 2,
  },
  windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
  init = function(bar)
    bar.displayCriteria = function(enchantment, spell, entry)
      return enchantment.Duration ~= -1
          and not (SpellFlags.Beneficial + spell.Flags == spell.Flags)
          and (not bar.settings.expiryMaxSeconds_num or entry.ExpiresAt < bar.settings.expiryMaxSeconds_num)
    end

    bar.formatSeconds = function(seconds)
      local hours = math.floor(seconds / 3600)
      local minutes = math.floor((seconds % 3600) / 60)
      local remainingSeconds = seconds % 60
      if hours > 0 then
        return string.format("%02d:%02d", hours, minutes)
      elseif minutes > 0 then
        return string.format("%02d:%02d", minutes, remainingSeconds)
      else
        return string.format("%ds", remainingSeconds)
      end
    end
  end,
  render = common.renderBuffs
}
