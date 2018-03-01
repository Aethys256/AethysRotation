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
  AR.GUISettings.APL.Warrior = {
    Commons = {
      OffGCDasOffGCD = {
        Pummel = true,
        Racials = true,
        Avatar = true,
        BattleCry = true,
      }
    },

    Arms = {
      ShowPoPP = false,
      WarbreakerEnabled = true,
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
        -- Abilities
        Warbreaker = false,
        Bladestorm = false,
        Ravager = false,
      },
      OffGCDasOffGCD = {
        -- Abilities
        FocusedRage = true,
        -- Items
      },
    },

    Fury = {
      ShowPoOW = false,
      ShowPoPP = false,
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
        -- Abilities
        DragonRoar = true,
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        -- Abilities
        Bloodbath = true,
        -- Items
        PotionoftheOldWar = true,
        PotionOfProlongedPower = true,
        UmbralMoonglaives = true,
      }
    }
  };

  AR.GUI.LoadSettingsRecursively(AR.GUISettings);

  -- Child Panels
  local ARPanel = AR.GUI.Panel;
  local CP_Warrior = CreateChildPanel(ARPanel, "Warrior");
  local CP_Arms = CreateChildPanel(CP_Warrior, "Arms");
  local CP_Fury = CreateChildPanel(CP_Warrior, "Fury");

  -- Shared Warrior settings
  CreateARPanelOptions(CP_Warrior, "APL.Warrior.Commons");

  -- Arms settings
  CreateARPanelOptions(CP_Arms, "APL.Warrior.Arms");
  CreatePanelOption("CheckButton", CP_Arms, "APL.Warrior.Arms.WarbreakerEnabled", "Enable Warbreaker", "Disable this if you want to omit Warbreaker from the rotation.");
  CreatePanelOption("CheckButton", CP_Arms, "APL.Warrior.Arms.ShowPoPP", "Show Potion of Prolonged Power", "Enable this if you want it to show you when to use Potion of Prolonged Power.");

  -- Fury settings
  CreateARPanelOptions(CP_Fury, "APL.Warrior.Fury");
  CreatePanelOption("CheckButton", CP_Fury, "APL.Warrior.Fury.ShowPoOW", "Show Potion of the Old War", "Enable this if you want it to show you when to use Potion of the Old War.");
  CreatePanelOption("CheckButton", CP_Fury, "APL.Warrior.Fury.ShowPoPP", "Show Potion of Prolonged Power", "Enable this if you want it to show you when to use Potion of Prolonged Power.");
