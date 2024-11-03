-- Auto Complete Quest
-- Hallow's End: Candy Bucket

local _, addon = ...
local L = addon.L;
local GossipDataProvider = addon.GossipDataProvider;
local GetQuestName = addon.API.GetQuestName

local AutoCompleteQuestName = {};

local AutoCompleteQuestID = {
    [43323] = true,     --A Time to Reflect
    [43461] = true,     --A Time to Reflect
    [82783] = true,     --Chromie's Codex
    [82817] = true,     --Disturbance Detected: Blackrock Depths

    [83240] = true,     --Theater Troupe
    [83333] = true,     --Gearing Up For Trouble
    [80670] = true,     --Eye of the Weaver
    [80671] = true,     --Blade of the General
    [80672] = true,     --Hand of the Vizier
    [82946] = true,     --Rollin' Down in the Deeps
    [82679] = true,     --Archives: Seeking History
    [82452] = true,     --Worldsoul: World Quest
    [82482] = true,     --Worldsoul: Snuffling
    [82483] = true,     --Worldsoul: Spreading the Light
    [82485] = true,
    [82516] = true,     --Worldsoul: Forging a Pact
    [82453] = true,     --Worldsoul: Encore!
    [82489] = true,
    [82659] = true,
    [82678] = true,
    [82490] = true,
    [82491] = true,
    [82492] = true,
    [82493] = true,
    [82494] = true,
    [82495] = true,
    [82496] = true,
    [82497] = true,
    [82498] = true,
    [82499] = true,
    [82500] = true,
    [82501] = true,
    [82502] = true,
    [82503] = true,
    [82504] = true,
    [82505] = true,
    [82506] = true,
    [82507] = true,
    [82508] = true,
    [82509] = true,
    [82510] = true,
    [82511] = true,
    [82512] = true,     --Worldsoul: World Boss
    [82706] = true,
    [82707] = true,
    [82708] = true,
    [82709] = true,
    [82710] = true,
    [82711] = true,
    [82712] = true,
    [82746] = true,
};

local ExampleQuest = {
    --{questID, fallbackName}
    --Use the questID to get the quest name
    {28981, L["AutoCompleteQuest HallowsEnd"]},      --Candy Bucket
};

function GossipDataProvider:ShouldAutoCompleteQuest(questID, questName)
    if AutoCompleteQuestID[questID] or (questName and AutoCompleteQuestName[questName]) then
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
