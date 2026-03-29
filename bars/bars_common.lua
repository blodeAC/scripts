local _imgui = require("imgui")

local M = {}

M.imguiHotkeys = {"Tab","LeftArrow","RightArrow","UpArrow","DownArrow","PageUp","PageDown","Home","End","Insert","Delete","Backspace","Space","Enter","Escape","LeftCtrl","LeftShift","LeftAlt","LeftSuper","RightCtrl","RightShift","RightAlt","RightSuper","Menu","_0","_1","_2","_3","_4","_5","_6","_7","_8","_9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","Apostrophe","Comma","Minus","Period","Slash","Semicolon","Equal","LeftBracket","Backslash","RightBracket","GraveAccent","CapsLock","ScrollLock","NumLock","PrintScreen","Pause","Keypad0","Keypad1","Keypad2","Keypad3","Keypad4","Keypad5","Keypad6","Keypad7","Keypad8","Keypad9","KeypadDecimal","KeypadDivide","KeypadMultiply","KeypadSubtract","KeypadAdd","KeypadEnter","KeypadEqual"}

M.genericActionOpts = ActionOptions.new()
M.genericActionOpts.MaxRetryCount = 0
M.genericActionOpts.TimeoutMilliseconds = 100
M.genericActionOpts.SkipChecks = true

M.genericActionCallback = function(e)
  if not e.Success then
    if e.Error ~= ActionError.ItemAlreadyWielded then
      print("Fail! " .. e.ErrorDetails)
    end
  end
end

M.equipmentActionOpts = ActionOptions.new()
M.equipmentActionOpts.MaxRetryCount = 3
M.equipmentActionOpts.TimeoutMilliseconds = 250

-- Set by bars.lua after loading so bar funcs can reference sibling bars at runtime
M._bars = nil
function M.getBars()
  return M._bars
end
function M.setBars(bars)
  M._bars = bars
end

function M.sortbag(bar, inscription, containerHolder, func)
  if bar.sortBag == nil or game.World.Exists(bar.sortBag) == false then
    for _, bag in ipairs(containerHolder.Containers) do
      await(game.Actions.ObjectAppraise(bag.Id))
      if (bag.StringValues[StringId.Inscription] or "") == inscription then
        bar.sortBag = bag.Id
        SaveBarSettings(bar, "sortBag", bag.Id)
        return
      end
    end
  else
    func(bar)
  end
end

function M.renderEvent(bar)
  local ImGui = _imgui.ImGui
  local currentTime = os.clock()
  local validEntries = {}
  local average = (bar.runningCount > 0) and (bar.runningSum / bar.runningCount) or 1

  local windowSize = ImGui.GetContentRegionAvail()
  local lastEntry = nil
  local minSpacingX = 20

  for i, entry in ipairs(bar.entries) do
    local elapsed = currentTime - entry.time
    if elapsed <= bar.settings.fadeDuration_num then
      local alpha = 1 - (elapsed / bar.settings.fadeDuration_num)
      local color = tonumber(
        string.format("%02X%06X", math.floor(alpha * 255),
          entry.positive and bar.settings.fontColorPositive_col3 or bar.settings.fontColorNegative_col3),
        16)

      if not entry.scale then
        entry.scale = string.sub(entry.text, -1) == "!" and entry.fontScaleCrit_flt or
            math.min(math.max((entry.value or average) / average, bar.settings.fontScaleMin_flt), bar.settings.fontScaleMax_flt)
      end
      ImGui.SetWindowFontScale(entry.scale)

      local floatDistance = (elapsed / bar.settings.fadeDuration_num) * windowSize.Y
      entry.cursorPosY = windowSize.Y - floatDistance - ImGui.GetFontSize()

      if entry.cursorPosX == nil then
        entry.textSize = ImGui.CalcTextSize(entry.text)
        local baseX = (windowSize.X - entry.textSize.X) / 2
        entry.cursorPosX = baseX

        if lastEntry then
          local conflict = function()
            return (lastEntry.cursorPosY + lastEntry.textSize.Y - entry.cursorPosY) > 0 and
                (lastEntry.cursorPosX + lastEntry.textSize.X - entry.cursorPosX) > 0
          end
          if conflict() then
            entry.cursorPosX = baseX + lastEntry.textSize.X + minSpacingX
            if entry.cursorPosX + entry.textSize.X > windowSize.X or conflict() then
              entry.cursorPosX = lastEntry.cursorPosX - entry.textSize.X - minSpacingX
            end
          end
        end
      end

      ImGui.SetCursorPos(Vector2.new(entry.cursorPosX, entry.cursorPosY))
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, color)
      ImGui.Text(entry.text)
      ImGui.PopStyleColor()
      ImGui.SetWindowFontScale(1)

      table.insert(validEntries, entry)
    else
      if entry.value and bar.runningCount > 10 then
        bar.runningSum = bar.runningSum - entry.value
        bar.runningCount = bar.runningCount - 1
      end
    end
    lastEntry = entry
  end

  bar.entries = validEntries
end

function M.renderBuffs(bar)
  local ImGui = _imgui.ImGui
  local buffs = {}

  for _, enchantment in ipairs(game.Character.ActiveEnchantments()) do
    local spell = game.Character.SpellBook.Get(enchantment.SpellId)
    local entry = {}
    entry.ClientReceivedAt = enchantment.ClientReceivedAt
    entry.Duration = enchantment.Duration
    entry.StartTime = enchantment.StartTime
    if entry.Duration > -1 then
      entry.ExpiresAt = (entry.ClientReceivedAt + TimeSpan.FromSeconds(entry.StartTime + entry.Duration) - DateTime.UtcNow).TotalSeconds
    else
      entry.ExpiresAt = 999999
    end

    if bar.displayCriteria(enchantment, spell, entry) then
      entry.Name = spell.Name or "Unknown"
      entry.Id = spell.Id or "No spell.Id"
      entry.Level = ({ "I", "II", "III", "IV", "V", "VI", "VII", "VIII" })[spell.Level]
      entry.icon = spell.Icon or 9914

      local function hasFlag(object, flag)
        return (object.Flags + flag == object.Flags)
      end

      local statKey = spell.StatModKey
      if spell.StatModAttribute ~= AttributeId.Undef then
        entry.stat = tostring(AttributeId.Undef + statKey)
      elseif spell.StatModVital ~= Vital.Undef then
        entry.stat = tostring(Vital.Undef + statKey)
      elseif spell.StatModSkill ~= SkillId.Undef then
        entry.stat = tostring(SkillId.Undef + statKey)
      elseif spell.StatModIntProp ~= IntId.Undef then
        entry.stat = tostring(IntId.Undef + statKey)
      elseif spell.StatModFloatProp ~= FloatId.Undef then
        entry.stat = tostring(FloatId.Undef + statKey)
      else
        entry.stat = tostring(enchantment.Category)
      end

      if hasFlag(enchantment, EnchantmentFlags.Additive) then
        entry.printProp = enchantment.StatValue > 0 and ("+" .. enchantment.StatValue) or enchantment.StatValue
      elseif hasFlag(enchantment, EnchantmentFlags.Multiplicative) then
        local percent = enchantment.StatValue - 1
        entry.printProp = (percent > 0 and ("+" .. string.format("%.0d", percent * 100)) or string.format("%.0d", percent * 100)) .. "%%"
      end

      table.insert(buffs, entry)
    end
  end

  table.sort(buffs, function(a, b)
    return a.ClientReceivedAt < b.ClientReceivedAt
  end)

  local windowPos = ImGui.GetWindowPos() + Vector2.new(5, 5)
  local windowSize = ImGui.GetContentRegionAvail()
  local minX, minY, maxX, maxY
  local iconSize = Vector2.new(28, 28)
  local bufferRect_vec2 = Vector2.new(bar.settings.bufferRectX_num, bar.settings.bufferRectY_num)

  ImGui.BeginChild("ScrollableChild", ImGui.GetContentRegionAvail(), true, bar.windowSettings or 0)
  for i, buff in ipairs(buffs) do
    local cursorStartX, cursorStartY
    local expiryTimer = (buff.ClientReceivedAt + TimeSpan.FromSeconds(buff.StartTime + buff.Duration) - DateTime.UtcNow).TotalSeconds
    local spellLevelSize_vec2 = ImGui.CalcTextSize(buff.Level)

    local reservedPerIconX = iconSize.X + bufferRect_vec2.X + bar.settings.iconSpacing_num
    local reservedPerIconY = iconSize.Y + bufferRect_vec2.Y + bar.settings.iconSpacing_num + ImGui.GetTextLineHeight() * 1.5

    if bar.settings.growAxis_str == "X" then
      if not bar.settings.growReverse then
        cursorStartX = windowPos.X + (i - 1) * reservedPerIconX
        cursorStartY = windowPos.Y + (bar.settings.growAlignmentFlip and windowSize.Y - reservedPerIconY or 0)
        if i > 1 and (cursorStartX + reservedPerIconX) > (windowPos.X + windowSize.X) then
          local iconsPerRow = math.floor(windowSize.X / reservedPerIconX)
          local rowOffset = 1
          while rowOffset < i and iconsPerRow * rowOffset < i do rowOffset = rowOffset + 1 end
          cursorStartX = windowPos.X + math.floor((i - 1) - iconsPerRow * rowOffset + iconsPerRow) * reservedPerIconX
          cursorStartY = windowPos.Y + (bar.settings.growAlignmentFlip and windowSize.Y - reservedPerIconY or 0) +
              (bar.settings.growAlignmentFlip and -rowOffset + 1 or rowOffset - 1) * reservedPerIconY
        end
      else
        cursorStartX = windowPos.X + windowSize.X - i * reservedPerIconX
        cursorStartY = windowPos.Y + (bar.settings.growAlignmentFlip and windowSize.Y - reservedPerIconY or 0)
        if i > 1 and cursorStartX < windowPos.X then
          local iconsPerRow = math.floor(windowSize.X / reservedPerIconX)
          local rowOffset = 1
          while rowOffset < i and iconsPerRow * rowOffset < i do rowOffset = rowOffset + 1 end
          cursorStartX = windowPos.X + windowSize.X - math.floor(i - iconsPerRow * rowOffset + iconsPerRow) * reservedPerIconX
          cursorStartY = windowPos.Y + (bar.settings.growAlignmentFlip and windowSize.Y - reservedPerIconY or 0) +
              (bar.settings.growAlignmentFlip and -rowOffset + 1 or rowOffset - 1) * reservedPerIconY
        end
      end
    elseif bar.settings.growAxis_str == "Y" then
      if not bar.settings.growReverse then
        cursorStartX = windowPos.X + (bar.settings.growAlignmentFlip and windowSize.X - reservedPerIconX or 0)
        cursorStartY = windowPos.Y + (i - 1) * reservedPerIconY
        if i > 1 and (cursorStartY + reservedPerIconY) > (windowPos.Y + windowSize.Y) then
          local iconsPerCol = math.floor(windowSize.Y / reservedPerIconY)
          local colOffset = 1
          while colOffset < i and iconsPerCol * colOffset < i do colOffset = colOffset + 1 end
          cursorStartX = windowPos.X + (bar.settings.growAlignmentFlip and windowSize.X - reservedPerIconX or 0) +
              (bar.settings.growAlignmentFlip and -colOffset + 1 or colOffset - 1) * reservedPerIconX
          cursorStartY = windowPos.Y + math.floor((i - 1) - iconsPerCol * colOffset + iconsPerCol) * reservedPerIconY
        end
      else
        cursorStartX = windowPos.X + (bar.settings.growAlignmentFlip and windowSize.X - reservedPerIconX or 0)
        cursorStartY = windowPos.Y + windowSize.Y - i * reservedPerIconY
        if i > 1 and cursorStartY < windowPos.Y then
          local iconsPerCol = math.floor(windowSize.Y / reservedPerIconY)
          local colOffset = 1
          while colOffset < i and iconsPerCol * colOffset < i do colOffset = colOffset + 1 end
          cursorStartX = windowPos.X + (bar.settings.growAlignmentFlip and windowSize.X - reservedPerIconX or 0) +
              (bar.settings.growAlignmentFlip and -colOffset + 1 or colOffset - 1) * reservedPerIconX
          cursorStartY = windowPos.Y + windowSize.Y - math.floor(i - iconsPerCol * colOffset + iconsPerCol) * reservedPerIconY
        end
      end
    end

    if not minX or minX > cursorStartX then minX = cursorStartX end
    if not minY or minY > cursorStartY then minY = cursorStartY end
    if not maxX or maxX < cursorStartX then maxX = cursorStartX end
    if not maxY or maxY < cursorStartY then maxY = cursorStartY end

    local cursorStart = Vector2.new(cursorStartX, cursorStartY)
    ImGui.GetWindowDrawList().AddRectFilled(cursorStart,
      cursorStart + iconSize + bufferRect_vec2 + Vector2.new(0, ImGui.GetTextLineHeight() + spellLevelSize_vec2.Y / 2),
      0xAA000000)

    ImGui.SetCursorScreenPos(cursorStart + bufferRect_vec2 / 2 + Vector2.new(0, spellLevelSize_vec2.Y / 2))
    ImGui.TextureButton("##buff" .. buff.Id, GetOrCreateTexture(buff.icon), iconSize)
    if ImGui.IsItemHovered() then
      ImGui.BeginTooltip()
      ImGui.Text(buff.Name)
      ImGui.Text(buff.stat)
      ImGui.SameLine()
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, 0xFF00FF00)
      ImGui.Text(" " .. buff.printProp)
      ImGui.PopStyleColor()
      ImGui.EndTooltip()
    end

    if bar.settings.spellLevelDisplay and buff.Level then
      ImGui.SetCursorScreenPos(cursorStart + Vector2.new(bufferRect_vec2.X / 2 + iconSize.X / 2 - spellLevelSize_vec2.X / 2, 0))
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, bar.settings.spellLevelColor_col4)
      ImGui.Text(buff.Level)
      ImGui.PopStyleColor()
    end

    local expiryTextSize = ImGui.CalcTextSize(bar.formatSeconds(expiryTimer))
    ImGui.SetCursorScreenPos(cursorStart + Vector2.new(
      bufferRect_vec2.X / 2 + iconSize.X / 2 - expiryTextSize.X / 2,
      iconSize.Y + bufferRect_vec2.Y / 2 + spellLevelSize_vec2.Y / 2))
    ImGui.Text(bar.formatSeconds(expiryTimer))
  end
  ImGui.EndChild()

  if bar.settings.buffBorder and minX and minY and maxX and maxY then
    ImGui.GetWindowDrawList().AddRect(
      Vector2.new(minX - 3, minY - 3),
      Vector2.new(maxX + 3 + iconSize.X + bufferRect_vec2.X, maxY + 3 + iconSize.Y + bufferRect_vec2.Y + ImGui.GetTextLineHeight() * 1.5),
      bar.settings.buffBorderColor_col4 or 0x99000099, 0, 0, bar.settings.buffBorderThickness_num or 2)
  end
end

return M
