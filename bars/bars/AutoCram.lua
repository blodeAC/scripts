return {
  name = "AutoCram",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x060011F7,
  },
  func = function(bar)
    for i, pack in ipairs(game.Character.Containers) do
      if not pack.HasAppraisalData then
        await(game.Actions.ObjectAppraise(pack.Id))
      end
      if string.len((pack.StringValues[StringId.Inscription] or "")) == 0 then
        local freeInThisBag = (pack.IntValues[IntId.ItemsCapacity] or 0) - #pack.AllItemIds
        local toMoveIds = {}
        for _, item in ipairs(game.Character.Inventory) do
          if item.ContainerId == game.CharacterId then
            table.insert(toMoveIds, item.Id)
          end
        end
        local maxToMove = math.min(#toMoveIds, freeInThisBag)
        if maxToMove > 0 then
          for j = 1, maxToMove do
            game.Actions.ObjectMove(toMoveIds[j], pack.Id, 0, true)
          end
        end
      end
    end
  end
}
