local common = require("bar_common")

return {
  name = "bag_salvageme",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 9914,
    label_str = " ",
  },
  func = function(bar)
    common.sortbag(bar, "salvageme", game.Character, function()
      if not game.Character.GetFirstInventory("Ust") then
        print("No UST!")
        return
      else
        game.Character.GetFirstInventory("Ust").Use(common.genericActionOpts, function(res)
          for _, itemId in ipairs(game.World.Get(bar.sortBag).AllItemIds) do
            game.Actions.SalvageAdd(itemId, common.genericActionOpts, common.genericActionCallback)
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
        end)
      end
    end)
  end,
  rightclick = function(bar)
    bar.sortBag = nil
  end
}
