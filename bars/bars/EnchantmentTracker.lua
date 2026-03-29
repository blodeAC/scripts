local _imgui = require("imgui")
local ImGui = _imgui.ImGui

return {
  name = "EnchantmentTracker",
  settings = {
    enabled = false,
    showItemBuffs = false,
    reverseSort = false,
    sortingOptions_combo = { 1, "Name", "Id", "Category", "StatModType", "ExpiresAt", "Level", "Power" }
  },
  init = function(bar)
    function bar.formatSeconds(seconds)
      local hours = math.floor(seconds / 3600)
      local minutes = math.floor((seconds % 3600) / 60)
      local remainingSeconds = seconds % 60
      if hours > 0 then
        return string.format("%02d:%02d", hours, minutes)
      else
        return string.format("%02d:%02d", minutes, remainingSeconds)
      end
    end
  end,
  render = function(bar)
    local activeSpells = { buffs = {}, debuffs = {} }

    for _, enchantment in ipairs(game.Character.ActiveEnchantments()) do
      local spell = game.Character.SpellBook.Get(enchantment.SpellId)
      if bar.settings.showItemBuffs or enchantment.Duration ~= -1 then
        local entry = {}
        entry.Name = spell.Name or "Unknown"
        entry.Id = spell.Id or "No spell.Id"
        entry.Category = enchantment.Category or spell.Category or "No category"
        entry.StatModType = spell.StatModType
        entry.Level = spell.Level or "No spell.Level"
        entry.Power = enchantment.Power
        entry.ClientReceivedAt = enchantment.ClientReceivedAt
        entry.Duration = enchantment.Duration
        entry.StartTime = enchantment.StartTime
        if entry.Duration > -1 then
          entry.ExpiresAt = (entry.ClientReceivedAt + TimeSpan.FromSeconds(entry.StartTime + entry.Duration) - DateTime.UtcNow).TotalSeconds
        else
          entry.ExpiresAt = 999999
        end
        entry.casterId = enchantment.CasterId
        entry.displayOrder = spell.DisplayOrder or 9999
        entry.isBuff = (SpellFlags.Beneficial + spell.Flags == spell.Flags)
        entry.icon = spell.Icon or 0x060011F7

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

        local key = entry.isBuff and "buffs" or "debuffs"
        local added = false
        for i, buffOrDebuff in ipairs(activeSpells[key]) do
          if buffOrDebuff.Category == entry.Category then
            if buffOrDebuff.Power == entry.Power and buffOrDebuff.ClientReceivedAt < entry.ClientReceivedAt then
              activeSpells[key][i] = entry
              added = true
              break
            elseif buffOrDebuff.Power < entry.Power then
              activeSpells[key][i] = entry
              added = true
              break
            end
          end
        end
        if not added then
          table.insert(activeSpells[key], entry)
        end
      end
    end

    local sortKey = bar.settings.sortingOptions_combo[bar.settings.sortingOptions_combo[1] + 1]
    for i, buffsOrDebuffs in pairs(activeSpells) do
      table.sort(buffsOrDebuffs, function(a, b)
        if bar.settings.reverseSort then
          return a[sortKey] > b[sortKey]
        else
          return a[sortKey] < b[sortKey]
        end
      end)
    end

    local checkboxSize = Vector2.new(24, 24)
    local reservedHeight = checkboxSize.Y + ImGui.GetStyle().ChildBorderSize * 2
    local availableSize = ImGui.GetContentRegionAvail()
    local tableSize = Vector2.new(availableSize.X, availableSize.Y - reservedHeight)

    if ImGui.BeginTable("Buffs | Debuffs", 2, _imgui.ImGuiTableFlags.SizingStretchSame + _imgui.ImGuiTableFlags.Resizable, tableSize) then
      ImGui.TableSetupColumn(" Buffs", _imgui.ImGuiTableColumnFlags.WidthStretch)
      ImGui.TableSetupColumn(" Debuffs", _imgui.ImGuiTableColumnFlags.WidthStretch)
      ImGui.TableHeadersRow()

      for column, buffsOrDebuffs in ipairs({ activeSpells.buffs, activeSpells.debuffs }) do
        ImGui.TableNextColumn()

        local borderPadding = ImGui.GetStyle().FrameBorderSize * 2
        local columnWidth = ImGui.GetColumnWidth()
        local columnHeight = ImGui.GetContentRegionAvail().Y - reservedHeight - borderPadding

        ImGui.BeginChild("ScrollableColumn##" .. column, Vector2.new(columnWidth, columnHeight), true)
        for _, buffOrDebuff in ipairs(buffsOrDebuffs) do
          local cursorStart = ImGui.GetCursorScreenPos()
          local iconSize = Vector2.new(28, 28)
          local printProp = buffOrDebuff.printProp

          local expiryTimer
          local backgroundColor = ImGui.GetColorU32(_imgui.ImGuiCol.ChildBg)
          if buffOrDebuff.Duration > -1 then
            expiryTimer = (buffOrDebuff.ClientReceivedAt + TimeSpan.FromSeconds(buffOrDebuff.StartTime + buffOrDebuff.Duration) - DateTime.UtcNow).TotalSeconds
            ImGui.PushStyleColor(_imgui.ImGuiCol.PlotHistogram, buffOrDebuff.isBuff and 0xAA006600 or 0xAA000066)
            ImGui.PushStyleColor(_imgui.ImGuiCol.FrameBg, ImGui.GetColorU32(backgroundColor))
            ImGui.ProgressBar(expiryTimer / buffOrDebuff.Duration, Vector2.new(ImGui.GetColumnWidth(), iconSize.Y + ImGui.GetStyle().CellPadding.Y), "")
            ImGui.PopStyleColor(2)
          end

          ImGui.SetCursorScreenPos(cursorStart)
          ImGui.TextureButton("##" .. buffOrDebuff.Id, GetOrCreateTexture(buffOrDebuff.icon), iconSize)
          if ImGui.IsItemHovered() then
            if buffOrDebuff.casterId ~= game.CharacterId and buffOrDebuff.casterId ~= 0 and
                buffOrDebuff.casterId ~= nil and game.World.Exists(buffOrDebuff.casterId) then
              ImGui.BeginTooltip()
              local caster = game.World.Get(buffOrDebuff.casterId)
              ImGui.Text("Granted by\n" .. caster.Name)
              ImGui.TextureButton("##" .. buffOrDebuff.Id - buffOrDebuff.casterId, GetOrCreateTexture((caster.DataValues[DataId.Icon] or 0)), iconSize)
              ImGui.EndTooltip()
            end
          end

          local expiryTimerYAdjust
          if expiryTimer then
            ImGui.SetWindowFontScale(1)
            expiryTimerYAdjust = ImGui.GetFontSize() / 2
            ImGui.SetCursorScreenPos(ImGui.GetCursorScreenPos() + Vector2.new(3, 0))
            local cursorStartDurationText = ImGui.GetCursorScreenPos() - Vector2.new(3, expiryTimerYAdjust)
            local durationTextSize = ImGui.CalcTextSize(bar.formatSeconds(expiryTimer))
            ImGui.GetWindowDrawList().AddRectFilled(cursorStartDurationText, cursorStartDurationText + durationTextSize + Vector2.new(3, 0), 0xAA000000)
            ImGui.SetCursorScreenPos(ImGui.GetCursorScreenPos() - Vector2.new(0, expiryTimerYAdjust))
            ImGui.Text(bar.formatSeconds(expiryTimer))
            ImGui.SetWindowFontScale(bar.settings.fontScale_flt or 1)
          end

          local cursorPostIcon = cursorStart + Vector2.new(iconSize.X, 0)
          local visibleText = tostring(printProp):gsub("%%%%", "%%")
          local textSize = ImGui.CalcTextSize(visibleText)

          local cursorForName = Vector2.new(cursorPostIcon.X + 5, cursorPostIcon.Y + iconSize.Y / 2 - ImGui.GetFontSize() / 2)
          ImGui.SetCursorScreenPos(cursorForName)
          ImGui.PushClipRect(cursorForName, Vector2.new(cursorForName.X + ImGui.GetContentRegionAvail().X - textSize.X - 5, cursorForName.Y + iconSize.Y + ImGui.GetStyle().CellPadding.Y), true)
          ImGui.Text(buffOrDebuff.Name)
          ImGui.PopClipRect()

          local cursorForProp = Vector2.new(cursorStart.X + ImGui.GetContentRegionAvail().X - textSize.X, cursorStart.Y + iconSize.Y / 2 - ImGui.GetFontSize() / 2)
          ImGui.SetCursorScreenPos(cursorForProp)
          ImGui.PushStyleColor(_imgui.ImGuiCol.Text, buffOrDebuff.isBuff and 0xFF00FF00 or 0xFF0000FF)
          ImGui.Text(printProp)
          ImGui.PopStyleColor()

          ImGui.SetCursorScreenPos(Vector2.new(cursorStart.X, cursorStart.Y + iconSize.Y + ImGui.GetStyle().CellPadding.Y + (expiryTimerYAdjust or 0)))
        end
        ImGui.EndChild()
      end
      ImGui.EndTable()
    end

    local spacingBetweenLabelX = 5
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, Vector2.new(spacingBetweenLabelX, 0))
    ImGui.SetCursorScreenPos(ImGui.GetCursorScreenPos() + Vector2.new(spacingBetweenLabelX, 3))

    local changed, checked = ImGui.Checkbox("Show Item Buffs     ##" .. bar.name, bar.settings.showItemBuffs)
    if changed then bar.settings.showItemBuffs = checked end

    ImGui.SameLine()
    ImGui.Text("Sort by ")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(100)

    local sortOptions = { table.unpack(bar.settings.sortingOptions_combo, 2, #bar.settings.sortingOptions_combo) }
    local sortIndex = bar.settings.sortingOptions_combo[1] - 1
    local changed2, newIndex = ImGui.Combo("##sortOption", sortIndex, sortOptions, #bar.settings.sortingOptions_combo - 1)
    if changed2 then
      bar.settings.sortingOptions_combo[1] = newIndex + 1
      SaveBarSettings(bar, "settings.sortingOptions_combo", bar.settings.sortingOptions_combo)
    end

    ImGui.SameLine()
    ImGui.Text("     Desc ")
    ImGui.SameLine()
    local changed3, checked3 = ImGui.Checkbox("##" .. bar.name .. "_reverseSort", bar.settings.reverseSort)
    if changed3 then bar.settings.reverseSort = checked3 end

    ImGui.PopStyleVar()
  end
}
