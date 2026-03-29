local _imgui = require("imgui")
local acclient = require("acclient")

return {
  name = "Distance",
  type = "text",
  settings = {
    enabled = false,
    fontScale_flt = 1.5,
    icon_hex = 0x060064E5,
    minDistance_num = 35,
    minDistance_col4 = 0xFF00FF00,
    range1_num = 50,
    range1_col4 = 0xFFFFFFFF,
    maxDistance_num = 60,
  },
  windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
  styleColor = {
    { _imgui.ImGuiCol.Text, function(bar)
      local dist = tonumber(bar:text())
      if not dist then
        return 0xFFFFFFFF
      elseif dist > (bar.settings.maxDistance_num or 9999) then
        return 0xFFFFFFFF
      elseif dist > (bar.settings.range1_num or 9999) then
        return bar.settings.range1_col4
      elseif dist >= (bar.settings.minDistance_num or 0) then
        return bar.settings.minDistance_col4
      else
        return 0xFFFFFFFF
      end
    end }
  },
  text = function(bar)
    if game.World.Selected == nil or game.World.Selected.ObjectClass ~= ObjectClass.Monster then return "" end
    local dist = acclient.Coordinates.Me.DistanceToFlat(acclient.Movement.GetPhysicsCoordinates(game.World.Selected.Id)) * 1 / 0.9144
    if not bar.settings.minDistance_num then bar.settings.minDistance_num = 0 end
    if not bar.settings.maxDistance_num then bar.settings.maxDistance_num = 9999 end
    return dist > bar.settings.minDistance_num and dist < bar.settings.maxDistance_num and string.format("%.0f", dist) or ""
  end
}
