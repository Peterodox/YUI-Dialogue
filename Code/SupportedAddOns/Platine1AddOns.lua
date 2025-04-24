-- For Platine's language addons https://legacy.curseforge.com/members/platine1/projects
-- TTS based on the current language (translation) rather than then client's language


local _, addon = ...


do
    local ADDON_NAME = nil;

    local requiredMethods = {
        "QTR_QuestData",    --table, translated
    };

    local function OnAddOnLoaded()
        addon.UseFontStringForTTS(true);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end