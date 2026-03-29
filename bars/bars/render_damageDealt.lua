local _imgui = require("imgui")
local common = require("bar_common")

return {
  name = "render_damageDealt",
  windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
  settings = {
    enabled = false,
    icon_hex = 0x060028FC,
    fontScaleMin_flt = 2,
    fontScaleMax_flt = 3,
    fontScaleCrit_flt = 4,
    fontColorPositive_col3 = 0xFFFFFF,
    fontColorNegative_col3 = 0x0000FF,
    fadeDuration_num = 2,
    floatSpeed_num = 1,
  },
  entries = {},
  runningSum = 0,
  runningCount = 0,

  init = function(bar)
    local function hpExtractor(e)
      local damage = nil
      local crit = false
      if e.Data.Name ~= nil then
        damage = e.Data.DamageDone
      elseif (e.Data.Type == LogTextType.Magic or e.Data.Type == LogTextType.CombatSelf) then
        local r = Regex.new(
          "^(?<crit>Critical hit!  )?(?:[^!]+! )*(?:(?:You (?:eradicate|wither|twist|scar|hit|mangle|slash|cut|scratch|gore|impale|stab|nick|crush|smash|bash|graze|incinerate|burn|scorch|singe|freeze|frost|chill|numb|dissolve|corrode|sear|blister|blast|jolt|shock|spark) (?<mobName>.*?) for (?<damage>[\\d,]+) points (?:.*))|(?:With .*? you (?:drain|exhaust|siphon|deplete) (?<drainDamage>[\\d,]+) points of health from (?<magicMobName>.*?))\\.)$"
        )
        local m = r.Match(e.Data.Text)
        if m.Success then
          if m.Groups["crit"].Success then crit = true end
          if m.Groups["damage"].Success then
            damage = m.Groups["damage"].Value
          elseif m.Groups["drainDamage"].Value then
            damage = m.Groups["drainDamage"].Value
          end
        end
      end

      if damage ~= nil then
        table.insert(bar.entries, {
          text = damage .. (crit and "!" or ""),
          value = math.abs(tonumber(damage or 0)),
          positive = tonumber(damage) > 0,
          time = os.clock(),
        })
        bar.runningSum = bar.runningSum + math.abs(tonumber(damage or 0))
        bar.runningCount = bar.runningCount + 1
      end
    end

    game.Messages.Incoming.Combat_HandleAttackerNotificationEvent.Add(hpExtractor)
    game.Messages.Incoming.Communication_TextboxString.Add(hpExtractor)

    game.Messages.Incoming.Combat_HandleEvasionAttackerNotificationEvent.Add(function(e)
      table.insert(bar.entries, { text = "Evade", positive = false, time = os.clock() })
    end)

    game.Messages.Incoming.Combat_HandleVictimNotificationEventOther.Add(function(e)
      if game.Character.Weenie.Vitals[VitalId.Health].Current ~= 0 then
        table.insert(bar.entries, { text = "RIP", positive = false, time = os.clock() })
      end
    end)
  end,

  render = common.renderEvent
}
