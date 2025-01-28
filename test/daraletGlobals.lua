---@class D_SigilTrinketBonusStat: EnumConst
---@class D_SigilTrinketBonusStat‎
---@field GearCrit D_SigilTrinketBonusStat -- None
---@field GearCritDamage D_SigilTrinketBonusStat -- TODO
---@field GearDamageResist D_SigilTrinketBonusStat -- TODO
---@field GearMaxHealth D_SigilTrinketBonusStat -- TODO
---@field WardLevel D_SigilTrinketBonusStat -- TODO
---@type D_SigilTrinketBonusStat
D_SigilTrinketBonusStat = { }
D_SigilTrinketBonusStat.GetValues = function()
  return {"GearCrit","GearCritDamage","GearDamageResist","GearMaxHealth","WardLevel"}
end
D_SigilTrinketBonusStat.FromValue = function(value)
  for i,val in ipairs(D_SigilTrinketBonusStat.GetValues()) do
    if val==value then
      return i
    end
  end
end

---@class WieldRequirements: EnumConst
---@class WieldRequirements‎
---@field Invalid WieldRequirements
---@field Skill WieldRequirements
---@field RawSkill WieldRequirements
---@field Attrib WieldRequirements
---@field RawAttrib WieldRequirements
---@field SecondaryAttrib WieldRequirements
---@field RawSecondaryAttrib WieldRequirements
---@field Level WieldRequirements
---@field Training WieldRequirements
---@field IntStat WieldRequirements
---@field BoolStat WieldRequirements
---@field CreatureType WieldRequirements
---@field HeritageType WieldRequirements
---@type WieldRequirements
WieldRequirements = { }
WieldRequirements.GetValues = function()
  return {"Invalid","SkillId","SkillId","AttributeId","AttributeId","VitalId","VitalId","Level","Training","IntId","BoolId","CreatureType","HeritageGroup"}
end
WieldRequirements.FromValue = function(value)
  for i,val in ipairs(WieldRequirements.GetValues()) do
    if val==value then
      return i-1
    end
  end
end
Level = WieldRequirements
Training = WieldRequirements
WieldRequirements2 = WieldRequirements

---@class D_ArmorWeightClass: EnumConst
---@class D_ArmorWeightClass‎
---@field None D_ArmorWeightClass
---@field Light D_ArmorWeightClass
---@field Medium D_ArmorWeightClass
---@field Heavy D_ArmorWeightClass
---@type D_ArmorWeightClass
D_ArmorWeightClass = { }
D_ArmorWeightClass.GetValues = function()
  return {"None","Light","Medium","Heavy"}
end
D_ArmorWeightClass.FromValue = function(value)
  for i,val in ipairs(D_ArmorWeightClass.GetValues()) do
    if val==value then
      return i-1
    end
  end
end

---@class D_ArmorStyle: EnumConst
---@class D_ArmorStyle‎
---@field None D_ArmorStyle
---@field Cloth D_ArmorStyle
---@field Leather D_ArmorStyle
---@field StuddedLeather D_ArmorStyle
---@field Chainmail D_ArmorStyle
---@field Platemail D_ArmorStyle
---@field Scalemail D_ArmorStyle
---@field Yoroi D_ArmorStyle
---@field Celdon D_ArmorStyle
---@field Amuli D_ArmorStyle
---@field Koujia D_ArmorStyle
---@field Covenant D_ArmorStyle
---@field Lorica D_ArmorStyle
---@field Nariyid D_ArmorStyle
---@field Chiran D_ArmorStyle
---@field OlthoiCeldon D_ArmorStyle
---@field OlthoiAmuli D_ArmorStyle
---@field OlthoiKoujia D_ArmorStyle
---@field OlthoiArmor D_ArmorStyle
---@field Buckler D_ArmorStyle
---@field SmallShield D_ArmorStyle
---@field StandardShield D_ArmorStyle
---@field LargeShield D_ArmorStyle
---@field TowerShield D_ArmorStyle
---@field CovenantShiel D_ArmorStyle
---@type D_ArmorStyle
D_ArmorStyle = { }
D_ArmorStyle.GetValues = function()
  return {"None","Cloth","Leather","StuddedLeather","Chainmail","Platemail","Scalemail","Yoroi","Celdon","Amuli","Koujia","Covenant","Lorica","Nariyid","Chiran","OlthoiCeldon","OlthoiAmuli","OlthoiKoujia","OlthoiArmor","Buckler","SmallShield","StandardShield","LargeShield","TowerShield","CovenantShield"}
end
D_ArmorStyle.FromValue = function(value)
  for i,val in ipairs(D_ArmorStyle.GetValues()) do
    if val==value then
      return i-1
    end
  end
end

---@class D_WeaponSubtype: EnumConst
---@class D_WeaponSubtype‎
---@field Undef D_WeaponSubtype
---@field AxeLarge D_WeaponSubtype
---@field AxeMedium D_WeaponSubtype
---@field AxeSmall D_WeaponSubtype
---@field DaggerLarge D_WeaponSubtype
---@field DaggerSmall D_WeaponSubtype
---@field MaceLarge D_WeaponSubtype
---@field MaceMedium D_WeaponSubtype
---@field MaceSmall D_WeaponSubtype
---@field StaffLarge D_WeaponSubtype
---@field StaffMedium D_WeaponSubtype
---@field StaffSmall D_WeaponSubtype
---@field SpearLarge D_WeaponSubtype
---@field SpearMedium D_WeaponSubtype
---@field SpearSmall D_WeaponSubtype
---@field SwordLarge D_WeaponSubtype
---@field SwordMedium D_WeaponSubtype
---@field SwordSmall D_WeaponSubtype
---@field Ua D_WeaponSubtype
---@field TwohandAxe D_WeaponSubtype
---@field TwohandMace D_WeaponSubtype
---@field TwohandSpear D_WeaponSubtype
---@field TwohandSword D_WeaponSubtype
---@field AtlatlLarge D_WeaponSubtype
---@field AtlatlSmall D_WeaponSubtype
---@field BowLarge D_WeaponSubtype
---@field BowSmall D_WeaponSubtype
---@field CrossbowLarge D_WeaponSubtype
---@field CrossbowSmall D_WeaponSubtype
---@field Caster D_WeaponSubtype
---@field CovenantShield D_WeaponSubtype
---@type D_WeaponSubtype
D_WeaponSubtype = { }
D_WeaponSubtype.GetValues = function()
  return {"Undef","AxeLarge","AxeMedium","AxeSmall","DaggerLarge","DaggerSmall","MaceLarge","MaceMedium","MaceSmall","StaffLarge","StaffMedium","StaffSmall","SpearLarge","SpearMedium","SpearSmall","SwordLarge","SwordMedium","SwordSmall","Ua","TwohandAxe","TwohandMace","TwohandSpear","TwohandSword","AtlatlLarge","AtlatlSmall","BowLarge","BowSmall","CrossbowLarge","CrossbowSmall","Caster"}
end
D_WeaponSubtype.FromValue = function(value)
  for i,val in ipairs(D_WeaponSubtype.GetValues()) do
    if val==value then
      return i-1
    end
  end
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
  },{
    __index = function (t, k)
      local k_num
      if type(k)=="string" then
        k_num = tonumber(k)
      end
      if not k_num then
        return k
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
      local k_num
      if type(k)=="string" then
        k_num = tonumber(k)
      end
      if not k_num then
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
      local k_num
      if type(k)=="string" then
        k_num = tonumber(k)
      end
      if not k_num then
        return k
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
      local k_num
      if type(k)=="string" then
        k_num = tonumber(k)
      end
      if not k_num then
        return k
      elseif k_num > 9009 and t[k_num-9009]~=nil then
        return t[k_num-9009]
      else
        return k
      end
    end
  })
}
