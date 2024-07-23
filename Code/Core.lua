local _, addon = ...
local API = addon.API;
local MainFrame = addon.DialogueUI;
local IsInteractingWithDialogNPC = API.IsInteractingWithDialogNPC;
local CancelClosingGossipInteraction = API.CancelClosingGossipInteraction;
local QuestIsFromAreaTrigger = API.QuestIsFromAreaTrigger;
local GossipDataProvider = addon.GossipDataProvider;
local QuestGetAutoAccept = API.QuestGetAutoAccept;
local CloseQuest = CloseQuest;


local EVENT_PROCESS_DELAY = 0.017;  --Affected by CameraMovement

local EL = CreateFrame("Frame");

local GossipEvents = {
    "GOSSIP_SHOW", "GOSSIP_CLOSED",
    "CONFIRM_TALENT_WIPE",  --Classic
};

local QuestEvents = {
    "QUEST_PROGRESS",
    "QUEST_DETAIL",
    "QUEST_FINISHED",   --Close QuestFrame
    "QUEST_GREETING",   --Offer several quests
    "QUEST_COMPLETE",   --Talk to turn in quest
};

local CloseDialogEvents = {};

if not addon.IsToCVersionEqualOrNewerThan(50000) then
    local ClassicEvents = {
        "CONFIRM_TALENT_WIPE", "CONFIRM_TALENT_WIPE",
    };

    for _, event in ipairs(ClassicEvents) do
        table.insert(GossipEvents, event);
        CloseDialogEvents[event] = true;
    end
end


function EL:OnManualEvent(event, ...)
    self:SetScript("OnUpdate", nil);

    if event == "QUEST_FINISHED" then
        if not IsInteractingWithDialogNPC() then
            MainFrame:HideUI();
        end
    elseif event == "GOSSIP_SHOW" then
        MainFrame:ShowUI(event);
    elseif event == "GOSSIP_CLOSED" then
        self:OnGossipClosed(...);
    end
end

function EL:OnGossipClosed(interactionIsContinuing)
    if self.customFrame then
        local f = self.customFrame;
        self.customFrame = nil;
        HideUIPanel(f);
        return
    end

    if not IsInteractingWithDialogNPC() then
        if not MainFrame:IsGossipCloseConsumed() then
            --MainFrame:SetInteractionIsContinuing(interactionIsContinuing);
            MainFrame:HideUI();
        end
        GossipDataProvider:OnInteractStopped();
    end
end

function EL:NegateLastEvent(event)
    if event == self.lastEvent then
        self.lastEvent = nil;
    end
end

function EL:OnEvent(event, ...)
    self.lastEvent = event;

    if event == "GOSSIP_SHOW" then
        local handler = self:GetHandler(...);
        if handler then
            self.customFrame = handler(...);
        else
            if self:ThrottleGossipEvent() then
                MainFrame:ShowUI(event);    --Depends on the options, we may select the non-gossip one directly without openning the UI
                GossipDataProvider:OnInteractWithNPC();
                CancelClosingGossipInteraction();
            end
        end

        self:NegateLastEvent(event);

    elseif event == "GOSSIP_CLOSED" then
        self:ProcessEventNextUpdate(0.1);
        --self:OnGossipClosed(...);

    elseif event == "QUEST_FINISHED" then
        --When the quest giver has more than one quest
        --sometimes there is a delay between QUEST_FINISHED and GOSSIP_SHOW (presumably depends on various of factors including latency)
        --the game determinates interaction then re-engage, messing up ActionCam and gossip info
        --our workaround is setting s delay to this event

        self:ProcessEventNextUpdate(MainFrame:GetQuestFinishedDelay());

    elseif event == "QUEST_DETAIL" then
        if ( QuestGetAutoAccept() and QuestIsFromAreaTrigger() ) then
            CloseQuest();
        else
            MainFrame:ShowUI(event);
        end

    elseif event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_GREETING" then
        MainFrame:ShowUI(event);

    elseif CloseDialogEvents[event] then
        MainFrame:HideUI();
    end

    --print(event, GetTimePreciseSec());
end


function EL:ListenEvent(state)
    local method;

    if state then
        method = "RegisterEvent";
        self:SetScript("OnEvent", self.OnEvent);
    else
        method= "UnregisterEvent";
        self:SetScript("OnEvent", nil);
    end

    for _, event in ipairs(GossipEvents) do
        self[method](self, event);
    end

    for _, event in ipairs(QuestEvents) do
        self[method](self, event);
    end
end

function EL:OnUpdate(elapsed)
    if self.processEvent then
        self.t = self.t + elapsed;
        if self.t > EVENT_PROCESS_DELAY then
            self.t = 0;
            self.processEvent = nil;
            if self.lastEvent then
                --print("LAST EVENT", self.lastEvent)
                self:OnManualEvent(self.lastEvent);
                self.lastEvent = nil;
            end
        end
    end

    if self.pauseGossip then
        self.pauseGossip = self.pauseGossip + elapsed;
        if self.pauseGossip >= 0 then
            self.pauseGossip = nil;
        end
    end

    if not (self.processEvent or self.pauseGossip) then
        self:SetScript("OnUpdate", nil);
    end
end

function EL:ThrottleGossipEvent()
    if not self.pauseGossip then
        self.pauseGossip = 0.016;
        self:SetScript("OnUpdate", self.OnUpdate);
        return true
    end

    return false
end

function EL:ProcessEventNextUpdate(customDelay)
    customDelay = customDelay or 0;
    self.t = -customDelay;
    self.processEvent = true;
    self:SetScript("OnUpdate", self.OnUpdate);
end


EL:ListenEvent(true);

do
    local DEFAULT_CAMERA_MODE = 1;
    local MAINTAIN_CAMERA_POSITION = false;

    local function OnCameraModeChanged(_, mode)
        if mode == 0 then   --0: No Zoom
            EVENT_PROCESS_DELAY = 0.017;
        elseif mode == 1 then   --1: Zoom to NPC
            if MAINTAIN_CAMERA_POSITION then
                EVENT_PROCESS_DELAY = 0.5;
            else
                EVENT_PROCESS_DELAY = 0.017;
            end
        elseif mode == 2 then   --2: Shift camear horizontally
            EVENT_PROCESS_DELAY = 0.5;
        end
        DEFAULT_CAMERA_MODE = mode;
    end

    addon.CallbackRegistry:Register("Camera.ModeChanged", OnCameraModeChanged, EL);

    local function Settings_CameraMovement1MaintainPosition(dbValue)
        MAINTAIN_CAMERA_POSITION = dbValue == true;
        if DEFAULT_CAMERA_MODE then
            OnCameraModeChanged(nil, DEFAULT_CAMERA_MODE);
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.CameraMovement1MaintainPosition", Settings_CameraMovement1MaintainPosition);
end

do  --Unlisten events from default UI
    --CustomGossipFrameManager:
    --We need to mute this so HideUI doesn't trigger CloseGossip
    --It handle NPE (Be A Guide) and Torghast Floor Selection
    if CustomGossipFrameManager then    --CustomGossipFrameBase.lua (Retail)
        CustomGossipFrameManager:UnregisterEvent("GOSSIP_SHOW");
        CustomGossipFrameManager:UnregisterEvent("GOSSIP_CLOSED");
    end

    if GossipFrame then --Classic
        GossipFrame:UnregisterEvent("GOSSIP_SHOW");
	    GossipFrame:UnregisterEvent("GOSSIP_CLOSED");
	    GossipFrame:UnregisterEvent("QUEST_LOG_UPDATE");
    end

    local hideQuestFrame = true --not addon.IsToCVersionEqualOrNewerThan(110000);  --TWW
    if hideQuestFrame then
        QuestFrame:UnregisterAllEvents();
    else
        QuestFrame:SetParent(nil);
        QuestFrame:SetScale(2/3);
    end
end

do
	local function HandleNPEGuideGossipShow(textureKit)
		C_AddOns.LoadAddOn("Blizzard_NewPlayerExperienceGuide");
		ShowUIPanel(GuideFrame);
		return GuideFrame
	end

	local function HandleTorghastLevelPickerGossipShow(textureKit)
		C_AddOns.LoadAddOn("Blizzard_TorghastLevelPicker");
		TorghastLevelPickerFrame:TryShow(textureKit)
		return TorghastLevelPickerFrame
	end

    local function HandleDelvesDifficultyPickerGossipShow(textureKit)   --TWW
		C_AddOns.LoadAddOn("Blizzard_DelvesDifficultyPicker");
		DelvesDifficultyPickerFrame:TryShow(textureKit);
		return DelvesDifficultyPickerFrame
	end

    EL.handlers = {};

    function EL:RegisterHandler(textureKit, func)
        self.handlers[textureKit] = func;
    end

    function EL:GetHandler(textureKit)
        --print("textureKit", textureKit)
        return textureKit and self.handlers[textureKit]
    end

	function EL:RegisterCustomGossipFrames()
		self:RegisterHandler("npe-guide", HandleNPEGuideGossipShow);
		self:RegisterHandler("skoldushall", HandleTorghastLevelPickerGossipShow);
		self:RegisterHandler("mortregar", HandleTorghastLevelPickerGossipShow);
		self:RegisterHandler("coldheartinterstitia", HandleTorghastLevelPickerGossipShow);
		self:RegisterHandler("fracturechambers", HandleTorghastLevelPickerGossipShow);
		self:RegisterHandler("soulforges", HandleTorghastLevelPickerGossipShow);
		self:RegisterHandler("theupperreaches", HandleTorghastLevelPickerGossipShow);
		self:RegisterHandler("twistingcorridors", HandleTorghastLevelPickerGossipShow);
        self:RegisterHandler("delves-difficulty-picker", HandleDelvesDifficultyPickerGossipShow);   --For some reason this textureKit is sometimes nil, causing issue
	end
    EL:RegisterCustomGossipFrames();
end