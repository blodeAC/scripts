local _imgui = require("imgui")
local common = require("bar_common")

return {
  name = "render_damageTaken",
  windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
  settings = {
    enabled = false,
    icon_hex = 0x060028FD,
    fontScaleMin_flt = 2,
    fontScaleMax_flt = 3,
    fontColorPositive_col3 = 0x00FF00,
    fontColorNegative_col3 = 0x0000FF,
    fadeDuration_num = 2,
    floatSpeed_num = 1,
  },
  entries = {},
  runningSum = 0,
  runningCount = 0,

  init = function(bar)
    game.Character.OnVitalChanged.Add(function(changedVital)
      if changedVital.Type == VitalId.Health then
        local delta = changedVital.Value - changedVital.OldValue
        table.insert(bar.entries, {
          text = tostring(delta),
          value = math.abs(delta),
          positive = delta > 0,
          time = os.clock(),
        })
        bar.runningSum = bar.runningSum + math.abs(delta)
        bar.runningCount = bar.runningCount + 1
      end
    end)
  end,

  render = common.renderEvent
}
