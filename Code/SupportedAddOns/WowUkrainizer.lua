-- Add a button to show quest texts in different languages
-- https://github.com/Cancri55E/WowUkrainizer

-- Definition:
-- WowUkrainizer\Core\DbContext.lua


local _, addon = ...
local API = addon.API;


do
    local ADDON_NAME = "WowUkrainizer";

    local requiredMethods = {
        "WowUkrainizer_GetTranslatedQuestTitle",
        "WowUkrainizer_GetTranslatedQuestData",
    };

    local function OnAddOnLoaded()
        local L = addon.L;

        -- Friz Quadrata TT with czech support
        addon.FontUtil:SetMultiLanguageQuestFont("Interface/AddOns/WowUkrainizer/assets/Classic_UA_FRIZQT.ttf");

        local ENABLE_TRANSLATION = true;

        local GetTranslatedQuestTitle = WowUkrainizer_GetTranslatedQuestTitle;
        local GetTranslatedQuestData = WowUkrainizer_GetTranslatedQuestData;

        local function GetQuestTextExternal(questID, method)
            if not ENABLE_TRANSLATION then
                return
            end

            local data = GetTranslatedQuestData(questID)
            if data then
                if method == "Detail" then
                    return data.Title, data.Description, data.ObjectivesText
                elseif method == "Progress" then
                    return data.Title, data.ProgressText, data.ObjectivesText
                elseif method == "Complete" then
                    return data.Title, data.CompletionText
                elseif method == "Greeting" then
                    --Not supported by addon
                end
            end
        end
        API.GetQuestTextExternal = GetQuestTextExternal;

        local function IsQuestTranslationAvailable(questID)
            local title = GetTranslatedQuestTitle(questID);
            return title and title ~= ""
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