local _, addon = ...
local L = addon.L;
local API = addon.API;


---Currently we only show quest level for Forever, until Classic has these APIs as well.
local CAN_SHOW_QUEST_LEVEL = (not addon.IS_RETAIL) and UnitQuestTrivialLevelRangeScaling ~= nil and C_QuestLog.GetQuestDifficultyLevel ~= nil;
addon.CAN_SHOW_QUEST_LEVEL = CAN_SHOW_QUEST_LEVEL; -- Determines if we should add quest level option to the settings


local Def = {
    LevelFormatNoBracket = "|cff%s%d|r ",
    LevelFormatBrackets = "|cff%s[%d]|r",

    -- If true, show level on the quest list (on the left of the quest title)
    -- If false, show the difficulty name on the right of the quest button.
    ShowQuestLevel = true,
};


---@return number difficultyIndex `2` Very Hard | `1` Hard | `0` Normal | `-1` Easy | `-2` Trivial
local function GetDifficultyIndex(levelDiff)
    if levelDiff > 5 then
        return 2;
    elseif levelDiff >= 3 then
        return 1;
    elseif levelDiff >= -1 then
        -- WoW Classic treats quest below your level as Easy
        -- But you might out-level the current step so we change this level cutoff to -1
        return 0;
    elseif levelDiff >= -5 then
        return -1;
    else
        return -2;
    end
end


---Colors for different themes are slightly different
local QuestDifficultyColors = {
    Bright = {
        VeryHard = "f85658",
        Hard = "ff9845",
        Normal = "e9c21b",
        Easy = "81c285",
        Trivial = "b2a6a5",
        Unfinished = "b3b3b3",
    },

    Dark = {
        VeryHard = "ff7370",
        Hard = "ed953c",
        Normal = "d9c726",
        Easy = "91be93",
        Trivial = "b2a6a5",
        Unfinished = "b3b3b3",
    },
};

local ActiveDifficultyColors = QuestDifficultyColors.Bright;


local IsQuestLevelCached;
local GetQuestLevel;
local GetQuestDifficultyLabel;
local GetQuestDifficultyLabelForQuestButton;

if CAN_SHOW_QUEST_LEVEL then
    ---`questLevel` can be 0 when the data isn't cached.
    function IsQuestLevelCached(questID)
        local questLevel = C_QuestLog.GetQuestDifficultyLevel(questID);
        return questLevel and questLevel > 0;
    end

    ---@return number? questLevel
    ---@return number? questLevelDiff questLevel - playerLevel
    function GetQuestLevel(questID)
        local playerLevel = UnitLevel("player");
        local questLevel = C_QuestLog.GetQuestDifficultyLevel(questID);
        if questLevel and questLevel > 0 then
            return questLevel, questLevel - playerLevel;
        end
    end

    function GetQuestDifficultyLabel(questID)
        local _, diff = GetQuestLevel(questID);
        if diff then
            local index = GetDifficultyIndex(diff);
            if index >= 2 then
                return L["Quest Difficulty VeryHard"];
            elseif index >= 1 then
                return L["Quest Difficulty Hard"];
            elseif index >= 0 then
                return L["Quest Difficulty Normal"];
            elseif index >= -1 then
                return L["Quest Difficulty Easy"];
            else
                return L["Quest Difficulty Trivial"];
            end
        end
    end

    function GetQuestDifficultyLabelForQuestButton(questID)
        if Def.ShowQuestLevel then return; end
        return GetQuestDifficultyLabel(questID);
    end
else
    IsQuestLevelCached = API.AlwaysTrue;
    GetQuestLevel = API.Nop;
    GetQuestDifficultyLabel = API.Nop;
    GetQuestDifficultyLabelForQuestButton = API.Nop;
end

API.IsQuestLevelCached = IsQuestLevelCached;
API.GetQuestLevel = GetQuestLevel;
API.GetQuestDifficultyLabel = GetQuestDifficultyLabel;
API.GetQuestDifficultyLabelForQuestButton = GetQuestDifficultyLabelForQuestButton;


function API.GetColorizedQuestLevel(questID)
    if not Def.ShowQuestLevel then return; end

    if not IsQuestLevelCached(questID) then
        return "   "; -- Use space as placeholder in case the title become to long after adding level
    end

    local questLevel, diff = GetQuestLevel(questID);
    if diff then
        local index = GetDifficultyIndex(diff);
        local hex;
        if API.IsPlayerOnQuest(questID) and not API.ReadyForTurnIn(questID) then
            hex = ActiveDifficultyColors.Unfinished;
        elseif index >= 2 then
            hex = ActiveDifficultyColors.VeryHard;
        elseif index >= 1 then
            hex = ActiveDifficultyColors.Hard;
        elseif index >= 0 then
            hex = ActiveDifficultyColors.Normal;
        elseif index >= -1 then
            hex = ActiveDifficultyColors.Easy;
        else
            hex = ActiveDifficultyColors.Trivial;
        end
        return string.format(Def.LevelFormatNoBracket, hex, questLevel);
    end
end


addon.CallbackRegistry:Register("ThemeChanged", function(themeID)
    if themeID == 2 then
        ActiveDifficultyColors = QuestDifficultyColors.Dark;
    else
        ActiveDifficultyColors = QuestDifficultyColors.Bright;
    end
end);

addon.CallbackRegistry:Register("SettingChanged.QuestDifficultyStyle", function(dbValue, userInput)
    Def.ShowQuestLevel = dbValue ~= 2;
    if userInput then
        addon.DialogueUI:OnSettingsChanged();
    end
end);
