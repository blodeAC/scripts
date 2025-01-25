local _imgui = require("imgui")
local ImGui = _imgui.ImGui
local config={}

config = {
  maxDistanceForVisibility = 100,
  targetHudConfig={
    windowSettings=_imgui.ImGuiWindowFlags.NoInputs+_imgui.ImGuiWindowFlags.NoBackground,
    hideSelectionHp=true,
    fontScale=1,
    stylevar={
      {_imgui.ImGuiStyleVar.FrameBorderSize, 2},
    },
    styleColor={
      {_imgui.ImGuiCol.Border,0xFFFFFFFF}
    },
    color = 0x800000FF,
    textAlignment = "center",
    ---@param progressBarStartPos Vector2
    ---@param progressBarSize Vector2
    text = function(progressBarStartPos,progressBarSize)
      local blankLine= " "
      local centeredText={
        target.name,
        blankLine
      }
      local rightText={
        blankLine,
        target.maxHp and ((tostring(math.floor(target.hp*target.maxHp+0.5)) .. " / " .. tostring(target.maxHp)) .. " ") or (tostring(math.floor(target.hp*100)) .. "%%")
      }
      local leftText={
        blankLine,
        tostring(game.World.Get(target.id).Value(IntId.Level))~="0" and ("  "..tostring(game.World.Get(target.id).Value(IntId.Level))) or "  ??"
      }
      for i,text in ipairs(leftText) do
        local textSize=ImGui.CalcTextSize(text)
        local Yadjustment=i*(progressBarSize.Y/#centeredText)-textSize.Y
        local startPos = progressBarStartPos + Vector2.new(0,Yadjustment)
        ImGui.SetCursorScreenPos(startPos)
        ImGui.Text(text)
      end
      for i,text in ipairs(centeredText) do
        local textSize=ImGui.CalcTextSize(text)
        local Yadjustment=i*(progressBarSize.Y/#centeredText)-textSize.Y
        local startPos = progressBarStartPos + Vector2.new(progressBarSize.X/2-textSize.X/2, Yadjustment)
        ImGui.SetCursorScreenPos(startPos)
        ImGui.Text(text)
      end
      for i,text in ipairs(rightText) do
        local textSize=ImGui.CalcTextSize(text)
        local Yadjustment=i*(progressBarSize.Y/#centeredText)-textSize.Y
        local startPos = progressBarStartPos + Vector2.new(progressBarSize.X-textSize.X,Yadjustment)
        ImGui.SetCursorScreenPos(startPos)
        ImGui.Text(text)
      end
    end
  }
}
return config