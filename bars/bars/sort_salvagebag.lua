local common = require("bar_common")

return {
  name = "sort_salvagebag",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x060011F7,
    label_str = "S    \n\n",
  },
  func = function(bar)
    common.sortbag(bar, "salvage", game.Character, function()
      for i, item in ipairs(game.Character.Inventory) do
        if item.ObjectClass == ObjectClass.Salvage and item.ContainerId ~= bar.sortBag then
          await(game.Actions.ObjectMove(item.Id, bar.sortBag, 0, true, common.genericActionOpts, common.genericActionCallback))
        end
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
