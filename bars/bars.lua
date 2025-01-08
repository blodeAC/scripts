local _imgui = require("imgui")
local vitals=game.Character.Weenie.Vitals
local acclient=require("acclient")

-- ACTIONQUEUE CONFIG
local genericActionOpts=ActionOptions.new()
---@diagnostic disable
genericActionOpts.MaxRetryCount=0
genericActionOpts.TimeoutMilliseconds=100
---@diagnostic enable
local genericActionCallback=function(e)
  if not e.Success then
    print(e.Error)
  end
end

-- FUNCTIONS USED BY BARS
local sortbag=function(bar,inscription,func)
  if bar.id==nil then
    for _,bag in ipairs(game.Character.Containers) do
      game.Messages.Incoming.Item_SetAppraiseInfo.Until(function(e)
        if bag.Id==e.Data.ObjectId then
          if bag.Value(StringId.Inscription)==inscription then
            bar.id=bag.Id
          end
          ---@diagnostic disable-next-line
          return true
        end
        ---@diagnostic disable-next-line
        return false
      end)

      bag.Appraise()
    end
  else
    func(bar)
  end
end

-- BARS
local bars = {}

bars = {  
  { name = "Health",  color = 0xAA0000AA, windowSettings=_imgui.ImGuiWindowFlags.NoInputs+_imgui.ImGuiWindowFlags.NoBackground, 
      textAlignment="center", type = "progress",
      max  = function() return vitals[VitalId.Health].Max end,
      value= function() return vitals[VitalId.Health].Current end,
      text = function() return "  "..vitals[VitalId.Health].Current .." / " .. vitals[VitalId.Health].Max .. " (" .. string.format("%.0f%%%%",(vitals[VitalId.Health].Current)/(vitals[VitalId.Health].Max)*100) ..")" end

  }, -- add "fontScale = 1.5" property to scale font 1.5x to any bar (or any other size), as needed
  { name = "Stamina", color = 0xAA00AAAA, windowSettings=_imgui.ImGuiWindowFlags.NoInputs+_imgui.ImGuiWindowFlags.NoBackground,
      textAlignment="center", type = "progress",
      max  = function() return vitals[VitalId.Stamina].Max end,
      value= function() return vitals[VitalId.Stamina].Current end,
      text = function() return "  "..vitals[VitalId.Stamina].Current .." / " .. vitals[VitalId.Stamina].Max .. " (" .. string.format("%.0f%%%%",(vitals[VitalId.Stamina].Current)/(vitals[VitalId.Stamina].Max)*100) ..")" end
  },
  { name = "Mana",    color = 0xAAAA0000, windowSettings=_imgui.ImGuiWindowFlags.NoInputs+_imgui.ImGuiWindowFlags.NoBackground,  
      textAlignment="center", type = "progress",
      max  = function() return vitals[VitalId.Mana].Max end,
      value= function() return vitals[VitalId.Mana].Current end,
      text = function() return "  "..vitals[VitalId.Mana].Current .." / " .. vitals[VitalId.Mana].Max .. " (" .. string.format("%.0f%%%%",(vitals[VitalId.Mana].Current)/(vitals[VitalId.Mana].Max)*100) ..")" end
  },

  --[[
  { name = "Distance",fontScale = 2, 
    windowSettings=_imgui.ImGuiWindowFlags.NoInputs+_imgui.ImGuiWindowFlags.NoBackground,
    minDistance = 35,
    maxDistance = 60,
    type = "text",
    text =  function(bar)
      if game.World.Selected==nil or game.World.Selected.ObjectClass~=ObjectClass.Monster then return "" end
      local dist=acclient.Coordinates.Me.DistanceTo(acclient.Movement.GetPhysicsCoordinates(game.World.Selected.Id))
      return dist>bar.minDistance and dist<bar.maxDistance and string.format("%.1f%",dist) or ""
    end
  },
--]]

  { name = "hpIncoming",
    fontScale = 2,
    text = function() return " " end,
    fontColorPositive_BBGGRRstring = "00FF00",
    fontColorNegative_BBGGRRstring = "0000FF",
    fadeDuration = 2, -- How long the text stays on screen
    floatSpeed = 1,   -- Speed of the floating text
    entries = {},     -- Table to store stamina changes
    
    init = function(bar)
      -- Set window properties
      bar.windowSettings =
          _imgui.ImGuiWindowFlags.NoInputs +
          _imgui.ImGuiWindowFlags.NoBackground

      -- Subscribe to stamina change events
      game.Character.OnVitalChanged.Add(function(changedVital)
        if changedVital.Type == VitalId.Health then
          local delta = changedVital.Value - changedVital.OldValue
          -- Add a new entry at the bottom of the bar
          table.insert(bar.entries, {
            text = tostring(delta),
            positive = delta>0 and true or false,
            time = os.clock(),
            position = Vector2.new(100, 300) -- Initial position (adjust as needed)
          })
        end
      end)
      bar.init=nil
    end,

    render = function(bar)
      local currentTime = os.clock()
      local validEntries = {}  -- Temporary list for valid entries
      
      -- Get the window's current size (content region)
      local windowSize = ImGui.GetContentRegionAvail()
      
      -- Process and render each entry
      for _, entry in ipairs(bar.entries) do
        local elapsed = currentTime - entry.time
        if elapsed <= bar.fadeDuration then
          -- Calculate alpha for fade effect
          local alpha = 1 - (elapsed / bar.fadeDuration)
          local color = tonumber(string.format("%02X%s", math.floor(alpha * 255), entry.positive and bar.fontColorPositive_BBGGRRstring or bar.fontColorNegative_BBGGRRstring), 16)
      
          -- Calculate the floating distance based on elapsed time and window size
          -- This ensures the text moves the full height of the window
          local floatDistance = (elapsed / bar.fadeDuration) * windowSize.Y  -- Scale to the full window height
    
          -- Center the text horizontally in the window
          local cursorPosX = (windowSize.X - ImGui.CalcTextSize(entry.text).X) / 2
    
          -- Start the y position from the bottom of the window and move up
          local cursorPosY = windowSize.Y - floatDistance - ImGui.GetFontSize()  -- Keep it above the bottom by font height
    
          -- Set the cursor position using SetCursorPos, relative to the window
          ImGui.SetCursorPos(Vector2.new(cursorPosX, cursorPosY))
      
          -- Render the text at the calculated position
          ImGui.PushStyleColor(_imgui.ImGuiCol.Text, color)
          ImGui.Text(entry.text)
          ImGui.PopStyleColor()
      
          -- Store the valid entry for the next render cycle
          table.insert(validEntries, entry)
        end
      end
    
      -- Replace old entries with the valid ones
      bar.entries = validEntries
    end
  },

--[[
  { name = "bag_salvageme", type = "button", icon=9914,  label = "UST",
    text = function() return "Ust" end,
    func = function(bar)
      sortbag(bar,"salvageme", function()
        if not game.Character.GetFirstInventory("Ust") then
          print("No UST!")
          return
        else
          game.Character.GetFirstInventory("Ust").Use(genericActionOpts,function(res)
            for _,itemId in ipairs(game.World.Get(bar.id).AllItemIds) do
              game.Actions.SalvageAdd(itemId,genericActionOpts,genericActionCallback)
            end
            
            if bar.id then
              for _,itemId in ipairs(game.World.Get(bar.id).AllItemIds) do
                game.Actions.SalvageAdd(itemId,genericActionOpts,genericActionCallback)
              end
            end
            game.Actions.InvokeChat("/ub mexec ustsalvage[]")
          end)
        end
      end)
    end
  },
--]]
  
  { name = "sort_trophybag", type = "button", icon=0x060011F7, label = "\nT ", 
    text = function() return "Trophy" end,
    func = function(bar)
      sortbag(bar,"trophies",function()
        for _,item in ipairs(game.Character.Inventory) do
          if item.HasAppraisalData==false and item.ObjectClass==ObjectClass.Misc then
            game.Messages.Incoming.Item_SetAppraiseInfo.Until(function(e)
              if item.Id==e.Data.ObjectId then
                if item.ContainerId~=bar.id and string.find(item.Value(StringId.Use),"A Trophy Collector or Trophy Smith may be interested in this.") then
                  game.Actions.ObjectMove(item.Id,bar.id,0,false,genericActionOpts,genericActionCallback)
                end
                ---@diagnostic disable-next-line
                return true
              end
            end)
            item.Appraise()
          else
            if item.ContainerId~=bar.id and string.find(item.Value(StringId.Use),"A Trophy Collector or Trophy Smith may be interested in this.") then
              game.Actions.ObjectMove(item.Id,bar.id,0,false,genericActionOpts,genericActionCallback)
            end
          end
        end
      end)
    end
  },
--[[
  { name = "sort_salvagebag", type = "button", icon=0x060011F7,  label = "S",
    text = function() return "Salvage" end,
    func = function(bar)
      sortbag(bar,"salvage",function()
        for i,item in ipairs(game.Character.Inventory) do
          local salvage=(item.ObjectClass==ObjectClass.Salvage)
          if salvage and item.ContainerId~=bar.id then
            game.Actions.ObjectMove(item.Id,bar.id,0,false,genericActionOpts,genericActionCallback)
          end
        end
      end)
    end
  },
  { name = "sort_gembag", type = "button", icon=0x060011F7, label = "G",
    text = function() return "Gem" end,
    func = function(bar)
      sortbag(bar,"gems",function()
        for i,item in ipairs(game.Character.Inventory) do
          local gem=(item.ObjectClass==ObjectClass.Gem)
          if gem and item.ContainerId~=bar.id then
            game.Actions.ObjectMove(item.Id,bar.id,0,false,genericActionOpts,genericActionCallback)
          end
        end
      end)
    end
  },


  { name = "attackpower", type = "button",
    text = function() return "AP=0.51" end,
    func = function()
      game.Actions.InvokeChat("/vt setattackbar 0.51")
    end
  }
--]]
}
return bars