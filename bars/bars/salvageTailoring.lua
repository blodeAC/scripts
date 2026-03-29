local common = require("bar_common")

return {
  name = "salvageTailoring",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 9914,
    label_str = " ",
  },
  func = function(bar)
    if not game.Character.GetFirstInventory("Ust") then
      print("No UST!")
      return
    end

    await(game.Character.GetFirstInventory("Ust").Use(common.genericActionOpts))

    for _, item in ipairs(game.Character.Inventory) do
      if "Tailoring" == (item.StringValues[StringId.Inscription] or "") then
        game.Actions.SalvageAdd(item.Id, common.genericActionOpts, common.genericActionCallback)
      end
    end

    for _, exBar in ipairs(common.getBars()) do
      if exBar.name == "sort_salvagebag" and exBar.sortBag then
        for _, itemId in ipairs(game.World.Get(exBar.sortBag).AllItemIds) do
          game.Actions.SalvageAdd(itemId, common.genericActionOpts, common.genericActionCallback)
        end
        break
      end
    end

    local opts = ActionOptions.new()
    opts.SkipChecks = true
    opts.TimeoutMilliseconds = 100
    opts.MaxRetryCount = 0
    game.Actions.Salvage(opts, common.genericActionCallback)
  end
}
