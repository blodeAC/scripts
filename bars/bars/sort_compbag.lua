local common = require("bar_common")

return {
  name = "sort_compbag",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x060011F7,
    label_str = "C    \n\n",
  },
  func = function(bar)
    common.sortbag(bar, "comps", game.Character, function()
      for i, item in ipairs(game.Character.Inventory) do
        local comp = (item.ObjectClass == ObjectClass.SpellComponent) and not string.find(item.Name, "Pea")
        if comp and item.ContainerId ~= bar.sortBag then
          await(game.Actions.ObjectMove(item.Id, bar.sortBag, 0, true, common.genericActionOpts, common.genericActionCallback))
        end
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
