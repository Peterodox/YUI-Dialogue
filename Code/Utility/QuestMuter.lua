-- Fix for WoW repeatedly offering a quest that you're ready on, such as:
-- (in TWW, possibly fixed now) Certain weekly quests popped up when you flew around.
-- "A New Adventure Awaits": When you reach Chromie Time level cap.
-- The incident seems rare and usually goes away after /reload. But it can be quite annoying when it happens, as our UI constantly shows/hides.

-- The fix: after QUEST_DETAIL fires, check if the quest is already accepted.
-- The catch: certain auto-accepted quests (like the ones in starting zones post CATA), can become "isOnQuest == true" before QUEST_DETAIL fires if the quest data is yet loaded during the game session.
-- so we track when the quest was accepted, and ignore those that have been accepted long before.


local _, addon = ...
local API = addon.API;


local time = time;
local QuestLogQuestIDGetter = C_QuestLog.GetQuestIDForLogIndex or GetQuestIDFromLogIndex;
local IsOnQuest = C_QuestLog.IsOnQuest;


local QuestMuter = CreateFrame("Frame");
QuestMuter.questTime = {};

QuestMuter:SetScript("OnEvent", function(self, event, questID)
    if event == "QUEST_ACCEPTED" then
        self.questTime[questID] = time();
    elseif event == "QUEST_REMOVED" then
        -- Turned-in quests are also deemed "removed"
        self.questTime[questID] = nil;
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);

        local currentTime = time();
        local numEntries = (C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries()) or GetNumQuestLogEntries() or 0;
        local id;

        for i = 1, numEntries do
            id = QuestLogQuestIDGetter(i);
            if id and id ~= 0 then
                self.questTime[id] = currentTime;
            end
        end
    end
end);

QuestMuter:RegisterEvent("QUEST_ACCEPTED");
QuestMuter:RegisterEvent("QUEST_REMOVED");
QuestMuter:RegisterEvent("PLAYER_ENTERING_WORLD");


function API.ShouldMuteQuestDetail(questID)
    -- Called by Core.lua
    if IsOnQuest(questID) then
        if QuestMuter.questTime[questID] and (time() - QuestMuter.questTime[questID]) > 1 then
            return false;
        end
    end
    return false;
end
