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
local C_GossipInfo = C_GossipInfo;
local GetOptions = C_GossipInfo.GetOptions;
local GetActiveQuests = C_GossipInfo.GetActiveQuests;
local GetAvailableQuests = C_GossipInfo.GetAvailableQuests;


local QuestDataProvider = {};
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
                    C_GossipInfo.CloseGossip();
                end
                self.interactionIsContinuing = nil;
            elseif self.customFrame then
                if not InCombatLockdown() then
                    HideUIPanel(self.customFrame);
                end
                self.customFrame = nil;
            end
        elseif event == "QUEST_DETAIL" then

        elseif event == "" then

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
        if event == "TOOLTIP_DATA_UPDATE" then
            self:HandleTooltipDataUpdate(...);
        else

        end
    end
    Skimmer:SetScript("OnEvent", Skimmer.OnEvent);

    function Skimmer:OnHide()
        --Unused
        if self.interactionIsContinuing then
            self.interactionIsContinuing = nil;
        else
            C_GossipInfo.CloseGossip();
        end
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
        print(numAvailableQuests)
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

        for i, questInfo in ipairs(availableQuests) do
            local button = self.optionButtonPool:Acquire();
            button:SetQuest(questInfo);
            if lastObject then
                button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -16);
            else
                button:SetPoint("LEFT", UIParent, "CENTER", 96, 0);
            end
            lastObject = button;
        end
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
        
    end

    function QuestDataProvider:GetQuestReward(questID)
        
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
end