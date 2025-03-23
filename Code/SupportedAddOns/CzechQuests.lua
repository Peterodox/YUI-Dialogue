-- Add a button to show quest texts in Czech language
-- CurseForge link https://www.curseforge.com/wow/addons/czech-quests-retail for retail

-- QuestData Keys:
-- title, objective, description (detail), progress, completion, 

-- Peter's Note:
--- 1. Pull Request by https://github.com/jarosr93
--- 2. The translations in Czech Quests have no line-break.
--- 3. We added a new method FontUtil:SetMultiLanguageQuestFont


local _, addon = ...


do
    local ADDON_NAME = "CzechQuests";

    local requiredMethods = {
        "CzechQuestsAddon_Store",   --SavedVariables
        "CzechQuestsAddon",         --Data
    };

    local function OnAddOnLoaded()
        local CzechQuestsAddon = CzechQuestsAddon;

        local function GetQuestData(questID)
            return CzechQuestsAddon:GetData("quest", questID);
        end

        local translator = {
            name = ADDON_NAME,
            font = "Interface/AddOns/CzechQuests/Assets/Fonts/frizquadratatt_cz.ttf",
            questDataGetter = function(questID)
                local duiQuestData;
                local questData = GetQuestData(questID);

                if questData then
                    duiQuestData = {};
                    duiQuestData.title = questData.title;                   --string: Title
                    duiQuestData.description = questData.description;       --string: Descriptions
                    duiQuestData.objective = questData.objective;           --string: Objectives
                    duiQuestData.progress = questData.progress;             --string: Quest Progress
                    duiQuestData.completion = questData.completion;         --string: Quest Completion
                    duiQuestData.greeting = questData.greeting;             --string: Greetings (optional)
                end

                return duiQuestData
            end,
        }
        addon.SetTranslator(translator);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end