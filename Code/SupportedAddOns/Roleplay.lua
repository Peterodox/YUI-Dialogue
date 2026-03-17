-- (Optional) Replace player name with RP name

local _, addon = ...

local INSTALLED_RP_ADDON;


local function EnableUseRoleplayName()
    addon.CallbackRegistry:Trigger("UseRoleplayName", true);
end


do  --Total RP 3: RP Name in Quest Text
    local ADDON_NAME = "tRP3_RPNameInQuests";
    --https://www.curseforge.com/wow/addons/trp3-rpnameinquests

    local function OnAddOnLoaded()
        if TRP3_RPNameInQuests_CompleteRename then
            local testRun = TRP3_RPNameInQuests_CompleteRename("Test");     --In case something went wrong
            if testRun and testRun ~= "" then
                INSTALLED_RP_ADDON = ADDON_NAME;
                addon.SetDialogueTextModifier(TRP3_RPNameInQuests_CompleteRename);
                EnableUseRoleplayName();
            end
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


do  --Eavesdropper
    local ADDON_NAME = "Eavesdropper";
    --https://www.curseforge.com/wow/addons/eavesdropper

    local function OnAddOnLoaded()
        local func = addon.API.GetGlobalObject("ED.QuestText.SubstitutePlayerPreferredName");
        if func then
            local testRun = func("Test");
            if testRun and testRun ~= "" then
                INSTALLED_RP_ADDON = ADDON_NAME;
                addon.SetDialogueTextModifier(func);
                EnableUseRoleplayName();
            end

            addon.GetRoleplayName = addon.API.GetGlobalObject("ED.QuestText.GetPlayerPreferredName");
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


local function GetInstalledRPAddOnName()
    return INSTALLED_RP_ADDON
end
addon.GetInstalledRPAddOnName = GetInstalledRPAddOnName;
