local common = require("bar_common")

return {
  name = "sort_trophybag",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x060011F7,
    label_str = "T    \n\n",
  },
  func = function(bar)
    common.sortbag(bar, "trophies", game.Character, function()
      local function stash(item)
        if item.ContainerId ~= bar.sortBag and string.find((item.StringValues[StringId.Use] or ""), "A Trophy Collector or Trophy Smith may be interested in this.") then
          await(game.Actions.ObjectMove(item.Id, bar.sortBag, 0, true, common.genericActionOpts, common.genericActionCallback))
        end
      end
      for i, item in ipairs(game.Character.Inventory) do
        if item.ObjectClass == ObjectClass.Misc then
          if item.HasAppraisalData == false then
            await(game.Actions.ObjectAppraise(item.Id))
          end
          stash(item)
        end
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
