-- Add a button to show quest texts in different languages
-- https://github.com/Cancri55E/WowUkrainizer

-- Definition:
-- WowUkrainizer\Core\DbContext.lua


local _, addon = ...

do
    local ADDON_NAME = "WowUkrainizer";

    local requiredMethods = {
        "WowUkrainizer_GetTranslatedQuestData",
    };

    local function OnAddOnLoaded()
        local GetTranslatedQuestData = WowUkrainizer_GetTranslatedQuestData;

        local translator = {
            name = ADDON_NAME,
            font = "Interface/AddOns/WowUkrainizer/assets/Classic_UA_FRIZQT.ttf",
            questDataGetter = function(questID)
                local duiQuestData;
                local questData = GetTranslatedQuestData(questID);

                if questData then
                    duiQuestData = {};
                    duiQuestData.title = questData.Title;
                    duiQuestData.description = questData.Description;
                    duiQuestData.objective = questData.ObjectivesText;
                    duiQuestData.progress = questData.ProgressText;
                    duiQuestData.completion = questData.CompletionText;
                end

                return duiQuestData
            end,
        };
        DialogueUIAPI.SetTranslator(translator);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end