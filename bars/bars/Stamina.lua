local _imgui = require("imgui")
local vitals = game.Character.Weenie.Vitals

return {
  name           = "Stamina",
  type           = "progress",
  settings       = {
    enabled             = false,
    color_col4          = 0xAA00AAAA,
    icon_hex            = 0x060069E8,
    textAlignment_combo = { 2, "left", "center", "right" },
  },
  windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
  styleVar       = {
    { _imgui.ImGuiStyleVar.FrameBorderSize, 2 }
  },
  styleColor     = {
    { _imgui.ImGuiCol.Border, 0xFFFFFFFF }
  },
  max            = function() return vitals[VitalId.Stamina].Max end,
  value          = function() return vitals[VitalId.Stamina].Current end,
  text           = function() return "  " .. vitals[VitalId.Stamina].Current .. " / " .. vitals[VitalId.Stamina].Max end
}
