local _imgui = require("imgui")
return {
  maxDistanceForVisibility = 100,
  targetHudConfig={
    windowSettings=_imgui.ImGuiWindowFlags.NoInputs+_imgui.ImGuiWindowFlags.NoBackground,
    hideSelectionHp=true,
    fontScale=1,
    borderSize=2,
    borderColor=0xFFFFFFFF, --0xAABBGGRR
    color = 0x800000FF,
    textAlignment = "center",
    text = function(target)
      if target.maxHp then
        return target.name .. "  (".. tostring(math.floor(target.hp*target.maxHp+0.5)) .. " / " .. tostring(target.maxHp) ..")"
      else
        return " " .. target.name
      end
    end
  }
}