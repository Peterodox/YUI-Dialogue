-- (Optional) Replace player name with RP name

local _, addon = ...

local INSTALLED_RP_ADDON;


local function EnableUseRoleplayName()
    addon.CallbackRegistry:Trigger("UseRoleplayName", true);
end


do  --Eavesdropper
    local ADDON_NAME = "Eavesdropper";
    --https://www.curseforge.com/wow/addons/eavesdropper

    local function OnAddOnLoaded()
        local questModifier = addon.API.GetGlobalObject("ED.QuestText.SubstitutePlayerPreferredName");
        if questModifier then
            local testRun = questModifier("Test");
            if testRun and testRun ~= "" then
                INSTALLED_RP_ADDON = ADDON_NAME;
                addon.SetDialogueTextModifier(questModifier);
                local chatModifier = addon.API.GetGlobalObject("ED.NPCDialogue.SubstitutePlayerPreferredName");
                addon.SetChatTextModifier(chatModifier or questModifier);
                EnableUseRoleplayName();
            end

            addon.GetRoleplayName = addon.API.GetGlobalObject("ED.QuestText.GetPlayerPreferredName");
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


do  --Total RP 3: RP Name in Quest Text
    local ADDON_NAME = "tRP3_RPNameInQuests";
    --https://www.curseforge.com/wow/addons/trp3-rpnameinquests

    local function OnAddOnLoaded()
        local questModifier = TRP3_RPNameInQuests_CompleteRename;
        if questModifier then
            local testRun = questModifier("Test");     --In case something went wrong
            if testRun and testRun ~= "" then
                INSTALLED_RP_ADDON = ADDON_NAME;
                addon.SetDialogueTextModifier(questModifier);
                addon.SetChatTextModifier(questModifier);
                EnableUseRoleplayName();
            end
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


local function GetInstalledRPAddOnName()
    return INSTALLED_RP_ADDON
end
addon.GetInstalledRPAddOnName = GetInstalledRPAddOnName;
