-- Add a button to show quest texts in Czech language
-- CurseForge link https://www.curseforge.com/wow/addons/czech-quests-retail for retail

-- QuestData Keys:
-- title, objective, description (detail), progress, completion, 

-- Peter's Note:
--- 1. Pull Request by https://github.com/jarosr93
--- 2. The translations in Czech Quests have no line-break.
--- 3. We added a new method FontUtil:SetMultiLanguageQuestFont


local _, addon = ...
local API = addon.API;


do
    local ADDON_NAME = "CzechQuests";

    local requiredMethods = {
        "CzechQuestsAddon_Store",   --SavedVariables
        "CzechQuestsAddon",         --Data
    };

    local function OnAddOnLoaded()
        local L = addon.L;

        -- Friz Quadrata TT with czech support
        addon.FontUtil:SetMultiLanguageQuestFont("Interface/AddOns/CzechQuests/Assets/Fonts/frizquadratatt_cz.ttf");

        local ENABLE_TRANSLATION = true;
        local CzechQuestsAddon = CzechQuestsAddon;

        local function GetQuestData(questID)
            return CzechQuestsAddon:GetData("quest", questID);
        end

        local function GetQuestTextExternal(questID, method)
            if not ENABLE_TRANSLATION then
                return
            end

            local data = GetQuestData(questID)
            if data then
                if method == "Detail" then
                    return data.title, data.description, data.objective
                elseif method == "Progress" then
                    return data.title, data.progress, data.objective
                elseif method == "Complete" then
                    return data.title, data.completion
                elseif method == "Greeting" then
                    --Not supported by addon
                end
            end
        end
        API.GetQuestTextExternal = GetQuestTextExternal;

        local function IsQuestTranslationAvailable(questID)
            if CzechQuestsAddon.data.quest and CzechQuestsAddon.data.quest[questID] then
                return true
            end
        end
        API.IsQuestTranslationAvailable = IsQuestTranslationAvailable;

        local MainFrame = addon.DialogueUI;
        local TranslatorButton = MainFrame.TranslatorButton;

        local function HideTranslatorButton()
            MainFrame:ShowTranslatorButton(false);
        end

        local function TranslatorButton_OnClick(button)
            ENABLE_TRANSLATION = not ENABLE_TRANSLATION;
            MainFrame:OnSettingsChanged();
        end

        local function OnHandleEvent(event)
            if not (event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE") then
                HideTranslatorButton();
            end
        end
        addon.CallbackRegistry:Register("DialogueUI.HandleEvent", OnHandleEvent);

        local function OnViewingQuest(questID)
            HideTranslatorButton();
            if IsQuestTranslationAvailable(questID) then
                MainFrame:ShowTranslatorButton(true);
                TranslatorButton = MainFrame.TranslatorButton;

                TranslatorButton:SetOnClickFunc(TranslatorButton_OnClick);

                function TranslatorButton:ShowTooltip()
                    local TooltipFrame = addon.SharedTooltip;
                    TooltipFrame:Hide();
                    TooltipFrame:SetOwner(self, "TOPRIGHT");
                    TooltipFrame:AddLeftLine(L["Translator Source"]..ADDON_NAME, 1, 1, 1, true);
                    if ENABLE_TRANSLATION then
                        TooltipFrame:AddLeftLine(L["Translator Click To Hide Translation"], 1, 0.82, 0);
                    else
                        TooltipFrame:AddLeftLine(L["Translator Click To Show Translation"], 1, 0.82, 0);
                    end
                    TooltipFrame:Show();
                end

                TranslatorButton:Show();
            end
        end
        addon.CallbackRegistry:Register("ViewingQuest", OnViewingQuest);

    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end