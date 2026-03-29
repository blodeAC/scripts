local common = require("bar_common")

return {
  name = "bank_peas",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x06006727,
  },
  text = function(bar) return bar.sortBag and "Store Peas" or "Find Pea Bag" end,
  init = function(bar)
    if game.World.OpenContainer and game.World.OpenContainer.Container and game.World.OpenContainer.Container.Name == "Avaricious Golem" then
      bar.hud.Visible = true
    else
      bar.hud.Visible = false
    end
    game.World.OnContainerOpened.Add(function(e)
      if e.Container.Name == "Avaricious Golem" then
        bar.hud.Visible = true
      end
    end)
    game.World.OnContainerClosed.Add(function(e)
      if e.Container and e.Container.Name == "Avaricious Golem" then
        bar.hud.Visible = false
      end
    end)
  end,
  func = function(bar)
    if not game.World.OpenContainer or not game.World.OpenContainer.Container or not game.World.OpenContainer.Container.Name == "Avaricious Golem" then
      bar.hud.Visible = false
      return
    end
    common.sortbag(bar, "peas", game.World.OpenContainer.Container, function()
      for i, item in ipairs(game.Character.Inventory) do
        local pea = string.find(item.Name, "Pea")
        if pea and item.ObjectClass == ObjectClass.SpellComponent and item.ContainerId ~= bar.sortBag then
          await(game.Actions.ObjectMove(item.Id, bar.sortBag, 0, false, common.genericActionOpts, common.genericActionCallback))
        end
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
