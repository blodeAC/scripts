local common = require("bar_common")

return {
  name = "sort_vendorbag",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x060011F7,
    label_str = "V    \n\n",
  },
  func = function(bar)
    common.sortbag(bar, "vendor", game.Character, function()
      for i, item in ipairs(game.Character.Inventory) do
        local trash = (string.find(item.Name, "Mana Stone") or string.find(item.Name, "Scroll") or string.find(item.Name, "Lockpick")) and
            item.Burden <= 50 and (item.IntValues[IntId.Value] or 0) >= 2000
        if trash and item.ContainerId ~= bar.sortBag then
          await(game.Actions.ObjectMove(item.Id, bar.sortBag, 0, false, common.genericActionOpts, common.genericActionCallback))
        end
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
