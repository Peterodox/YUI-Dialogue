---- Implementation Guide ----

--[[
    local translator = {
        name = "AddOn Name",                                            --string: Your addon's name
        font = "Interface/AddOns/DialogueUI/Fonts/frizqt__.ttf",        --string: Your font's path (optional)
        questDataGetter = function(questID)
            local duiQuestData;
            local questData = YourQuestDataProvider(questID);

            --The following step formats your quest data to ours

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
    };

    DialogueUIAPI.SetTranslator(translator)   --Global API
--]]




local temp, addon = ...
temp = false;
local API = addon.API;

local ENABLE_TRANSLATION = false;

local QuestDataGetter;
local QuestFont;
local TranslatorName;
local OnTranslatorLoaded;


local function UseFontStringForTTS(state)
    if state then
        function API.GetQuestTTSContentExternal()
            local body, title = addon.DialogueUI:GetTTSTextFromFontStrings();
            if body then
                local content = {
                    body = body,
                    title = title,
                };
                return content
            end
        end
    else
        API.GetQuestTTSContentExternal = nil;
    end
end
addon.UseFontStringForTTS = UseFontStringForTTS;


local function IsTranslatorEnabled()
    return ENABLE_TRANSLATION
end
addon.IsTranslatorEnabled = IsTranslatorEnabled;


local function SetTranslator(translator)
    if translator and type(translator == "table") then
        if not translator.name then
            API.PrintMessage("Missing Translator Name");
            return
        end

        if type(translator.questDataGetter) == "function" then
            TranslatorName = translator.name;
            if type(translator.font) == "string" then
                QuestFont = translator.font;
            elseif type(translator.font) == "function" then
                QuestFont = translator.font();
            end
            QuestDataGetter = translator.questDataGetter;
        else
            API.PrintMessage("Missing Translator Data Provider");
            return
        end

        if not temp then
            temp = true;
            C_Timer.After(0.1, function()
                OnTranslatorLoaded();
            end);
        elseif translator.name ~= TranslatorName then
            API.PrintMessage(string.format("You already had a Translator: %s, but %s is trying to add another one.", TranslatorName, translator.name));
        end
    end
end
DialogueUIAPI.SetTranslator = SetTranslator;
addon.SetTranslator = SetTranslator;


function OnTranslatorLoaded()
    if not (QuestDataGetter and TranslatorName) then return end;

    local L = addon.L;

    addon.FontUtil:SetMultiLanguageQuestFont(QuestFont);

    ENABLE_TRANSLATION = true;

    local function GetQuestTextExternal(questID, method)
        if not ENABLE_TRANSLATION then
            return
        end

        local data = QuestDataGetter(questID)
        if data then
            if method == "Detail" then
                return data.title, data.description, data.objective
            elseif method == "Progress" then
                return data.title, data.progress, data.objective
            elseif method == "Complete" then
                return data.title, data.completion
            elseif method == "Greeting" then
                return data.title, data.greeting
            end
        end
    end
    API.GetQuestTextExternal = GetQuestTextExternal;

    local function IsQuestTranslationAvailable(questID)
        local data = QuestDataGetter(questID);
        local title = data and data.title;
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
                TooltipFrame:AddLeftLine(L["Translator Source"]..TranslatorName, 1, 1, 1, true);
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