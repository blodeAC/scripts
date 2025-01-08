-- Configuration for corpse looting script
local _imgui = require("imgui")
local acclient = require("acclient")

local config = {
  -- Hotkey to initiate looting (Tab key by default)
  LOOTING_HOTKEY = _imgui.ImGuiKey.Tab,

  -- Keys for casting spells without a target
  NOTARGETCAST = { 
    _imgui.ImGuiKey._5
  },

  -- Shape of the marker used to highlight corpses
  markerShape = acclient.DecalD3DShape.VerticalArrow,

  -- Color of the corpse marker (0xAARRBBGG format, red by default)
  shapeColor0xAARRBBGG = 0xFFFF0000,

  -- Scale of the corpse marker (0 to 1)
  shapeScale0to1 = 1.0,

  -- Vertical offset of the corpse marker
  shapeZOffset = 0,

  -- Whether the marker should orient towards the player
  shapeOrientToPlayer = true,

  -- Whether the marker should tilt vertically
  shapeVerticalTilt = false,

  -- Time in seconds after which a corpse gets priority for looting
  corpsePrioritySeconds = 240,

  -- Color of the XP display (0xAARRGGBB format, semi-transparent green by default)
  xpColor0xAARRGGBB = 0x8000FF00,

  -- Scale of the XP display (0 to 1)
  xpScale0to1 = 0.2,

  -- How long the XP display remains visible in seconds
  xpTimeoutSeconds = 2,

  -- Vertical offset of the XP display
  xpZOffset = -0.22,

  -- Whether to enable trophy handling
  trophyHander = true,

  -- Enable debug mode for additional console output
  debug = false
}

return config
