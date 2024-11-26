local _, addon = ...
local Skimmer = CreateFrame("Frame");
addon.Skimmer = Skimmer;
--Skimmer:Hide();


local API = addon.API;
local GetDBBool = addon.GetDBBool;
local GetCustomGossipHandler = addon.GetCustomGossipHandler;
local DialogueUI = addon.DialogueUI;
local HandleAutoSelect = addon.DialogueHandleAutoSelect;
local SortFunc_GossipPrioritizeQuest = addon.SortFunc_GossipPrioritizeQuest;

local tsort = table.sort;
local CreateFrame = CreateFrame;
local InCombatLockdown = InCombatLockdown;
local CompleteQuest = CompleteQuest;
local CloseQuest = CloseQuest;
local DeclineQuest = DeclineQuest;
local GetQuestID = GetQuestID;
local UnitLevel = UnitLevel;
local C_GossipInfo = C_GossipInfo;
local GetOptions = C_GossipInfo.GetOptions;
local GetActiveQuests = C_GossipInfo.GetActiveQuests;
local GetAvailableQuests = C_GossipInfo.GetAvailableQuests;
local GetQuestText = API.GetQuestText;  --usage GetQuestText("type")    type: Detail, Progress, Complete, Greeting
local GetQuestTitle = GetTitleText;
local GetObjectiveText = GetObjectiveText;


local QuestDataProvider = {};
Skimmer.QuestDataProvider = QuestDataProvider;

local EL = CreateFrame("Frame");


do  --Event Handler
    local DialogueEvents = {
        "GOSSIP_SHOW",
        "GOSSIP_CLOSED",
        "QUEST_PROGRESS",
        "QUEST_DETAIL",
        "QUEST_FINISHED",
        "QUEST_GREETING",
        "QUEST_COMPLETE",
    };

    function EL:OnEvent(event, ...)
        print(event, GetTimePreciseSec(), ...);    --debug
        if event == "GOSSIP_SHOW" then
            local handler = GetCustomGossipHandler(...);
            if handler then
                self.customFrame = handler(...);
                return
            end

            self.showGossipFrame = Skimmer:HandleGossip();

        elseif event == "GOSSIP_CLOSED" then
            local interactionIsContinuing = ...
            if self.showGossipFrame then
                if interactionIsContinuing then
                    self.interactionIsContinuing = true;
                end
                if not self.interactionIsContinuing then
                    Skimmer:HideUI();
                end
                self.interactionIsContinuing = nil;
            elseif self.customFrame then
                if not InCombatLockdown() then
                    HideUIPanel(self.customFrame);
                end
                self.customFrame = nil;
            end
        elseif event == "QUEST_DETAIL" then
            local questID = GetQuestID();
            if QuestDataProvider:IsQueuingQuest(questID) then
                QuestDataProvider:OnQuestDetailReceived(questID);
                DeclineQuest();
            else
                Skimmer:HandleQuestDetail();
            end
        elseif event == "QUEST_FINISHED" then
            Skimmer:HideUI();
        end
    end

    function EL:ListenEvents(state)
        local method;

        if state then
            method = "RegisterEvent";
            self:SetScript("OnEvent", self.OnEvent);
        else
            method= "UnregisterEvent";
            self:SetScript("OnEvent", nil);
        end

        for _, event in ipairs(DialogueEvents) do
            self[method](self, event);
        end
    end
end

do
    function Skimmer:Init()
        self.Init = nil;

        --Object Pools
        local function CreateOptionButton()
            local f = CreateFrame("Frame", nil, self, "DUISkimmerOptionTemplate");
            return f
        end

        local function RemoveOptionButton(f)
            f:Hide();
            f:ClearAllPoints();
        end

        local function OnAcquireOptionButton(f)

        end

        self.optionButtonPool = API.CreateObjectPool(CreateOptionButton, RemoveOptionButton, OnAcquireOptionButton);
    end

    function Skimmer:ReleaseAllObjects()
        self.optionButtonPool:Release();
        self:ClearTooltipDataWatchList();
    end

    function Skimmer:OnEvent(event, ...)
        if event == "QUEST_LOG_UPDATE" then
            self:UpdateDisplayedQuests();
        elseif event == "TOOLTIP_DATA_UPDATE" then
            self:HandleTooltipDataUpdate(...)
        end
        print(event)
    end
    Skimmer:SetScript("OnEvent", Skimmer.OnEvent);

    function Skimmer:OnHide()
        C_GossipInfo.CloseGossip();
        self:ReleaseAllObjects();
        self:UnregisterEvent("QUEST_LOG_UPDATE");
    end
    Skimmer:SetScript("OnHide", Skimmer.OnHide);

    function Skimmer:OnShow()
        self:RegisterEvent("QUEST_LOG_UPDATE");
    end
    Skimmer:SetScript("OnShow", Skimmer.OnShow);
end


do
    function Skimmer:HideUI()
        self:Hide();
    end
end


do
    function Skimmer:HandleGossip()
        if DialogueUI:IsGossipHandledExternally() then return false end;

        if self.Init then
            self:Init();
        end

        local options = GetOptions();
        local activeQuests = GetActiveQuests();
        local availableQuests = GetAvailableQuests();

        if HandleAutoSelect(options, activeQuests, availableQuests) then
            return false
        end

        tsort(options, SortFunc_GossipPrioritizeQuest);

        local numAvailableQuests = availableQuests and #availableQuests or 0;
        local numActiveQuests = activeQuests and #activeQuests or 0;

        local anyNewOrCompleteQuest = numAvailableQuests > 0;
        if not anyNewOrCompleteQuest then
            for i, questInfo in ipairs(activeQuests) do
                if questInfo.isComplete then
                    anyNewOrCompleteQuest = true;
                    break
                end
            end
        end

        self:ReleaseAllObjects();

        local showGossipFirst = (options[1] and options[1].flags == 1) or (not anyNewOrCompleteQuest);

        local lastObject;
        local lastLeftObject;

        for i, questInfo in ipairs(availableQuests) do
            local button = self.optionButtonPool:Acquire();
            button:SetQuest(questInfo);
            if lastObject then
                button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -16);
            else
                button:SetPoint("LEFT", UIParent, "CENTER", 96, 0);
            end
            lastObject = button;

            --[[
            local button = self.optionButtonPool:Acquire();
            button:SetQuest(questInfo, true);
            if lastLeftObject then
                button:SetPoint("TOPLEFT", lastLeftObject, "BOTTOMLEFT", 0, -16);
            else
                button:SetPoint("LEFT", UIParent, "CENTER", -256, 0);
            end
            lastLeftObject = button;
            --]]
        end

        for i, questInfo in ipairs(availableQuests) do
            if QuestDataProvider:IsQueuingQuest(questInfo.questID) then
                C_GossipInfo.SelectAvailableQuest(questInfo.questID);
                return
            end
        end

        self:Show();

        return true
    end

    function Skimmer:HandleQuestDetail()
        if self.Init then
            self:Init();
        end

        local questID = GetQuestID();
        local title = GetQuestTitle();

        local questInfo = {};
        questInfo.questID = questID;
        questInfo.title = GetQuestTitle();

        self:ReleaseAllObjects();

        local button = self.optionButtonPool:Acquire();
        button:SetQuest(questInfo);
        button:SetPoint("LEFT", UIParent, "CENTER", 96, 0);

        self:Show();
    end
end

do  --QuestDataProvider
    local QuestCache = {};

    function QuestDataProvider:LoadQuest(questID)
        
    end

    function QuestDataProvider:ClearQuestCache(questID)
        
    end

    function QuestDataProvider:GetQuestData(questID)
        
    end

    function QuestDataProvider:GetQuestTitle(questID)
        
    end

    function QuestDataProvider:GetQuestObjective(questID)
        return QuestCache[questID] and QuestCache[questID].objectives or nil
    end

    function QuestDataProvider:GetQuestReward(questID)
        
    end

    function QuestDataProvider:IsQuestDetailCached(questID)
        local playerLevel = UnitLevel("player");
        return QuestCache[questID] and QuestCache[questID].playerLevel == playerLevel
    end

    function QuestDataProvider:OnQuestDetailReceived(questID)
        QuestCache[questID] = {
            playerLevel = UnitLevel("player"),
            title = GetQuestTitle(),
            objectives = GetObjectiveText(),
        };

        self.questQueue[questID] = nil;
    end

    function QuestDataProvider:RequestQuestDetail(questID)
        if not self.questQueue then
            self.questQueue = {};
        end
        self.questQueue[questID] = true;
    end

    function QuestDataProvider:IsQueuingQuest(questID)
        return self.questQueue and self.questQueue[questID]
    end
end

do  --Module Control
    function DUI_ToggleSkimmer(state)
        if state then
            EL:ListenEvents(true);
            addon.SetHandleEventExternally(true);
        else
            EL:ListenEvents(false);
            addon.SetHandleEventExternally(false);
        end
    end

    if false then
        C_Timer.After(2, function()
            DUI_ToggleSkimmer(true);
        end)
    end
end


--[[
    local totalXp, baseXp = GetQuestLogRewardXP(questID);
    GetQuestLogRewardMoney([questID])
    GetNumQuestLogRewards
    GetQuestLogRewardInfo(itemIndex [, questID]) 
    GetNumQuestLogChoices(questID [, includeCurrencies])
    GetQuestLogChoiceInfo
    C_QuestInfoSystem.GetQuestRewardCurrencies
    C_QuestInfoSystem.GetQuestRewardSpellInfo
    C_QuestInfoSystem.HasQuestRewardCurrencies
    C_QuestInfoSystem.HasQuestRewardSpells
--]]


do
    --[[
    local f = addon.TemplateAPI.CreateResizableVerticalFrame();
    f:SetPoint("CENTER", 0, 0);
    f:SetFrameSize(200, 200);
    --]]
end