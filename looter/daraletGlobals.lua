D_SigilTrinketBonusStat = {None=0, GearCrit=1,GearCritDamage=2,GearDamageResist=3,GearMaxHealth=4,WardLevel=5}
D_SigilTrinketBonusStat.GetValues = function(value)
  if value then
    for name,enumVal in pairs(D_SigilTrinketBonusStat) do
      if enumVal==value then
        return name
      end
    end
  else
    return {"None", "GearCrit","GearCritDamage","GearDamageResist","GearMaxHealth","WardLevel"}
  end
end
D_SigilTrinketBonusStat.FromValue = function(value)
  return D_SigilTrinketBonusStat.GetValues(value)
end


D_ArmorWeightClass = {None=0,Cloth=1,Light=2,Medium=3,Heavy=4}
D_ArmorWeightClass.GetValues = function(value)
  if value then
    for name,enumVal in pairs(D_ArmorWeightClass) do
      if enumVal==value then
        return name
      end
    end
  else
    return  {"None","Cloth","Light","Medium","Heavy"}
  end
end
D_ArmorWeightClass.FromValue = function(value)
  return D_ArmorWeightClass.GetValues(value)
end

D_ArmorStyle = {None=0,Cloth=1,Leather=2,StuddedLeather=3,Chainmail=4,Platemail=5,Scalemail=6,Yoroi=7,Celdon=8,Amuli=9,Koujia=10,Covenant=11,Lorica=12,Nariyid=13,Chiran=14,OlthoiCeldon=15,OlthoiAmuli=16,OlthoiKoujia=17,OlthoiArmor=18,Buckler=19,SmallShield=20,StandardShield=21,LargeShield=22,TowerShield=23,CovenantShield=24}
D_ArmorStyle.GetValues = function(value)
  if value then
    for name,enumVal in pairs(D_ArmorStyle) do
      if enumVal==value then
        return name
      end
    end
  else
    return {"None","Cloth","Leather","StuddedLeather","Chainmail","Platemail","Scalemail","Yoroi","Celdon","Amuli","Koujia","Covenant","Lorica","Nariyid","Chiran","OlthoiCeldon","OlthoiAmuli","OlthoiKoujia","OlthoiArmor","Buckler","SmallShield","StandardShield","LargeShield","TowerShield","CovenantShield"}
  end
end
D_ArmorStyle.FromValue = function(value)
  return D_ArmorStyle.GetValues(value)
end

D_WeaponSubtype = {Undef=0,AxeLarge=1,AxeMedium=2,AxeSmall=3,DaggerLarge=4,DaggerSmall=5,MaceLarge=6,MaceMedium=7,MaceSmall=8,StaffLarge=9,StaffMedium=10,StaffSmall=11,SpearLarge=12,SpearMedium=13,SpearSmall=14,SwordLarge=15,SwordMedium=16,SwordSmall=17,Ua=18,TwohandAxe=19,TwohandMace=20,TwohandSpear=21,TwohandSword=22,AtlatlLarge=23,AtlatlSmall=24,BowLarge=25,BowSmall=26,CrossbowLarge=27,CrossbowSmall=28,Caster=29}
D_WeaponSubtype.GetValues = function(value)
  if value then
    for name,enumVal in pairs(D_WeaponSubtype) do
      if enumVal==value then
        return name
      end
    end
  else
    return  {"Undef","AxeLarge","AxeMedium","AxeSmall","DaggerLarge","DaggerSmall","MaceLarge","MaceMedium","MaceSmall","StaffLarge","StaffMedium","StaffSmall","SpearLarge","SpearMedium","SpearSmall","SwordLarge","SwordMedium","SwordSmall","Ua","TwohandAxe","TwohandMace","TwohandSpear","TwohandSword","AtlatlLarge","AtlatlSmall","BowLarge","BowSmall","CrossbowLarge","CrossbowSmall","Caster"}
  end
end
D_WeaponSubtype.FromValue = function(value)
  return D_WeaponSubtype.GetValues(value)
end

ExtraEnums = {
  IntValues = setmetatable({
    "D_WardLevel",
    "D_ArmorSlots",
    "D_ArmorWeightClass",
    "D_GearMaxStamina",
    "D_GearMaxMana",
    "D_CombatFocusType",
    "D_WeightClassReqAmount",
    "D_ArmorStyle",
    "D_WeaponSubtype",
    "D_ArmorPatchAmount",
    "D_SigilTrinketColor",
    "D_SigilTrinketSchool",
    "D_SigilTrinketEffectId",
    "D_SigilTrinketMaxTier",
    "D_SigilTrinketElement",
    "D_SigilTrinketBonusStat",
    "D_SigilTrinketBonusStatAmount",
    "D_JewelSockets",
    "D_GearStrength",
    "D_GearEndurance",
    "D_GearCoordination",
    "D_GearQuickness",
    "D_GearFocus",
    "D_GearSelf",
    "D_GearLifesteal",
    "D_GearSelfHarm",
    "D_GearThreatGain",
    "D_GearThreatReduction",
    "D_GearElementalWard",
    "D_GearPhysicalWard",
    "D_GearMagicFind",
    "D_GearBlock",
    "D_GearItemManaUsage",
    "D_GearThorns",
    "D_GearVitalsTransfer",
    "D_GearLastStand",
    "D_GearSelflessness",
    "D_GearVipersStrike",
    "D_GearFamiliarity",
    "D_GearBravado",
    "D_GearHealthToStamina",
    "D_GearHealthToMana",
    "D_GearExperienceGain",
    "D_GearManasteal",
    "D_GearBludgeon",
    "D_GearPierce",
    "D_GearSlash",
    "D_GearFire",
    "D_GearFrost",
    "D_GearAcid",
    "D_GearLightning",
    "D_GearHealBubble",
    "D_GearCompBurn",
    "D_GearPyrealFind",
    "D_GearNullification",
    "D_GearWardPen",
    "D_GearStamReduction",
    "D_GearHardenedDefense",
    "D_GearReprisal",
    "D_GearElementalist",
    "D_BaseArmor",
    "D_BaseDamage",
    "D_BaseWard",
    "D_BaseWeaponTime",
    "D_BaseMaxMana",
    "D_ItemSpellId",
    "D_CombatFocusAttributeSpellRemoved",
    "D_CombatFocusAttributeSpellAdded",
    "D_CombatFocusSkillSpellRemoved",
    "D_CombatFocusSkillSpellAdded",
    "D_StackableSpellType",
    "D_NearbyPlayerScalingThreshold",
    "D_NearbyPlayerScalingExtraPlayersPerAdd",
    "D_NearbyPlayerScalingAddWcid",
    "D_RemainingConfirmations",
    "D_SigilTrinketType",
    "D_TrophyQuality",
    "D_AmmoEffect",
    "D_AmmoEffectUsesRemaining",
    "D_AltCurrencyValue",
    "D_Tier"
  },{
    __index = function (t, k)
      local k_num = tonumber(k)
      if k_num==nil then
        if k=="D_Tier" then
          return "10007"
        else
          for i,name in ipairs(ExtraEnums.IntValues) do
            if name==k then
              return tostring(i+390)
            end
          end
          return k
        end
      elseif k=="10007" then
        return "D_Tier"
      elseif t[k_num-390]~=nil then
        return t[k_num-390]
      else
        return k
      end
    end
  }),
  BoolValues = setmetatable({
    "D_UseArchetypeSystem",
    "D_OverrideArchetypeXp",
    "D_OverrideArchetypeHealth",
    "D_OverrideArchetypeStamina",
    "D_OverrideArchetypeMana",
    "D_OverrideArchetypeSkills",
    "D_BossKillXpReward",
    "D_ArmorPatchApplied",
    "D_UseLegacyThreatSystem",
    "D_OverrideVisualRange",
    "D_AffectsOnlyAis",
    "D_ExamineItemsSilently", -- allows for no/custom message upon NPC Emote Refuse examination of items
    "D_TakeItemsSilently", -- allows for no/custom messages for NPC TakeItems emote
    "D_DungeonLockout", -- if object is on landblock, no new players will be added to permitted list
    "D_CannotBreakStealth",
    "D_CampfireHotspot",
    "D_MutableQuestItem",
    "D_StruckByUnshrouded",
    "D_MenhirManaHotspot",
    "D_UseNearbyPlayerScaling",
    "D_IsBankContainer",
    "D_ShroudKillXpReward",
    "D_IsPlayerTierChest",
    "D_UpgradeableQuestItem",
    "D_FellowshipRequired",
    "D_SpecialPropertiesRequireMana",
    "D_RepeatConfirmation",
    "D_SilentCombat",
    "D_ReturnHomeWhenStuck",
  },{
    __index = function (t, k)
      local k_num = tonumber(k)
      if k_num==nil then
        for i,name in ipairs(ExtraEnums.BoolValues) do
          if name==k then
            return tostring(i+130)
          end
        end
        return k
      elseif k_num > 130 and t[k_num-130]~=nil then
        return t[k_num-130]
      else
        return k
      end
    end
  }),
  DataValues = setmetatable({
  }, {
    __index = function (t, k)
      return k
    end
  }),
  Int64Values = setmetatable({
  }, {
    __index = function (t, k)
      return k
    end
  }),
  FloatValues = setmetatable({
    "D_LootQualityMod",
    "D_KillXpMod",
    "D_ArchetypeToughness",
    "D_ArchetypePhysicality",
    "D_ArchetypeDexterity",
    "D_ArchetypeMagic",
    "D_ArchetypeIntelligence",
    "D_ArchetypeLethality",
    "D_BossKillXpMonsterMax",
    "D_BossKillXpPlayerMax",
    "D_SigilTrinketTriggerChance",
    "D_SigilTrinketCooldown",
    "D_SigilTrinketManaReserved",
    "D_SigilTrinketIntensity",
    "D_SigilTrinketReductionAmount",
    "D_WeaponPhysicalDefense",
    "D_WeaponMagicalDefense",
    "D_Damage",
    "D_WeaponAuraDamage",
    "D_StaminaCostReductionMod",
    "D_RankContribution",
    "D_SworeAllegiance",
    "D_NearbyPlayerVitalsScalingPerExtraPlayer",
    "D_NearbyPlayerAttackScalingPerExtraPlayer",
    "D_NearbyPlayerDefenseScalingPerExtraPlayer",
    "D_SigilTrinketStaminaReserved",
    "D_SigilTrinketHealthReserved",
    "D_IgnoreWard",
    "D_ArmorWarMagicMod",
    "D_ArmorLifeMagicMod",
    "D_ArmorMagicDefMod",
    "D_ArmorPhysicalDefMod",
    "D_ArmorMissileDefMod",
    "D_ArmorDualWieldMod",
    "D_ArmorRunMod",
    "D_ArmorAttackMod",
    "D_ArmorHealthRegenMod",
    "D_ArmorStaminaRegenMod",
    "D_ArmorManaRegenMod",
    "D_ArmorShieldMod",
    "D_ArmorPerceptionMod",
    "D_ArmorThieveryMod",
    "D_WeaponWarMagicMod",
    "D_WeaponLifeMagicMod",
    "D_WeaponRestorationSpellsMod",
    "D_ArmorHealthMod",
    "D_ArmorStaminaMod",
    "D_ArmorManaMod",
    "D_ArmorResourcePenalty",
    "D_ArmorDeceptionMod",
    "D_ArmorTwohandedCombatMod",
    "D_BaseArmorWarMagicMod",
    "D_BaseArmorLifeMagicMod",
    "D_BaseArmorMagicDefMod",
    "D_BaseArmorPhysicalDefMod",
    "D_BaseArmorMissileDefMod",
    "D_BaseArmorDualWieldMod",
    "D_BaseArmorRunMod",
    "D_BaseArmorAttackMod",
    "D_BaseArmorHealthRegenMod",
    "D_BaseArmorStaminaRegenMod",
    "D_BaseArmorManaRegenMod",
    "D_BaseArmorShieldMod",
    "D_BaseArmorPerceptionMod",
    "D_BaseArmorThieveryMod",
    "D_BaseWeaponWarMagicMod",
    "D_BaseWeaponLifeMagicMod",
    "D_BaseWeaponRestorationSpellsMod",
    "D_BaseArmorHealthMod",
    "D_BaseArmorStaminaMod",
    "D_BaseArmorManaMod",
    "D_BaseArmorResourcePenalty",
    "D_BaseArmorDeceptionMod",
    "D_BaseArmorTwohandedCombatMod",
    "D_BaseWeaponPhysicalDefense",
    "D_BaseWeaponMagicalDefense",
    "D_BaseWeaponOffense",
    "D_BaseDamageMod",
    "D_BaseElementalDamageMod",
    "D_BaseManaConversionMod"
  },{
    __index = function (t, k)
      local k_num = tonumber(k)
      if k_num==nil then
        if k=="D_HotspotImmunityTimestamp" then
          return "10002"
        else
          for i,name in ipairs(ExtraEnums.FloatValues) do
            if name==k then
              if i<28 then
                return tostring(i+170)
              else
                return tostring(i+19972)
              end
            end
          end
          return k
        end
      elseif k_num == 10002 then
        return "D_HotspotImmunityTimestamp"
      elseif k_num < 199 and t[k_num-171]~=nil then
        return t[k_num-171]
      elseif t[k_num-19999+27]~=nil then
        return t[k_num-19999+27]
      else
        return k
      end
    end
  }),
  StringValues = setmetatable({
    "D_JewelSocket1",
    "D_JewelSocket2",
    "D_CacheLog",
    "D_AllegianceLog",
    "D_CorpseLog",
  },{
    __index = function (t, k)
      local k_num = tonumber(k)
      if k_num==nil then
        for i,name in ipairs(ExtraEnums.StringValues) do
          if name==k then
            return tostring(i+9009)
          end
        end
        return k
      elseif k_num > 9009 and t[k_num-9009]~=nil then
        return t[k_num-9009]
      else
        return k
      end
    end
  })
}
