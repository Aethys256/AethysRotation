--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Pet = Unit.Pet
local Target = Unit.Target
local Spell = HL.Spell
local MultiSpell = HL.MultiSpell
local Item = HL.Item
-- HeroRotation
local HR = HeroRotation
local AoEON = HR.AoEON
local CDsON = HR.CDsON
local Cast  = HR.Cast
-- Lua

--- ============================ CONTENT ============================
--- ======= APL LOCALS =======
-- Commons
local Everyone = HR.Commons.Everyone
local Warlock = HR.Commons.Warlock

-- GUI Settings
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Warlock.Commons,
  Destruction = HR.GUISettings.APL.Warlock.Destruction
}

-- Spells
local S = Spell.Warlock.Destruction

-- Items
local I = Item.Warlock.Destruction
local TrinketsOnUseExcludes = {--  I.TrinketName:ID(),
}
local OdrShawloftheYmirjarEquipped  = Player:HasLegendaryEquipped(174)

-- Enemies
local Enemies40y, Enemies40yCount, EnemiesCount8ySplash

-- Rotation Variables
local var_pool_soul_shards
local var_havoc_active
local var_havoc_guid
local var_havoc_remains

S.SummonInfernal:RegisterInFlight()
S.ChaosBolt:RegisterInFlight()
S.Incinerate:RegisterInFlight()

HL:RegisterForEvent(function()
    OdrShawloftheYmirjarEquipped = Player:HasLegendaryEquipped(174)
  end, "PLAYER_EQUIPMENT_CHANGED")

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function UnitWithHavoc(enemies)
    for k in pairs(enemies) do
      local CycleUnit = enemies[k]
      if CycleUnit:DebuffUp(S.Havoc) then
        return true,CycleUnit:GUID(),CycleUnit:DebuffRemains(S.Havoc)
      end
    end
    return false
end

local function InfernalTime()
    return HL.GuardiansTable.InfernalDuration or (S.SummonInfernal:InFlight() and 30) or 0
  end

local function EvaluateCycleSoulFireMain(TargetUnit)
    --refreshable&soul_shard<=4&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
    return (TargetUnit:DebuffRefreshable(S.ImmolateDebuff)  and (not S.Cataclysm:IsAvailable() or S.Cataclysm:CooldownRemains() > TargetUnit:DebuffRemains(S.ImmolateDebuff)))
end

local function EvaluateCycleImmolateMain(TargetUnit)
    --refreshable&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
    return (TargetUnit:DebuffRefreshable(S.ImmolateDebuff) and (not S.Cataclysm:IsAvailable() or S.Cataclysm:CooldownRemains() > TargetUnit:DebuffRemains(S.ImmolateDebuff)))
end

local function EvaluateCycleImmolateAoE(TargetUnit)
    --remains<5&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
    return (TargetUnit:DebuffRemains(S.ImmolateDebuff) < 5 and (not S.Cataclysm:IsAvailable() or S.Cataclysm:CooldownRemains() > TargetUnit:DebuffRemains(S.ImmolateDebuff)))
end

local function CDs()
    --summon_infernal
    if S.SummonInfernal:IsCastable() then
        if Cast(S.SummonInfernal, Settings.Destruction.GCDasOffGCD.SummonInfernal) then return "summon_infernal cds 1"; end
    end
    --dark_soul_instability
    if S.DarkSoulInstability:IsCastable() then
        if Cast(S.DarkSoulInstability, Settings.Destruction.OffGCDasOffGCD.DarkSoulInstability) then return "dark_soul_instability cds 2"; end
    end
    --potion,if=pet.infernal.active
    if Settings.Commons.Enabled.Potions and I.PotionofSpectralIntellect:IsReady() and InfernalTime() > 0 then
        if Cast(I.PotionofSpectralIntellect, nil, Settings.Commons.DisplayStyle.Potions) then return "potion cds 3"; end
    end
    --berserking,if=pet.infernal.active
    if S.Berserking:IsCastable() and InfernalTime() > 0 then
        if Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "berserking cds 4"; end
    end
    --blood_fury,if=pet.infernal.active
    if S.BloodFury:IsCastable() and InfernalTime() > 0 then
        if Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "blood_fury cds 5"; end
    end
    --fireblood,if=pet.infernal.active
    if S.Fireblood:IsCastable() and InfernalTime() > 0 then
        if Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "fireblood cds 6"; end
    end
    --use_items,if=pet.infernal.active|target.time_to_die<20
    if InfernalTime() > 0 then
        local TrinketToUse = Player:GetUseableTrinkets(TrinketsOnUseExcludes)
        if TrinketToUse then
            if Cast(TrinketToUse, nil, Settings.Commons.DisplayStyle.Trinkets) then return "Generic use_items for " .. TrinketToUse:Name(); end
        end
    end
end

local function Aoe()
    --rain_of_fire,if=pet.infernal.active&(!cooldown.havoc.ready|active_enemies>3)
    if S.RainofFire:IsCastable() and Player:SoulShards() >= 3 and InfernalTime() > 0 and (S.Havoc:CooldownRemains() > 0 or EnemiesCount8ySplash > 3) then
        if Cast(S.RainofFire, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "rain_of_fire aoe 1"; end
    end
    --soul_rot
    if S.SoulRot:IsCastable() then
        if Cast(S.SoulRot, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.SoulRot)) then return "soul_rot aoe 2"; end
    end
    --channel_demonfire,if=dot.immolate.remains>cast_time
    if S.ChannelDemonfire:IsCastable() and Target:DebuffRemains(S.ImmolateDebuff) > S.ChannelDemonfire:CastTime() then
        if Cast(S.ChannelDemonfire, nil, nil, not Target:IsInRange(40)) then return "channel_demonfire aoe 3"; end
    end
    --immolate,cycle_targets=1,if=remains<5&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
    if S.Immolate:IsCastable() then
        if Everyone.CastCycle(S.Immolate, Enemies40y, EvaluateCycleImmolateAoE, not Target:IsSpellInRange(S.Immolate)) then return "immolate main 6"; end
    end
    --call_action_list,name=cds
    if CDsON() then
        local ShouldReturn = CDs(); if ShouldReturn then return ShouldReturn; end
    end
    --havoc,cycle_targets=1,if=!(target=self.target)&active_enemies<4
    if S.Havoc:IsCastable() and EnemiesCount8ySplash < 4 then
        local TargetGUID = Target:GUID()
        for _, CycleUnit in pairs(Enemies40y) do
            if CycleUnit:GUID() ~= TargetGUID and not CycleUnit:IsFacingBlacklisted() and not CycleUnit:IsUserCycleBlacklisted() then
                HR.CastLeftNameplate(CycleUnit, S.Havoc)
                break
            end
        end
    end
    --rain_of_fire
    if S.RainofFire:IsCastable() and Player:SoulShards() >= 3 then
        if Cast(S.RainofFire, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "rain_of_fire aoe 9"; end
    end
    --havoc,cycle_targets=1,if=!(self.target=target)
    if S.Havoc:IsCastable() then
        local TargetGUID = Target:GUID()
        for _, CycleUnit in pairs(Enemies40y) do
            if CycleUnit:GUID() ~= TargetGUID and not CycleUnit:IsFacingBlacklisted() and not CycleUnit:IsUserCycleBlacklisted() then
                HR.CastLeftNameplate(CycleUnit, S.Havoc)
                break
            end
        end
    end
    --decimating_bolt,if=(soulbind.lead_by_example.enabled|!talent.fire_and_brimstone.enabled)
    if S.DecimatingBolt:IsCastable() and (S.LeadByExample:SoulbindEnabled() or not S.FireandBrimstone:IsAvailable()) then
        if Cast(S.DecimatingBolt, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.DecimatingBolt)) then return "decimating_bolt aoe 11"; end
    end
    --incinerate,if=talent.fire_and_brimstone.enabled&buff.backdraft.up&soul_shard<5-0.2*active_enemies
    if S.Incinerate:IsCastable() and S.FireandBrimstone:IsAvailable() and Player:BuffUp(S.Backdraft) and Player:SoulShards() < 5 - 0.2 * EnemiesCount8ySplash then
        if Cast(S.Incinerate, nil, nil, not Target:IsSpellInRange(S.Incinerate)) then return "incinerate aoe 12"; end
    end
    --soul_fire
    if S.SoulFire:IsCastable() then
        if Cast(S.SoulFire, nil, nil, not Target:IsSpellInRange(S.SoulFire)) then return "soul_fire aoe 13"; end
    end
    --conflagrate,if=buff.backdraft.down
    if S.Conflagrate:IsCastable() and Player:BuffDown(S.Backdraft) then
        if Cast(S.Conflagrate, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "conflagrate aoe 14"; end
    end
    --shadowburn,if=target.health.pct<20
    if S.Shadowburn:IsCastable() and Target:HealthPercentage() < 20 then
        if Cast(S.Shadowburn, nil, nil, not Target:IsSpellInRange(S.Shadowburn)) then return "shadowburn aoe 15"; end
    end
    --scouring_tithe,if=!(talent.fire_and_brimstone.enabled|talent.inferno.enabled)
    if S.ScouringTithe:IsCastable() and not (S.FireandBrimstone:IsAvailable() or S.Inferno:IsAvailable()) then
        if Cast(S.ScouringTithe, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.ScouringTithe)) then return "decimating_bolt aoe 16"; end
    end
    --impending_catastrophe,if=!(talent.fire_and_brimstone.enabled|talent.inferno.enabled)
    if S.ImpendingCatastrophe:IsCastable() and not (S.FireandBrimstone:IsAvailable() or S.Inferno:IsAvailable()) then
        if Cast(S.ImpendingCatastrophe, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.ImpendingCatastrophe)) then return "impending_catastrophe aoe 17"; end
    end
    --incinerate
    if S.Incinerate:IsCastable() then
        if Cast(S.Incinerate, nil, nil, not Target:IsSpellInRange(S.Incinerate)) then return "incinerate aoe 18"; end
    end
end

local function Havoc()
    --conflagrate,if=buff.backdraft.down&soul_shard>=1&soul_shard<=4
    if S.Conflagrate:IsCastable() and Player:BuffDown(S.Backdraft) and Player:SoulShards() > 1 and Player:SoulShards() <= 4 then
        if Cast(S.Conflagrate, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "conflagrate havoc 1"; end
    end
    --soul_fire,if=cast_time<havoc_remains
    if S.SoulFire:IsCastable() and S.SoulFire:CastTime() < var_havoc_remains then
        if Cast(S.SoulFire, nil, nil, not Target:IsSpellInRange(S.SoulFire)) then return "soul_fire havoc 2"; end
    end
    --decimating_bolt,if=cast_time<havoc_remains&soulbind.lead_by_example.enabled
    if S.DecimatingBolt:IsCastable() and S.DecimatingBolt:CastTime() < var_havoc_remains and S.LeadByExample:SoulbindEnabled() then
        if Cast(S.DecimatingBolt, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.DecimatingBolt)) then return "decimating_bolt havoc 3"; end
    end
    --scouring_tithe,if=cast_time<havoc_remains
    if S.ScouringTithe:IsCastable() and S.ScouringTithe:CastTime() < var_havoc_remains then
        if Cast(S.ScouringTithe, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.ScouringTithe)) then return "decimating_bolt havoc 4"; end
    end
    --immolate,if=talent.internal_combustion.enabled&remains<duration*0.5|!talent.internal_combustion.enabled&refreshable
    if S.Immolate:IsCastable() and ((S.InternalCombustion:IsAvailable() and Target:DebuffRemains(S.ImmolateDebuff) < S.Immolate:BaseDuration() * 0.5) or (not S.InternalCombustion:IsAvailable() and Target:DebuffRefreshable(S.ImmolateDebuff))) then
        if Cast(S.Immolate, nil, nil, not Target:IsSpellInRange(S.Immolate)) then return "immolate havoc 5"; end
    end
    --chaos_bolt,if=cast_time<havoc_remains
    if S.ChaosBolt:IsCastable() and Player:SoulShards() >= 2 and S.ChaosBolt:CastTime() < var_havoc_remains then
        if Cast(S.ChaosBolt, nil, nil, not Target:IsSpellInRange(S.ChaosBolt)) then return "chaos_bolt havoc 6"; end
    end
    --shadowburn
    if S.Shadowburn:IsCastable() then
        if Cast(S.Shadowburn, nil, nil, not Target:IsSpellInRange(S.Shadowburn)) then return "shadowburn havoc 7"; end
    end
    --incinerate,if=cast_time<havoc_remains
    if S.Incinerate:IsCastable() and S.Incinerate:CastTime() < var_havoc_remains then
        if Cast(S.Incinerate, nil, nil, not Target:IsSpellInRange(S.Incinerate)) then return "incinerate havoc 8"; end
    end
end

--- ======= MAIN =======
local function APL()
  -- Unit Update
  Enemies40y = Player:GetEnemiesInRange(40)
  if AoEON() then
    Enemies40yCount = #Enemies40y
    EnemiesCount8ySplash = Target:GetEnemiesInSplashRangeCount(8)
  else
    Enemies40yCount = 1
    EnemiesCount8ySplash = 1
  end
  var_havoc_active,var_havoc_guid,var_havoc_remains = UnitWithHavoc(Enemies40y)

  if Everyone.TargetIsValid() then

    if S.SummonPet:IsCastable() and (not S.GrimoireofSacrifice:IsAvailable() or Player:BuffDown(S.GrimoireofSacrificeBuff)) then
        if Cast(S.SummonPet, Settings.Destruction.GCDasOffGCD.SummonPet) then return "summon_pet"; end
    end

    -- Precombat
    if (not Player:AffectingCombat()) then
        --flask
        --food
        --augmentation
        --summon_pet
        --grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
        if S.GrimoireofSacrifice:IsCastable() and Player:BuffDown(S.GrimoireofSacrificeBuff) then
            if Cast(S.GrimoireofSacrifice, Settings.Destruction.GCDasOffGCD.GrimoireOfSacrifice) then return "grimoire_of_sacrifice precombat 2"; end
        end
        --snapshot_stats
        -- fleshcraft
        if S.Fleshcraft:IsCastable() then
          if Cast(S.Fleshcraft, nil, Settings.Commons.DisplayStyle.Covenant) then return "fleshcraft precombat 3"; end
        end
        --soul_fire
        if S.SoulFire:IsCastable() and not Player:IsCasting(S.SoulFire) then
            if Cast(S.SoulFire, nil, nil, not Target:IsSpellInRange(S.SoulFire)) then return "soul_fire precombat 3"; end
        end
        --incinerate,if=!talent.soul_fire.enabled3
        if S.Incinerate:IsCastable() and not S.SoulFire:IsAvailable() and not Player:IsCasting(S.Incinerate) then
            if Cast(S.Incinerate, nil, nil, not Target:IsSpellInRange(S.Incinerate)) then return "incinerate precombat 3"; end
        end
        --conflagrate manually added 1
        if S.Conflagrate:IsCastable() and S.RoaringBlaze:IsAvailable() then
            if Cast(S.Conflagrate, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "conflagrate manually added 1"; end
        end
        --cataclysm manually added 2
        if S.Cataclysm:IsCastable() then
            if Cast(S.Cataclysm, nil, nil, not Target:IsInRange(40)) then return "cataclysm maimanually added 2"; end
        end
        --immolate manually added 3
        if S.Immolate:IsCastable() then
            if Cast(S.Immolate, nil, nil, not Target:IsSpellInRange(S.Immolate)) then return "immolate manually added 3"; end
        end
    end

    --call_action_list,name=havoc,if=havoc_active&active_enemies>1&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
    if var_havoc_active and Enemies40yCount > 1 and Enemies40yCount < 5 - num(S.Inferno:IsAvailable()) + num(S.Inferno:IsAvailable() and S.InternalCombustion:IsAvailable()) then
        local ShouldReturn = Havoc(); if ShouldReturn then return ShouldReturn; end
    end
    -- fleshcraft,if=soulbind.volatile_solvent,cancel_if=buff.volatile_solvent_humanoid.up
    if S.Fleshcraft:IsCastable() and (S.VolatileSolvent:SoulbindEnabled() and Player:BuffDown(S.VolatileSolventHumanBuff)) then
      if Cast(S.Fleshcraft, nil, Settings.Commons.DisplayStyle.Covenant) then return "fleshcraft main 1"; end
    end
    --conflagrate,if=talent.roaring_blaze.enabled&debuff.roaring_blaze.remains<1.5
    if S.Conflagrate:IsCastable() and S.RoaringBlaze:IsAvailable() and Target:DebuffRemains(S.RoaringBlazeDebuff) < 1.5 then
        if Cast(S.Conflagrate, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "conflagrate main 2"; end
    end
    --cataclysm,if=!(pet.infernal.active&dot.immolate.remains+1>pet.infernal.remains)|spell_targets.cataclysm>1
    if S.Cataclysm:IsCastable() and (not (InfernalTime() > 0 and Target:DebuffRemains(S.ImmolateDebuff) +1 > InfernalTime()) or EnemiesCount8ySplash > 1) then
        if Cast(S.Cataclysm, nil, nil, not Target:IsInRange(40)) then return "cataclysm main 3"; end
    end
    --call_action_list,name=aoe,if=active_enemies>2
    if EnemiesCount8ySplash > 2 then
        local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
    end
    --soul_fire,cycle_targets=1,if=refreshable&soul_shard<=4&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
    if S.SoulFire:IsCastable() and Player:SoulShards() <= 4 then
        if Everyone.CastCycle(S.SoulFire, Enemies40y, EvaluateCycleSoulFireMain, not Target:IsSpellInRange(S.SoulFire)) then return "soul_fire main 5"; end
    end
    --immolate,cycle_targets=1,if=refreshable&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
    if S.Immolate:IsCastable() then
        if Everyone.CastCycle(S.Immolate, Enemies40y, EvaluateCycleImmolateMain, not Target:IsSpellInRange(S.Immolate)) then return "immolate main 6"; end
    end
    --immolate,if=talent.internal_combustion.enabled&action.chaos_bolt.in_flight&remains<duration*0.5
    if S.Immolate:IsCastable() and S.InternalCombustion:IsAvailable() and S.ChaosBolt:InFlight() and Target:DebuffRemains(S.ImmolateDebuff) < S.Immolate:BaseDuration() * 0.5 then
        if Cast(S.Immolate, nil, nil, not Target:IsSpellInRange(S.Immolate)) then return "immolate main 7"; end
    end
    --call_action_list,name=cds
    if CDsON() then
        local ShouldReturn = CDs(); if ShouldReturn then return ShouldReturn; end
    end
    --channel_demonfire
    if S.ChannelDemonfire:IsCastable() and Target:DebuffRemains(S.ImmolateDebuff) > 0 then
        if Cast(S.ChannelDemonfire, nil, nil, not Target:IsInRange(40)) then return "channel_demonfire main 9"; end
    end
    --scouring_tithe
    if S.ScouringTithe:IsCastable() then
        if Cast(S.ScouringTithe, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.ScouringTithe)) then return "scouring_tithe main 10"; end
    end
    --decimating_bolt
    if S.DecimatingBolt:IsCastable() then
        if Cast(S.DecimatingBolt, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.DecimatingBolt)) then return "decimating_bolt main 11"; end
    end
    --havoc,cycle_targets=1,if=!(target=self.target)&(dot.immolate.remains>dot.immolate.duration*0.5|!talent.internal_combustion.enabled)
    if S.Havoc:IsCastable() and AoEON() then
        local TargetGUID = Target:GUID()
        for _, CycleUnit in pairs(Enemies40y) do
            if CycleUnit:GUID() ~= TargetGUID and not CycleUnit:IsFacingBlacklisted() and not CycleUnit:IsUserCycleBlacklisted() and (CycleUnit:DebuffRemains(S.ImmolateDebuff) > S.Immolate:BaseDuration() * 0.5 or not S.InternalCombustion:IsAvailable()) then
                HR.CastLeftNameplate(CycleUnit, S.Havoc)
                break
            end
        end
    end
    --impending_catastrophe
    if S.ImpendingCatastrophe:IsCastable() then
        if Cast(S.ImpendingCatastrophe, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.ImpendingCatastrophe)) then return "impending_catastrophe main 13"; end
    end
    --soul_rot
    if S.SoulRot:IsCastable() then
        if Cast(S.SoulRot, nil, Settings.Commons.DisplayStyle.Covenant, not Target:IsSpellInRange(S.SoulRot)) then return "soul_rot main 14"; end
    end
    --havoc,if=runeforge.odr_shawl_of_the_ymirjar.equipped
    if S.Havoc:IsCastable() and OdrShawloftheYmirjarEquipped then
        if Cast(S.Havoc, nil, nil, not Target:IsSpellInRange(S.Havoc)) then return "havoc main 15"; end
    end
    --variable,name=pool_soul_shards,value=active_enemies>1&cooldown.havoc.remains<=10
    --|cooldown.summon_infernal.remains<=15&talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains<=15
    --|talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains<=15&(cooldown.summon_infernal.remains>target.time_to_die|cooldown.summon_infernal.remains+cooldown.summon_infernal.duration>target.time_to_die)
    var_pool_soul_shards = (Enemies40yCount > 1 and S.Havoc:CooldownRemains() <= 10) 
        or (S.SummonInfernal:CooldownRemains() <= 15 and S.DarkSoulInstability:IsAvailable() and S.DarkSoulInstability:CooldownRemains() <= 15) 
        or (S.DarkSoulInstability:IsAvailable() and S.DarkSoulInstability:CooldownRemains() <= 15 and (S.SummonInfernal:CooldownRemains() > Target:TimeToDie() or S.SummonInfernal:CooldownRemains() + 180 > Target:TimeToDie()))
    --conflagrate,if=buff.backdraft.down&soul_shard>=1.5-0.3*talent.flashover.enabled&!variable.pool_soul_shards
    if S.Conflagrate:IsCastable() and Player:BuffDown(S.Backdraft) and Player:SoulShards() >= 1.5 - 0.3 * num(S.Flashover:IsAvailable()) and var_pool_soul_shards then
        if Cast(S.Conflagrate, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "conflagrate main 17"; end
    end
    --chaos_bolt,if=buff.dark_soul_instability.up
    if S.ChaosBolt:IsCastable() and Player:SoulShards() >= 2 and Player:BuffUp(S.DarkSoulInstability) then
        if Cast(S.ChaosBolt, nil, nil, not Target:IsSpellInRange(S.ChaosBolt)) then return "chaos_bolt main 18"; end
    end
    --chaos_bolt,if=buff.backdraft.up&!variable.pool_soul_shards&!talent.eradication.enabled
    if S.ChaosBolt:IsCastable() and Player:SoulShards() >= 2 and Player:BuffUp(S.Backdraft) and not var_pool_soul_shards and not S.Eradication:IsAvailable() then
        if Cast(S.ChaosBolt, nil, nil, not Target:IsSpellInRange(S.ChaosBolt)) then return "chaos_bolt main 19"; end
    end
    --chaos_bolt,if=!variable.pool_soul_shards&talent.eradication.enabled&(debuff.eradication.remains<cast_time|buff.backdraft.up)
    if S.ChaosBolt:IsCastable() and Player:SoulShards() >= 2 and not var_pool_soul_shards and S.Eradication:IsAvailable() and (Target:DebuffRemains(S.EradicationDebuff) < S.ChaosBolt:CastTime() or Player:BuffUp(S.Backdraft)) then
        if Cast(S.ChaosBolt, nil, nil, not Target:IsSpellInRange(S.ChaosBolt)) then return "chaos_bolt main 20"; end
    end
    --shadowburn,if=!variable.pool_soul_shards|soul_shard>=4.5
    if S.Shadowburn:IsCastable() and (not var_pool_soul_shards or Player:SoulShards() >= 4.5) then
        if Cast(S.Shadowburn, nil, nil, not Target:IsSpellInRange(S.Shadowburn)) then return "shadowburn main 21"; end
    end
    --chaos_bolt,if=(soul_shard>=4.5-0.2*active_enemies)
    if S.ChaosBolt:IsCastable() and Player:SoulShards() >= 4.5 - 0.2 * EnemiesCount8ySplash and not Player:IsCasting(S.ChaosBolt) then
        if Cast(S.ChaosBolt, nil, nil, not Target:IsSpellInRange(S.ChaosBolt)) then return "chaos_bolt main 22"; end
    end
    --conflagrate,if=charges>1
    if S.Conflagrate:IsCastable() and S.Conflagrate:Charges() > 1 then
        if Cast(S.Conflagrate, nil, nil, not Target:IsSpellInRange(S.Conflagrate)) then return "conflagrate main 23"; end
    end
    --incinerate
    if S.Incinerate:IsCastable() then
        if Cast(S.Incinerate, nil, nil, not Target:IsSpellInRange(S.Incinerate)) then return "incinerate main 24"; end
    end

    return
  end
end

local function OnInit()
    HR.Print("Destruction Warlock rotation is currently a work in progress.")
end

HR.SetAPL(267, APL, OnInit)