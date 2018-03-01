--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, addonTable = ...;
  -- AethysRotation
  local AR = AethysRotation;
  -- AethysCore
  local AC = AethysCore;
  -- File Locals
  local GUI = AC.GUI;
  local CreateChildPanel = GUI.CreateChildPanel;
  local CreatePanelOption = GUI.CreatePanelOption;
  local CreateARPanelOption = AR.GUI.CreateARPanelOption;
  local CreateARPanelOptions = AR.GUI.CreateARPanelOptions;


--- ============================ CONTENT ============================
  -- Default settings
  AR.GUISettings.APL.Rogue = {
    Commons = {
      -- SoloMode Settings
      CrimsonVialHP = 0,
      FeintHP = 0,
      -- Evisc/Env Mantle Damage Offset Multiplier
      EDMGMantleOffset = 2,
      StealthOOC = true,
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
        CrimsonVial = true,
        Feint = true,
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        Racials = true,
        -- Stealth CDs
        Vanish = true,
        -- Abilities
        Kick = true,
        MarkedforDeath = true,
        Sprint = true,
        Stealth = true
      }
    },
    Assassination = {
      -- Damage Offsets
      EnvenomDMGOffset = 3,
      MutilateDMGOffset = 3,
      -- Poison Refresh (in minutes)
      PoisonRefresh = 15,
      PoisonRefreshCombat = 3,
      -- Suggest Multi-DoT at FoK Range
      RangedMultiDoT = true,
      -- FoK Rotation Toggle
      FoKRotation = false,
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        -- Abilities
        Vendetta = true,
      }
    },
    Outlaw = {
      -- Roll the Bones Logic, accepts "SimC", "1+ Buff" and every "RtBName".
      -- "SimC", "1+ Buff", "Broadsides", "Buried Treasure", "Grand Melee", "Jolly Roger", "Shark Infested Waters", "True Bearing"
      RolltheBonesLogic = "SimC",
      -- SoloMode Settings
      RolltheBonesLeechHP = 60, -- % HP threshold to reroll for Grand Melee.
      -- Blade Flurry TimeOut
      BFOffset = 2,
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        -- Abilities
        AdrenalineRush = true,
        CurseoftheDreadblades = true,
        BladeFlurry = true,
      }
    },
    Subtlety = {
      -- Damage Offsets
      EviscerateDMGOffset = 3,
      -- Shadow Dance Eco Mode (Min Fractional Charges before using it while CDs are disabled)
      ShDEcoCharge = 2.55,
      -- Single Target MfD as DPS CD
      STMfDAsDPSCD = false,
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        -- Abilities
        ShadowBlades = true,
        SymbolsofDeath = true,
        ShadowDance = true,
      },
      -- Stealth Macro Enable/Disable Options
      StealthMacro = {
        -- Abilities
        Vanish = true,
        Shadowmeld = true,
        ShadowDance = true
      }
    }
  };

  AR.GUI.LoadSettingsRecursively(AR.GUISettings);

  -- Child Panels
  local ARPanel = AR.GUI.Panel;
  local CP_Rogue = CreateChildPanel(ARPanel, "Rogue");
  local CP_Assassination = CreateChildPanel(CP_Rogue, "Assassination");
  local CP_Outlaw = CreateChildPanel(CP_Rogue, "Outlaw");
  local CP_Subtlety = CreateChildPanel(CP_Rogue, "Subtlety");
  -- Controls
  -- Rogue
  CreatePanelOption("Slider", CP_Rogue, "APL.Rogue.Commons.CrimsonVialHP", {0, 100, 1}, "Crimson Vial HP", "Set the Crimson Vial HP threshold.");
  CreatePanelOption("Slider", CP_Rogue, "APL.Rogue.Commons.FeintHP", {0, 100, 1}, "Feint HP", "Set the Feint HP threshold.");
  CreatePanelOption("Slider", CP_Rogue, "APL.Rogue.Commons.EDMGMantleOffset", {1, 5, 0.25}, "Mantle Damage Offset", "Set the Evisc/Env Mantle Damage Offset.");
  CreatePanelOption("CheckButton", CP_Rogue, "APL.Rogue.Commons.StealthOOC", "Stealth Reminder (OOC)", "Show Stealth Reminder when out of combat.");
  CreateARPanelOptions(CP_Rogue, "APL.Rogue.Commons");
  -- Assassination
  CreatePanelOption("Slider", CP_Assassination, "APL.Rogue.Assassination.EnvenomDMGOffset", {1, 5, 0.25}, "Envenom DMG Offset", "Set the Envenom DMG Offset.");
  CreatePanelOption("Slider", CP_Assassination, "APL.Rogue.Assassination.MutilateDMGOffset", {1, 5, 0.25}, "Mutilate DMG Offset", "Set the Mutilate DMG Offset.");
  CreatePanelOption("Slider", CP_Assassination, "APL.Rogue.Assassination.PoisonRefresh", {5, 55, 1}, "OOC Poison Refresh", "Set the timer for the Poison Refresh (OOC)");
  CreatePanelOption("Slider", CP_Assassination, "APL.Rogue.Assassination.PoisonRefreshCombat", {0, 55, 1}, "Combat Poison Refresh", "Set the timer for the Poison Refresh (In Combat)");
  CreatePanelOption("CheckButton", CP_Assassination, "APL.Rogue.Assassination.RangedMultiDoT", "Suggest Ranged Multi-DoT", "Suggest multi-DoT targets at Fan of Knives range (10 yards) instead of only melee range. Disabling will only suggest DoT targets within melee range.");
  CreatePanelOption("CheckButton", CP_Assassination, "APL.Rogue.Assassination.FoKRotation", "Enable Fan of Knives Rotation", "Suggest using Fan of Knives on a single target instead of Mutilate.");
  CreateARPanelOptions(CP_Assassination, "APL.Rogue.Assassination");
  -- Outlaw
  CreatePanelOption("Dropdown", CP_Outlaw, "APL.Rogue.Outlaw.RolltheBonesLogic", {"SimC", "1+ Buff", "Broadsides", "Buried Treasure", "Grand Melee", "Jolly Roger", "Shark Infested Waters", "True Bearing"}, "Roll the Bones Logic", "Define the Roll the Bones logic to follow.");
  CreatePanelOption("Slider", CP_Outlaw, "APL.Rogue.Outlaw.RolltheBonesLeechHP", {1, 100, 1}, "Roll the Bones Leech HP", "Set the HP threshold before re-rolling for the leech buff (working only if Solo Mode is enabled).");
  CreatePanelOption("Slider", CP_Outlaw, "APL.Rogue.Outlaw.BFOffset", {1, 5, 1}, "Blade Flurry Offset", "Set the Blade Flurry timer before suggesting to disable it (to compensate fast movement).");
  CreateARPanelOptions(CP_Outlaw, "APL.Rogue.Outlaw");
  -- Subtlety
  CreatePanelOption("Slider", CP_Subtlety, "APL.Rogue.Subtlety.EviscerateDMGOffset", {1, 5, 0.25}, "Eviscerate DMG Offset", "Set the Eviscerate DMG Offset.");
  CreatePanelOption("Slider", CP_Subtlety, "APL.Rogue.Subtlety.ShDEcoCharge", {2, 3, 0.1}, "ShD Eco Charge", "Set the Shadow Dance Eco Charge threshold.");
  CreatePanelOption("CheckButton", CP_Subtlety, "APL.Rogue.Subtlety.STMfDAsDPSCD", "ST Marked for Death as DPS CD", "Enable if you want to put Single Target Marked for Death shown as Off GCD (top icons) instead of Suggested.");
  CreateARPanelOptions(CP_Subtlety, "APL.Rogue.Subtlety");
  CreatePanelOption("CheckButton", CP_Subtlety, "APL.Rogue.Subtlety.StealthMacro.Vanish", "Stealth Combo - Vanish", "Allow suggesting Vanish stealth ability combos (recommended)");
  CreatePanelOption("CheckButton", CP_Subtlety, "APL.Rogue.Subtlety.StealthMacro.Shadowmeld", "Stealth Combo - Shadowmeld", "Allow suggesting Shadowmeld stealth ability combos (recommended)");
  CreatePanelOption("CheckButton", CP_Subtlety, "APL.Rogue.Subtlety.StealthMacro.ShadowDance", "Stealth Combo - Shadow Dance", "Allow suggesting Shadow Dance stealth ability combos (recommended)");
