-- Auto Complete Quest
-- Hallow's End: Candy Bucket

local _, addon = ...
local L = addon.L;
local GossipDataProvider = addon.GossipDataProvider;
local GetQuestName = addon.API.GetQuestName

local AutoCompleteQuestName = {};

local AutoCompleteQuestID = {

};

local ExampleQuest = {
    --{questID, fallbackName}
    --Use the questID to get the quest name
    {28981, L["AutoCompleteQuest HallowsEnd"]},      --Candy Bucket
};

function GossipDataProvider:ShouldAutoCompleteQuest(questID, questName)
    if AutoCompleteQuestID[questID] or AutoCompleteQuestName[questName] then
        return true
    end
    return false
end


local Loader = CreateFrame("Frame");

function Loader:OnEvent(event, questID, success)
    if event == "QUEST_DATA_LOAD_RESULT" then
        if AutoCompleteQuestID[questID] then
            for i, v in ipairs(ExampleQuest) do
                if questID == v[1] then
                    table.remove(ExampleQuest, i);
                    local name;
                    if success then
                        name = GetQuestName(questID);
                    end
                    name = name or v[2];
                    AutoCompleteQuestName[name] = true;
                    --print(questID, success, name, name == v[2]);
                    break
                end
            end
        end

        if #ExampleQuest == 0 then
            self:UnregisterEvent("QUEST_DATA_LOAD_RESULT");
            self:SetScript("OnEvent", nil);
            ExampleQuest = nil;
        end
    end
end

local function RequestQuestNames()
    local RequestLoadQuestByID = C_QuestLog.RequestLoadQuestByID;
    if not RequestLoadQuestByID then
        ExampleQuest = nil;
        Loader.OnEvent = nil;
        return
    end

    Loader:SetScript("OnEvent", Loader.OnEvent);
    Loader:RegisterEvent("QUEST_DATA_LOAD_RESULT");
    local questID;
    for _, v in ipairs(ExampleQuest) do
        questID = v[1];
        AutoCompleteQuestID[questID] = true;
        RequestLoadQuestByID(questID);
    end
end
addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", RequestQuestNames);
