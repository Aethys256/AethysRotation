--- ============================ HEADER ============================
  -- HeroLib
  local HL      = HeroLib;
  local Cache   = HeroCache;
  local Unit    = HL.Unit;
  local Player  = Unit.Player;
  local Pet     = Unit.Pet;
  local Target  = Unit.Target;
  local Spell   = HL.Spell;
  local Item    = HL.Item;
-- HeroRotation
  local HR      = HeroRotation;
-- Spells
  local SpellAffli   = Spell.Warlock.Affliction;
  local SpellDemo    = Spell.Warlock.Demonology;
  local SpellDestro  = Spell.Warlock.Destruction;
-- Lua

  SpellAffli.AbsoluteCorruption = Spell(196103)
  SpellAffli.Haunt:RegisterInFlight()
--- ============================ CONTENT ============================
-- Affliction, ID: 265
  HL.AddCoreOverride ("Spell.IsCastableP",
    function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
      local RangeOK = true;
      if Range then
        local RangeUnit = ThisUnit or Target;
        RangeOK = RangeUnit:IsInRange( Range, AoESpell );
      end
      local BaseCheck = self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and RangeOK
      if self == SpellAffli.SummonPet then
          return BaseCheck and not (Pet:IsActive() or Player:BuffP(SpellAffli.GrimoireofSacrificeBuff))
      else
        return BaseCheck
      end
    end
  , 265);

  HL.AddCoreOverride ("Player.SoulShardsP",
    function (self)
      local Shard = WarlockPowerBar_UnitPower(self.UnitID)
      if not Player:IsCasting() then
        return Shard
      else
        if Player:IsCasting(SpellAffli.UnstableAffliction)
            or Player:IsCasting(SpellAffli.SeedOfCorruption) then
          return Shard - 1
        elseif Player:IsCasting(SpellAffli.SummonPet) then
          return Shard - 1
        else
          return Shard
        end
      end
    end
  , 265);

  HL.AddCoreOverride ("Spell.CooldownRemainsP",
      function (self, BypassRecovery, Offset)
        if self == SpellAffli.VileTaint and Player:IsCasting(self) then
          return 20;
        elseif self == SpellAffli.Haunt and Player:IsCasting(self) then
          return 15;
        else
          return self:CooldownRemains( BypassRecovery, Offset or "Auto" );
        end
      end
  , 265);
  local BaseUnitDebuffRemains
  BaseUnitDebuffRemains = HL.AddCoreOverride ("Unit.DebuffRemains",
      function (self, Spell, AnyCaster, Offset)
        BaseReturn = BaseUnitDebuffRemains(self, Spell, AnyCaster, Offset)
        if Spell == SpellAffli.UnstableAffliction1Debuff and Player:IsCasting(SpellAffli.UnstableAffliction) then
          if BaseReturn > 0 then return BaseReturn else return 8 end
        elseif (Spell == SpellAffli.UnstableAffliction2Debuff
             or Spell == SpellAffli.UnstableAffliction3Debuff
             or Spell == SpellAffli.UnstableAffliction4Debuff
             or Spell == SpellAffli.UnstableAffliction5Debuff) and Player:IsCasting(SpellAffli.UnstableAffliction) then
              if BaseReturn > 0 then return BaseReturn
              elseif (BaseUnitDebuffRemains(self, HL.UnstableAfflictionDebuffsPrev[Spell], AnyCaster, Offset) > 0) then return 8 else return 0 end
        elseif Spell == SpellAffli.HauntDebuff and (Player:IsCasting(SpellAffli.Haunt) or SpellAffli.Haunt:InFlight()) then
          return 15
        elseif Spell == SpellAffli.CorruptionDebuff and SpellAffli.AbsoluteCorruption:IsAvailable() then
          if self:Debuff(Spell, nil, AnyCaster) then return 9999 else return 0 end
        else
          return BaseUnitDebuffRemains(self, Spell, AnyCaster, Offset)
        end
      end
  , 265)
-- Demonology, ID: 266

-- Returns the amount of wild imps that are up
HL.AddCoreOverride("Player.PetStack",
function (PetType)
  PetType = PetType or false
  local count = 0
  if not HL.GuardiansTable.Pets or not PetType then
    return count
  end
  for key, petData in pairs(HL.GuardiansTable.Pets) do
    if petData[1] == PetType then
      count = count +1
    end 
  end
  return count
end
, 266)

HL.AddCoreOverride("Player.PetDuration",
function (PetType)
  if not PetType then return 0 end
  local PetsInfo = {
    [55659] = {"Wild Imp", 20},
    [99737] = {"Wild Imp", 20},
    [98035] = {"Dreadstalker", 12},
    [17252] = {"Felguard", 15},
    [135002] = {"Demonic Tyrant", 15},
  }
  local maxduration = 0
  for key, Value in pairs(HL.GuardiansTable.Pets) do
    if HL.GuardiansTable.Pets[key][1] == PetType then
      if (PetsInfo[HL.GuardiansTable.Pets[key][2]][2] - (GetTime() - HL.GuardiansTable.Pets[key][3])) > maxduration then
        maxduration = HL.OffsetRemains((PetsInfo[HL.GuardiansTable.Pets[key][2]][2] - (GetTime() - HL.GuardiansTable.Pets[key][3])), "Auto" );
      end
    end
  end
  return maxduration
end
, 266)

HL.AddCoreOverride ("Player.SoulShardsP",
    function (self)
      local Shard = Player:SoulShards()
      if not Player:IsCasting() then
        return Shard
      else
        if Player:IsCasting(SpellDemo.NetherPortal) then
          return Shard - 3
        elseif Player:IsCasting(SpellDemo.CallDreadStalkers) and Player:BuffRemainsP(SpellDemo.DemonicCallingBuff) == 0 then
          return Shard - 2
        elseif Player:IsCasting(SpellDemo.CallDreadStalkers) and Player:BuffRemainsP(SpellDemo.DemonicCallingBuff) > 0 then
          return Shard - 1
        elseif Player:IsCasting(SpellDemo.SummonVilefiend) then
          return Shard - 1
        elseif Player:IsCasting(SpellDemo.SummonFelguard) then
          return Shard - 1
        elseif Player:IsCasting(SpellDemo.HandOfGuldan) then
          if Shard > 3 then
            return Shard - 3
          else
            return 0
          end
        elseif Player:IsCasting(SpellDemo.Demonbolt) then
          if Shard >= 4 then
            return 5
          else
            return Shard + 2
          end
        elseif Player:IsCasting(SpellDemo.Shadowbolt) then
          if Shard == 5 then
            return Shard
          else
            return Shard + 1
          end
        else
          return Shard
        end
      end
    end
  , 266);

-- Destruction, ID: 267

-- Example (Arcane Mage)
-- HL.AddCoreOverride ("Spell.IsCastableP",
-- function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
--   if Range then
--     local RangeUnit = ThisUnit or Target;
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and RangeUnit:IsInRange( Range, AoESpell );
--   elseif self == SpellArcane.MarkofAluneth then
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and not Player:IsCasting(self);
--   else
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0;
--   end;
-- end
-- , 62);
