local _imgui = require("imgui")
local vitals = game.Character.Weenie.Vitals

return {
  name           = "Mana",
  type           = "progress",
  settings       = {
    enabled             = false,
    color_col4          = 0xAAAA0000,
    icon_hex            = 0x060069EA,
    textAlignment_combo = { 2, "left", "center", "right" },
  },
  windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
  styleVar       = {
    { _imgui.ImGuiStyleVar.FrameBorderSize, 2 }
  },
  styleColor     = {
    { _imgui.ImGuiCol.Border, 0xFFFFFFFF }
  },
  max            = function() return vitals[VitalId.Mana].Max end,
  value          = function() return vitals[VitalId.Mana].Current end,
  text           = function() return "  " .. vitals[VitalId.Mana].Current .. " / " .. vitals[VitalId.Mana].Max end
}
