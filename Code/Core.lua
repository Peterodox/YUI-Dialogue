local _, addon = ...
local API = addon.API;
local MainFrame = addon.DialogueUI;
local IsInteractingWithDialogNPC = API.IsInteractingWithDialogNPC;
local CancelClosingGossipInteraction = API.CancelClosingGossipInteraction;
local QuestIsFromAreaTrigger = API.QuestIsFromAreaTrigger;
local GossipDataProvider = addon.GossipDataProvider;
local QuestGetAutoAccept = API.QuestGetAutoAccept;
local ShouldMuteQuestDetail = API.ShouldMuteQuestDetail;
local CloseQuest = CloseQuest;
local InCombatLockdown = InCombatLockdown;
local IsInInstance = IsInInstance;


local EVENT_PROCESS_DELAY = 0.017;          --Affected by CameraMovement
local MAINTAIN_CAMERA_POSITION = false;
local USE_AUTO_QUEST_POPUP = true;
local DISABLE_DUI_IN_INSTANCE = false;
local HANDLE_EVENT_EXTERNALLY = false;      --If true, Events will be handled by Skimmers


local EL = CreateFrame("Frame");
local Muter = {};

local function GetCustomGossipHandler()
end

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

local MapEvents = {
    PLAYER_ENTERING_WORLD = true,
    ZONE_CHANGED_NEW_AREA = true,
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

local ShouldMuteQuest;
if addon.IsToCVersionEqualOrNewerThan(110005) then
    local GetQuestID = GetQuestID;
    function ShouldMuteQuest()
        local questID = GetQuestID();
        return ShouldMuteQuestDetail(questID)
    end
else
    function ShouldMuteQuest()
        return false
    end
end

function EL:OnManualEvent(event, ...)
    self:SetScript("OnUpdate", nil);

    if event == "QUEST_FINISHED" or event == "QUEST_FINISHED_FORCED" then
        --For the issue where the quest window fails to close:
        --Sometimes QUEST_FINISHED fires but IsInteractingWithNpcOfType still thinks we are interacting with QuestGiver
        --/dump C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.QuestGiver)
        --print(event, "IS INTERACTING", IsInteractingWithDialogNPC(), GetTimePreciseSec())   --debug
        if (event == "QUEST_FINISHED_FORCED") or (not IsInteractingWithDialogNPC()) then
            self.timeSinceQuestFinish = nil;
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
        if not InCombatLockdown() then
            HideUIPanel(f);
        end
        return
    end

    if not IsInteractingWithDialogNPC() then
        if not MainFrame:IsGossipCloseConsumed() then
            --MainFrame:SetInteractionIsContinuing(interactionIsContinuing);
            self.timeSinceQuestFinish = nil;
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
    if HANDLE_EVENT_EXTERNALLY then
        return
    end

    if event == "GOSSIP_SHOW" then
        self.lastEvent = event;
        local handler = GetCustomGossipHandler(...);
        if handler then
            self.customFrame = handler(...);
        else
            if self:ThrottleGossipEvent() then
                GossipDataProvider:OnInteractWithNPC();
                MainFrame:ShowUI(event);    --Depends on the options, we may select the non-gossip one directly without openning the UI
                CancelClosingGossipInteraction();
            end
        end

        self:NegateLastEvent(event);

    elseif event == "GOSSIP_CLOSED" then
        self.lastEvent = event;
        self:ProcessEventNextUpdate(0.1);
        --self:OnGossipClosed(...);

    elseif event == "QUEST_FINISHED" then
        --When the quest giver has more than one quest
        --sometimes there is a delay between QUEST_FINISHED and GOSSIP_SHOW (presumably depends on various of factors including latency)
        --the game determinates interaction then re-engage, messing up ActionCam and gossip info
        --our workaround is setting s delay to this event
        --print(event, GetTimePreciseSec(), IsInteractingWithDialogNPC());

        local delay = MainFrame:GetQuestFinishedDelay();

        self.timeSinceQuestFinish = -delay;

        if self.lastEvent ~= "QUEST_FINISHED_FORCED" then
            self.lastEvent = event;
            self:ProcessEventNextUpdate(delay);
        end

    elseif event == "QUEST_DETAIL" then
        --Can fire multiple times in rare occasions, possibly due to cross-character progress

        if ShouldMuteQuest() then
            if API.IsQuestAutoAccepted() then
                API.AcknowledgeAutoAcceptQuest();
            end
            CloseQuest();
            return
        end

        self.lastEvent = event;

        local questStartItemID = ...

        if USE_AUTO_QUEST_POPUP and questStartItemID and questStartItemID ~= 0 then
			addon.WidgetManager:AddAutoQuestPopUp(questStartItemID);
            CloseQuest();
            return
		end

        if USE_AUTO_QUEST_POPUP and QuestIsFromAreaTrigger() and (QuestGetAutoAccept() or InCombatLockdown()) then
            --"QuestIsFromAreaTrigger" and "QuestGetAutoAccept" Doesn't work in Classic
            --Some quests that triggered upon login aren't "QuestIsFromAreaTrigger"
            addon.WidgetManager:AddAutoQuestPopUp();
            CloseQuest();
        else
            MainFrame:ShowUI(event, questStartItemID);
        end

    elseif event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_GREETING" then
        --Sometimes QUEST_FINISHED fires before QUEST_COMPLETE
        self.lastEvent = event;
        MainFrame:ShowUI(event);

    elseif CloseDialogEvents[event] then
        self.lastEvent = event;
        self.timeSinceQuestFinish = nil;
        MainFrame:HideUI();

    elseif MapEvents[event] then
        if DISABLE_DUI_IN_INSTANCE then
            Muter:UpdateForInstance();
        end
    end

    --print(event, GetTimePreciseSec(), ...);    --debug
end

function EL:ListenEvents(state)
    local method;

    if state then
        method = "RegisterEvent";
        self:SetScript("OnEvent", self.OnEvent);
    else
        method= "UnregisterEvent";
        if DISABLE_DUI_IN_INSTANCE then
            self:SetScript("OnEvent", self.OnEvent);
        else
            self:SetScript("OnEvent", nil);
        end
    end

    for _, event in ipairs(GossipEvents) do
        self[method](self, event);
    end

    for _, event in ipairs(QuestEvents) do
        self[method](self, event);
    end

    --self[method](self, "PLAYER_INTERACTION_MANAGER_FRAME_SHOW");    --debug
    --self[method](self, "PLAYER_INTERACTION_MANAGER_FRAME_HIDE");
end

function EL:OnUpdate(elapsed)
    if self.timeSinceQuestFinish then
        self.timeSinceQuestFinish = self.timeSinceQuestFinish + elapsed;
        if self.timeSinceQuestFinish > EVENT_PROCESS_DELAY then
            self.timeSinceQuestFinish = nil;
            if self.lastEvent == "QUEST_FINISHED" or self.lastEvent == "QUEST_FINISHED_FORCED" then
                if not IsInteractingWithDialogNPC() then
                    --print("COUNTER STOP", UnitExists("npc"))
                    self.processEvent = nil;
                    self.lastEvent = nil;
                    MainFrame:HideUI();
                end
            end
        end
    end

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

do
    local DEFAULT_CAMERA_MODE = 1;

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

    local function ManualTriggerQuestFinished(isAutoComplete)
        --print("TRIGGER FINISH", GetTimePreciseSec())      --debug
        if EL.lastEvent ~= "QUEST_FINISHED_FORCED" then
            EL.lastEvent = "QUEST_FINISHED_FORCED";
            EL:ProcessEventNextUpdate(1.5);                 --Force trigger QUEST_FINISHED event to close the UI. We use extended delay (1s) due to unavailable server latency
        end
    end
    addon.CallbackRegistry:Register("TriggerQuestFinished", ManualTriggerQuestFinished);

    local function Settings_AutoQuestPopup(dbValue)
        USE_AUTO_QUEST_POPUP = dbValue ~= false;
    end
    addon.CallbackRegistry:Register("SettingChanged.AutoQuestPopup", Settings_AutoQuestPopup);
end

do  --Unlisten events from default UI
    --CustomGossipFrameManager:
    --We need to mute this so HideUI doesn't trigger CloseGossip
    --It handle NPE (Be A Guide) and Torghast Floor Selection


    Muter.questEvents = {
        QUEST_GREETING = true,
        QUEST_DETAIL = true,
        QUEST_PROGRESS = true,
        QUEST_COMPLETE = true,
        QUEST_FINISHED = true,
        QUEST_ITEM_UPDATE = true,
        QUEST_LOG_UPDATE = true,
        UNIT_PORTRAIT_UPDATE = true,
        PORTRAITS_UPDATED = true,
    };

    if addon.IsToCVersionEqualOrNewerThan(50000) then
        Muter.questEvents.LEARNED_SPELL_IN_SKILL_LINE = true;
    else
        Muter.questEvents.LEARNED_SPELL_IN_TAB = true;            --Classic
    end

    local function SetUseDialogueUI(state)
        if state == nil then state = true end;

        if state then
            if Muter.muted then return end;
            Muter.muted = true;
            EL:ListenEvents(true);

            if CustomGossipFrameManager then    --CustomGossipFrameBase.lua (Retail)
                CustomGossipFrameManager:UnregisterEvent("GOSSIP_SHOW");
                CustomGossipFrameManager:UnregisterEvent("GOSSIP_CLOSED");
            end

            if GossipFrame then --Classic
                GossipFrame:UnregisterEvent("GOSSIP_SHOW");
                GossipFrame:UnregisterEvent("GOSSIP_CLOSED");
                GossipFrame:UnregisterEvent("QUEST_LOG_UPDATE");
            end

            local hideQuestFrame = true;    --false when we do debug
            if hideQuestFrame then
                QuestFrame:UnregisterAllEvents();
            else
                QuestFrame:SetParent(nil);
                QuestFrame:SetScale(2/3);
            end

        elseif Muter.muted then
            Muter.muted = false;
            EL:ListenEvents(false);

            if CustomGossipFrameManager then    --CustomGossipFrameBase.lua (Retail)
                CustomGossipFrameManager:RegisterEvent("GOSSIP_SHOW");
                CustomGossipFrameManager:RegisterEvent("GOSSIP_CLOSED");
            end

            if GossipFrame then --Classic
                GossipFrame:RegisterEvent("GOSSIP_SHOW");
                GossipFrame:RegisterEvent("GOSSIP_CLOSED");
                GossipFrame:RegisterEvent("QUEST_LOG_UPDATE");
            end

            local hideQuestFrame = true;    --false when we do debug
            if hideQuestFrame then
                local qf = QuestFrame;
                for event, valid in pairs(Muter.questEvents) do
                    if valid then
                        qf:RegisterEvent(event);
                    end
                end
            else
                QuestFrame:SetParent(UIParent);
                QuestFrame:SetScale(1);
            end
        end

        addon.EnableBookUI(state);
    end
    addon.SetUseDialogueUI = SetUseDialogueUI;

    SetUseDialogueUI(true);

    function Muter:UpdateForInstance()
        if IsInInstance() then
            SetUseDialogueUI(false);
        else
            SetUseDialogueUI(true);
        end
    end

    local function Settings_DisableDUIInInstance(dbValue, userInput)
        DISABLE_DUI_IN_INSTANCE = dbValue == true;
        if DISABLE_DUI_IN_INSTANCE then
            for event in pairs(MapEvents) do
                EL:RegisterEvent(event);
            end
            Muter:UpdateForInstance();
            if userInput and IsInInstance() and MainFrame:IsShown() then
                MainFrame:Hide();
            end
        else
            for event in pairs(MapEvents) do
                EL:UnregisterEvent(event);
            end
            SetUseDialogueUI(true);
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.DisableDUIInInstance", Settings_DisableDUIInInstance);
end

do  --See Blizzard_UIPanels_Game/CustomGossipFrameBase.lua
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

    local Handlers = {};

    function EL:RegisterHandler(textureKit, func)
        Handlers[textureKit] = func;
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

    function GetCustomGossipHandler(textureKit)
        return textureKit and Handlers[textureKit]
    end
    addon.GetCustomGossipHandler = GetCustomGossipHandler;
end

do  --DEBUG Skimmer
    local function SetHandleEventExternally(state)
        HANDLE_EVENT_EXTERNALLY = state == true;
    end
    addon.SetHandleEventExternally = SetHandleEventExternally;
end