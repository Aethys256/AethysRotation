--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AR = ...;
  -- AethysCore
  local AC = AethysCore;
  local Utils = AC.Utils;
  -- Lua
  local stringformat = string.format;
  local stringgmatch = string.gmatch;
  local strsplit = strsplit;
  local tableconcat = table.concat;
  -- File Locals
  local CreatePanelOption = AC.GUI.CreatePanelOption;
  local StringToNumberIfPossible = Utils.StringToNumberIfPossible;


--- ============================ CONTENT ============================
  AR.GUI = {};

  function AR.GUI.LoadSettingsRecursively (Table, KeyChain)
    local KeyChain = KeyChain or "";
    for Key, Value in pairs(Table) do
      -- Generate the NewKeyChain
      local NewKeyChain;
      if KeyChain ~= "" then
        NewKeyChain = KeyChain .. "." .. Key;
      else
        NewKeyChain = Key;
      end
      -- Continue the table browsing
      if type(Value) == "table" then
        AR.GUI.LoadSettingsRecursively(Value, NewKeyChain);
      -- Update the value
      else
        -- Check if the final key is a string or a number (the case for table values with numeric index)
        local ParsedKey = StringToNumberIfPossible(Key);
        -- Load the saved value
        local DBSetting = AethysRotationDB.GUISettings[NewKeyChain];
        -- If the saved value exists, take it
        if DBSetting ~= nil then
          Table[ParsedKey] = DBSetting;
        -- Else, save the default value
        else
          AethysRotationDB.GUISettings[NewKeyChain] = Value;
        end
      end
    end
  end

  do
    local function OffGCDName (Name)
      return stringformat("Show as Off GCD: %s", Name);
    end
    local function OffGCDDesc (Name)
      return stringformat("Enable if you want to put %s shown as Off GCD (top icons) instead of Main (Middle icon).", Name);
    end
    local CreateARPanelOption = {
      Enabled = function (Panel, Setting, Name)
        CreatePanelOption("CheckButton", Panel, Setting, "Show: " .. Name, "Enable if you want to show when to use " .. Name .. ".");
      end,
      GCDasOffGCD = function (Panel, Setting, Name)
        CreatePanelOption("CheckButton", Panel, Setting, OffGCDName(Name), OffGCDDesc(Name));
      end,
      OffGCDasOffGCD = function (Panel, Setting, Name)
        CreatePanelOption("CheckButton", Panel, Setting, OffGCDName(Name), OffGCDDesc(Name));
      end
    };
    function AR.GUI.CreateARPanelOption (Type, Panel, Setting, ...)
      CreateARPanelOption[Type](Panel, Setting, ...);
    end

    function AR.GUI.CreateARPanelOptions (Panel, Settings)
      -- Find the corresponding setting table
      local SettingsSplit = {strsplit(".", Settings)};
      local SettingsTable = AR.GUISettings;
      for i = 1, #SettingsSplit do
        SettingsTable = SettingsTable[SettingsSplit[i]];
      end
      -- Iterate over all options available
      for Type, _ in pairs(CreateARPanelOption) do
        SettingsType = SettingsTable[Type];
        if SettingsType then
          for SettingName, _ in pairs(SettingsType) do
            -- Split the key on uppercase matches
            local Name = "";
            for Word in stringgmatch(SettingName, "[A-Z][a-z]+") do
              if Name == "" then
                Name = Word;
              else
                Name = Name .. " " .. Word;
              end
            end
            -- Rewrite the setting string
            local Setting = tableconcat({Settings, Type, SettingName}, ".");
            -- Construct the option
            AR.GUI.CreateARPanelOption(Type, Panel, Setting, Name);
          end
        end
      end
    end
  end
