return {
  name = "attackpower",
  type = "button",
  settings = {
    enabled = false,
    icon_hex = 0x06006084,
    attackBar_pct = { 0.51, 0.01, 1 }
  },
  text = function(bar) return "AP=0.51" end,
  func = function(bar)
    game.Actions.InvokeChat("/vt setattackbar " .. bar.settings.attackBar_pct[1])
  end
}
