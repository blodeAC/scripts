local common = require("bar_common")

return {
  name = "sort_gembag",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x060011F7,
    label_str = "G    \n\n",
  },
  func = function(bar)
    common.sortbag(bar, "gems", game.Character, function()
      for i, item in ipairs(game.Character.Inventory) do
        if item.ObjectClass == ObjectClass.Gem and item.ContainerId ~= bar.sortBag then
          await(game.Actions.ObjectMove(item.Id, bar.sortBag, 0, false, common.genericActionOpts, common.genericActionCallback))
        end
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
