-- Add a button to show quest texts in different languages
-- See "UpdateQuestTranslationFrame()" in  https://github.com/rubenzantingh/MultiLanguage/blob/master/MultiLanguage.lua
-- Note: this addon has several global variables in lowercase initial (e.g. questData, languageCode), possibly an oversight

-- QuestData Keys:
-- title, objective, description (detail), progress, completion, 


local _, addon = ...
local API = addon.API;


do
    local ADDON_NAME = "MultiLanguage";

    local requiredMethods = {
        "MultiLanguageOptions",     --SavedVariables
        "MultiLanguageQuestData",   --Data
    };

    local languageLookup = {
        en = "enUS",
        fr = "frFR",
        de = "deDE",
        es = "esES",
        pt = "ptBR",
        ru = "ruRU",
        cn = "zhCN",
        ko = "koKR";
        it = "itIT",
    };

    local function OnAddOnLoaded()
        local gsub = string.gsub;
        local currentLocale = GetLocale();
        local L = addon.L;

        local ENABLE_TRANSLATION = true;

        local function GetDataByID(database, id)
            local language = MultiLanguageOptions and MultiLanguageOptions.SELECTED_LANGUAGE;
            if language and languageLookup[language] ~= currentLocale then
                return database and database[language] and database[language][id] or nil;
            end
        end

        local function GetQuestData(questID)
            return GetDataByID(MultiLanguageQuestData, questID)
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
            if GetQuestData(questID) then
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

        local function OnViewingQuest(questID, method)
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


        -- A copy of their code:
        -- e.g. texts start with [q2] means it should be green
        local textColorCodes = {
            ["[q]"] = "|cFFFFD100",
            ["[q0]"] = "|cFF9D9D9D",
            ["[q2]"] = "|cFF00FF00",
            ["[q3]"] = "|cFF0070DD",
            ["[q4]"] = "|cFFA335EE",
            ["[q5]"] = "|cFFFF8000",
            ["[q6]"] = "|cFFE5CC80",
            ["[q7]"] = "|cFF00CCFF",
            ["[q8]"] = "|cFF00CCFF"
        }

        local function escapeMagic(s)
            return gsub(s, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
        end

        local function SetColorForLine(line, spellColorLinePassed)
            if spellColorLinePassed then
                return "|cFFFFD100" .. line .. "|r"
            end

            for pattern, colorCode in pairs(textColorCodes) do
                local escapedPattern = escapeMagic(pattern)
                local _, count = gsub(line, escapedPattern, "")

                if count > 0 then
                    line = gsub(line, escapedPattern, "")
                    return colorCode .. line .. "|r"
                end
            end

            return "|cFFFFFFFF" .. line .. "|r"
        end
        -- End of copy


        local function AddTooltipTranslation(enabled, tooltip, database, id, isSpell)
            if enabled then
                local item = GetDataByID(database, id);
                if item and item.name then
                    tooltip:AddBlankLine();
                    tooltip:AddLine(SetColorForLine(item.name));
                    if item.additional_info then
                        local spellColorLinePassed;
                        for line in item.additional_info:gmatch("[^\r\n]+") do
                            local firstWord, secondWord = line:match("{(.-)}%s-{(.-)}");
                            if firstWord and secondWord then
                                tooltip:AddDoubleLine(SetColorForLine(firstWord, spellColorLinePassed), SetColorForLine(secondWord, spellColorLinePassed));
                            else
                                tooltip:AddLine(SetColorForLine(line, spellColorLinePassed), 1, 1, 1, true);
                            end

                            if isSpell and not spellColorLinePassed then
                                if string.find(line, "%[q%]") then
                                    spellColorLinePassed = true;
                                end
                            end
                        end
                    end
                    tooltip:Show();
                end
            end
        end

        local function AddItemTranslation(tooltip, itemID, itemLink)
            local enabled = MultiLanguageOptions and MultiLanguageOptions.ITEM_TRANSLATIONS;
            AddTooltipTranslation(enabled, tooltip, MultiLanguageItemData, itemID);
        end
        addon.CallbackRegistry:Register("SharedTooltip.SetItem", AddItemTranslation);


        local function AddSpellTranslation(tooltip, spellID)
            local enabled = MultiLanguageOptions and MultiLanguageOptions.SPELL_TRANSLATIONS;
            AddTooltipTranslation(enabled, tooltip, MultiLanguageSpellData, spellID, true);
        end
        addon.CallbackRegistry:Register("SharedTooltip.SetSpell", AddSpellTranslation);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end