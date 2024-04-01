-- (Optional) Replace player name with RP name

local _, addon = ...

local tRP3_RPNameInQuests_Installed = false;
local INSTALLED_RP_ADDON;

do
    local ADDON_NAME = "TotalRP3";

    local function OnAddOnLoaded()
        INSTALLED_RP_ADDON = ADDON_NAME;
    end

    --addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


do
    local ADDON_NAME = "MyRolePlay";

    local function OnAddOnLoaded()
        INSTALLED_RP_ADDON = ADDON_NAME;
    end

    --addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


do
    local ADDON_NAME = "tRP3_RPNameInQuests";
    --Call their method if installed
    --Also set DialogueUI_DB.UseRoleplayName to "true"
    --https://www.curseforge.com/wow/addons/trp3-rpnameinquests

    local function OnAddOnLoaded()
        if TRP3_RPNameInQuests_CompleteRename then
            local textRun = TRP3_RPNameInQuests_CompleteRename("Test");     --In case something went wrong
            if textRun and textRun ~= "" then
                tRP3_RPNameInQuests_Installed = true;
                INSTALLED_RP_ADDON = ADDON_NAME;
                addon.SetDialogueTextModifier(TRP3_RPNameInQuests_CompleteRename);
                addon.SetDBValue("UseRoleplayName", true);
            end
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


local function GetInstalledRPAddOnName()
    return INSTALLED_RP_ADDON
end
addon.GetInstalledRPAddOnName = GetInstalledRPAddOnName;