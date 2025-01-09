---CONFIGURATION
local maxDistanceForVisibility = 60

------------------------------------
local init = function()
  local acclient = require("acclient")
  -- Metatable for wobject to define health bar related methods
  local wobjectMeta = {
    -- Method to calculate offset coordinates based on angle and scalar
    getOffsetCoordinates = function(self, angle, scalar, mirrored)
      if not game.World.Exists(self.id) or acclient.Movement.GetPhysicsCoordinates(self.id) == nil then return nil end
      -- Get the heading and adjust with angle
      local heading = math.rad((acclient.Movement.GetPhysicsCoordinates(self.id).HeadingTo(acclient.Coordinates.Me) + angle) %
      360)

      -- Calculate the north-south (Y) and east-west (X) offsets
      local delta_NS = scalar / 2 * math.sin(heading)
      local delta_EW = scalar / 2 * math.cos(heading)

      -- Adjust NS based on mirroring, return new coordinates
      local new_NS = ((mirrored and -1 or 1) * delta_NS)
      local new_EW = delta_EW

      return { NS = new_NS, EW = new_EW }
    end,

    -- Method to orient the health bar relative to player
    orientHpBar = function(self)
      -- Get offset coordinates and orient the health bar to those coordinates
      local offset = self:getOffsetCoordinates(-90, self.hp, true)
      if offset == nil then return end
      self.hpbar.OrientToCoords(acclient.Coordinates.Me.NS + offset["NS"], acclient.Coordinates.Me.EW + offset["EW"], 1,
        false)
      self.hpbar.Visible = true
      self.hpText.OrientToCoords(acclient.Coordinates.Me.NS, acclient.Coordinates.Me.EW, 1, false)
    end,

    -- Method to anchor the health bar to the wobject
    anchorHpBar = function(self, init)
      local offset = self:getOffsetCoordinates(90, 1 - self.hp)
      if offset == nil then return end
      if init then
        self.redbar.Anchor(self.id, self.height + self.ticker.ScaleY / 2, 0, 0, -0.25)
        self.redbar.OrientToPlayer(false)
      end
      self.redbar.Visible = true

      self.hpbar.Visible = true
      self.hpbar.Anchor(self.id, self.height + self.ticker.ScaleY / 2, offset["NS"], offset["EW"], -0.25)
      self.hpbar.ScaleX = self.hp

      local fwoffset = self:getOffsetCoordinates(0, 0.2, false)
      self.hpText.Anchor(self.id, self.height + self.ticker.ScaleY / 2, fwoffset["NS"], fwoffset["EW"], -0.25)
      if self.hp ~= 1 then
        self:orientHpBar()
      else
        self.hpbar.OrientToPlayer(false)
        self.hpbar.Visible = true
      end
    end
  }

  -- Table to hold all wobjects, with custom insert method and custom pairs iterator
  local wobjects
  wobjects = setmetatable({
    insert = function(self, wobject)
      -- Set metatable for the new wobject to use wobjectMeta

      setmetatable(wobject, { __index = wobjectMeta })

      local weenie = game.World.Get(wobject.id)
      wobject.name = weenie.Name
      wobject.objectClass = weenie.ObjectClass
      
      local heritage = weenie.Value(IntId.HeritageGroup, -1)
      wobject.height = 1.1

      if (heritage == 8) then                                        -- lugian
        wobject.height = wobject.height + 0.21
      elseif (heritage > 5 and heritage < 10 and heritage ~= 7) then -- 7==tumerok // other non-humans
        wobject.height = wobject.height + 0.1
      end

      wobject.ticker = acclient.DecalD3D.MarkObjectWith3DText(wobject.id, "_", "Arial", 0x00000000)
      wobject.ticker.Scale(0.1)
      wobject.ticker.Visible = false

      wobject.hpText = acclient.DecalD3D.MarkObjectWith3DText(wobject.id, "_", "Arial", 0x00000000)
      wobject.hpText.Scale(0.12)
      wobject.hpText.Visible = false

      -- Create green hp bar and assign properties
      wobject.hpbar = acclient.DecalD3D.NewD3DObj()
      wobject.hpbar.SetShape(acclient.DecalD3DShape.Cube)
      wobject.hpbar.ScaleX = wobject.hp
      wobject.hpbar.ScaleY = 0.15
      wobject.hpbar.ScaleZ = 0.15
      wobject.hpbar.Color = 0x8000FF00

      -- Create red hp bar for background and assign properties
      wobject.redbar = acclient.DecalD3D.NewD3DObj()
      wobject.redbar.SetShape(acclient.DecalD3DShape.Cube)
      wobject.redbar.ScaleX = 0.99
      wobject.redbar.ScaleY = 0.1
      wobject.redbar.ScaleZ = 0.1
      wobject.redbar.Color = 0x80FF0000
      wobject.redbar.OrientToCamera(false)

      wobject:anchorHpBar(true)

      -- Store wobject by its ID
      self[wobject.id] = wobject

      -- Request a health update for the newly inserted wobject
      ---@diagnostic disable-next-line: undefined-field
      acclient.Client.RequestHealthUpdate(wobject.id)
    end
  }, {
    -- Custom iterator for pairs to return only table entries
    __pairs = function(self)
      local function iterator(tbl, key)
        local nextKey, nextValue = next(tbl, key)
        while nextKey do
          if type(nextValue) == "table" then
            return nextKey, nextValue
          end
          nextKey, nextValue = next(tbl, nextKey)
        end
        return nil
      end
      ---@diagnostic disable-next-line: redundant-return-value
      return iterator, self, nil
    end
  })

  -- Table of valid play scripts for health-related events
  local healthPlayScripts = {
    [PlayScript.AttribDownBlue.ToNumber()] = true,
    [PlayScript.AttribDownGreen.ToNumber()] = true,
    [PlayScript.AttribDownOrange.ToNumber()] = true,
    [PlayScript.AttribDownPurple.ToNumber()] = true,
    [PlayScript.AttribDownRed.ToNumber()] = true,
    [PlayScript.AttribDownYellow.ToNumber()] = true,
    [PlayScript.TransDownBlack.ToNumber()] = true,
    [PlayScript.HealthDownBlue.ToNumber()] = true,
    [PlayScript.HealthDownRed.ToNumber()] = true,
    [PlayScript.HealthDownVoid.ToNumber()] = true,
    [PlayScript.HealthDownYellow.ToNumber()] = true,
    [PlayScript.SwapHealth_Red_To_Blue.ToNumber()] = true,
    [PlayScript.SwapHealth_Red_To_Yellow.ToNumber()] = true,
    [PlayScript.SwapHealth_Blue_To_Red.ToNumber()] = true,
    [PlayScript.SwapHealth_Yellow_To_Red.ToNumber()] = true,
    [PlayScript.HealthUpRed.ToNumber()] = true,
    [PlayScript.ProjectileCollision.ToNumber()] = true,
    [PlayScript.SplatterLowLeftBack.ToNumber()] = true,
    [PlayScript.SplatterLowLeftFront.ToNumber()] = true,
    [PlayScript.SplatterLowRightBack.ToNumber()] = true,
    [PlayScript.SplatterLowRightFront.ToNumber()] = true,
    [PlayScript.SplatterMidLeftBack.ToNumber()] = true,
    [PlayScript.SplatterMidLeftFront.ToNumber()] = true,
    [PlayScript.SplatterMidRightBack.ToNumber()] = true,
    [PlayScript.SplatterMidRightFront.ToNumber()] = true,
    [PlayScript.SplatterUpLeftBack.ToNumber()] = true,
    [PlayScript.SplatterUpLeftFront.ToNumber()] = true,
    [PlayScript.SplatterUpRightBack.ToNumber()] = true,
    [PlayScript.SplatterUpRightFront.ToNumber()] = true,
    [PlayScript.SparkLowLeftBack.ToNumber()] = true,
    [PlayScript.SparkLowLeftFront.ToNumber()] = true,
    [PlayScript.SparkLowRightBack.ToNumber()] = true,
    [PlayScript.SparkLowRightFront.ToNumber()] = true,
    [PlayScript.SparkMidLeftBack.ToNumber()] = true,
    [PlayScript.SparkMidLeftFront.ToNumber()] = true,
    [PlayScript.SparkMidRightBack.ToNumber()] = true,
    [PlayScript.SparkMidRightFront.ToNumber()] = true,
    [PlayScript.SparkUpLeftBack.ToNumber()] = true,
    [PlayScript.SparkUpLeftFront.ToNumber()] = true,
    [PlayScript.SparkUpRightBack.ToNumber()] = true,
    [PlayScript.SparkUpRightFront.ToNumber()] = true
  }

  -- Filter table to check properties of wobjects
  local filter = {
    properties = {
      ObjectClass = {
        ObjectClass.Monster
      }
    },
    tests = {
      function(weenie)
        return weenie.Name ~= ""
      end
    }
  }

  -- Set metatable for filter with custom contains and check methods
  setmetatable(filter, {
    __index = {
      -- Check if a value exists in a table
      contains = function(_, table, value)
        for _, v in ipairs(table) do
          if v == value then
            return true
          end
        end
        return false
      end,

      -- Check if a wobject passes all filter criteria
      check = function(self, weenie)
        if weenie.Id == game.CharacterId then
          return false
        end

        -- Check properties
        for prop, category in pairs(self.properties) do
          if not self:contains(category, weenie[prop]) then
            return false -- Fail if any property does not match
          end
        end

        -- Check custom tests
        for _, testfunc in pairs(self.tests) do
          if not testfunc(weenie) then
            return false -- Fail if any test function returns false
          end
        end

        return true -- All filters passed
      end
    }
  })

  -------------------------------------
  --- events
  -------------------------------------

  -- Event listener for when an object is created
  game.World.OnObjectCreated.Add(function(e)
    local wobjectId = e.ObjectId
    local weenie = game.World.Get(wobjectId)

    -- If the object passes the filter, insert it into wobjects
    if (wobjects[wobjectId] == nil and filter:check(weenie)) then
      wobjects:insert({ id = wobjectId, hp = 1 })
    end
  end)

  game.Messages.Incoming.Combat_QueryHealthResponse.Add(function(e)
    local wobject = wobjects[e.Data.ObjectId]

    if (wobject ~= nil) then
      if (e.Data.HealthPercent <= 0) then
        wobject = nil
      else
        if wobject.hp ~= e.Data.HealthPercent then --expected?
          wobject.dmgPercent = wobject.hp - e.Data.HealthPercent
          wobject.hp = e.Data.HealthPercent
          wobject.lastUpdate = os.clock()
          --wobject.expected=false
          wobject:anchorHpBar()
        end
        if game.World.Selected~=nil and game.World.Selected.Id == e.Data.ObjectId and wobject.maxHp then
          wobject.hpText.SetText(acclient.DecalD3DTextType.Text3D, tostring(math.floor(e.Data.HealthPercent*wobject.maxHp+0.5)) .. " / " .. tostring(wobject.maxHp), "Arial",
          0xFFFFFFFF)
          wobject.hpText.Visible = true
        end
      end
    end
  end)

  local lastSelected = nil
  -- Event listener for script play events related to health
  game.Messages.Incoming.Effects_PlayScriptType.Add(function(e)
    local wobjectId = e.Data.ObjectId

    -- Request health update if the wobject exists and the script is health-related. Don't send if targeted bc those are free
    if (wobjects[wobjectId] ~= nil and healthPlayScripts[e.Data.ScriptId] ~= nil) then
      ---@diagnostic disable-next-line: undefined-field
      acclient.Client.RequestHealthUpdate(wobjectId)
      --wobjects[wobjectId].expected=true
    end
  end)

  game.Messages.Incoming.Effects_SoundEvent.Add(function(e)
    local wobjectId = e.Data.ObjectId
    
    if (wobjects[wobjectId] ~= nil and e.Data.SoundType == Sound.HitFlesh1) then
      ---@diagnostic disable-next-line: undefined-field
      acclient.Client.RequestHealthUpdate(wobjectId)
    end
  end)

  --wipe out text on deselect
  game.World.OnObjectSelected.Add(function(e)
    if lastSelected ~= nil then
      if wobjects[lastSelected] ~= nil then
        wobjects[lastSelected].hpText.Visible = false
      end
    end
    lastSelected = e.ObjectId
  end)

  --hp correlator function for only looking at the selected mob
  local hpCorrelator = function(e)
    ---@diagnostic disable:undefined-field
    ---@diagnostic disable:inject-field
    local damage
    local mobName
    if e.Data.Name ~= nil then
      mobName = e.Data.Name
      damage = e.Data.DamageDone
    elseif (e.Data.Type == LogTextType.Magic) then
      local test = Regex.Match(e.Data.Text,
        "^(?:(?:Sneak attack! )(?:Critical hit! )?You (?:hit|mangle|slash|cut|scratch|gore|impale|stab|nick|crush|smash|bash|graze|incinerate|burn|scorch|singe|freeze|frost|chill|numb|dissolve|corrode|sear|blister|blast|jolt|shock|spark) (.*?) for ([\\d,]+) points with |With .*? you drain ([\\d+,]+) points of health from (.*).$)")
      mobName = test.Groups[1].Value ~= "" and test.Groups[1].Value or test.Groups[4].Value ~= "" and test.Groups[4].Value or
      nil
      damage = test.Groups[2].Value ~= "" and test.Groups[2].Value or test.Groups[3].Value
    end

    local selName = game.World.Selected ~= nil and game.World.Selected.Name ~= nil and game.World.Selected.Name or nil
    if selName == nil or mobName == nil or damage == nil or selName ~= mobName then
      return
    end

    local bestGuess = nil
    for _, wobject in pairs(wobjects) do
      if wobject.name == mobName and wobject.lastUpdate ~= nil and os.difftime(os.clock(), wobject.lastUpdate) < 0.5 then -- 500ms max delay between hprequest and damage message
        bestGuess = bestGuess or wobject
        if wobject.lastUpdate < bestGuess.lastUpdate then
          bestGuess = wobject
        end
      else
        wobject.lastUpdate = nil
      end
    end

    if bestGuess ~= nil then
      local totalHp = math.floor(bestGuess.hp * tonumber(damage) / bestGuess.dmgPercent + 0.5)
      local maxHp = math.floor(tonumber(damage) / bestGuess.dmgPercent + 0.5)
      --print(tostring(totalHp) .. " / " .. tostring(maxHp) ..  "| ".. (totalHp/maxHp) .. ": " .. bestGuess.hp)
      if (totalHp / maxHp) <= bestGuess.hp and maxHp>0 then
        bestGuess.maxHp = maxHp
      end
      
      bestGuess.lastUpdate = nil
    end
    ---@diagnostic enable:undefined-field
    ---@diagnostic enable:inject-field
  end

  game.Messages.Incoming.Combat_HandleAttackerNotificationEvent.Add(hpCorrelator)
  game.Messages.Incoming.Communication_TextboxString.Add(hpCorrelator)

  -- Event listener for script end, to clean up resources
  game.OnScriptEnd.Add(function(e)
    for i, wobject in pairs(wobjects) do
      ---@diagnostic disable:undefined-field
      -- Dispose of the health bar objects when the script ends
      if wobject.hpbar ~= nil then wobject.hpbar.Dispose() end
      if wobject.redbar ~= nil then wobject.redbar.Dispose() end
      if wobject.ticker ~= nil then wobject.ticker.Dispose() end
      if wobject.hpText ~= nil then wobject.hpText.Dispose() end
      ---@diagnostic enable:undefined-field
    end
  end)

  -- Function to update position of health bars when the character's position changes
  local function positionChanged(e)
    for _, wobject in pairs(wobjects) do
      ---@diagnostic disable
      local coords=nil
      if game.World.Exists(wobject.id) then coords=acclient.Movement.GetPhysicsCoordinates(wobject.id) end
      if coords and acclient.Coordinates.Me.DistanceTo(coords)>maxDistanceForVisibility then
        wobject.hpbar.Visible=false
        wobject.redbar.Visible=false
      else
        wobject:anchorHpBar()
      end
      ---@diagnostic enable
    end
  end

  -- Insert initial objects that pass the filter
  for i, wobject in ipairs(game.World.GetAll(function(weenie) return filter:check(weenie) end)) do
    wobjects:insert({ id = wobject.Id, hp = 1 })
  end

  -- Add listener for when the character's position changes
  game.Character.Weenie.OnPositionChanged.Add(positionChanged)
end

if game.State == ClientState.In_Game then
  init()
end

game.OnStateChanged.Add(function(state)
  if state.NewState == ClientState.In_Game then
    init()
  end
end)