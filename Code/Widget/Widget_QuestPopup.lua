local _, addon = ...

local L = addon.L;
local API = addon.API;
local WidgetManager = addon.WidgetManager;
local ThemeUtil = addon.ThemeUtil;
local FontUtil = addon.FontUtil;
local easeFunc = addon.EasingFunctions.outQuart;
local After = C_Timer.After;
local GetQuestID = GetQuestID;
local AddAutoQuestPopUp = AddAutoQuestPopUp;
local RemoveAutoQuestPopUp = RemoveAutoQuestPopUp;
local PlayAutoAcceptQuestSound = PlayAutoAcceptQuestSound;
local ShowQuestOffer = ShowQuestOffer;
local AcceptQuest = AcceptQuest;


local QuestWidgets = {};    --[questID] = widget

local CreateQuestPopup;
do
    local E_SCALE = 0.5;

    --Use pixel size
    local FRAME_WIDTH, FRAME_HEIGHT = 536, 88;
    local BG_WIDTH, BG_HEIGHT = 576, 128;
    local TEXT_OFFSET_X = 106;
    local TITLE_MAX_WIDTH = 372;


    local QuestPopupFrameMixin = {};

    function QuestPopupFrameMixin:OnLoad()
        self:UpdateScale();

        local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestPopup.png";
        self.Background:SetTexture(file);
        self.QuestIcon:SetTexture(file);
        self.Highlight:SetTexture(file);

        --self:SetLayout("accepted");
    end

    function QuestPopupFrameMixin:UpdateScale()
        self:SetSize(FRAME_WIDTH * E_SCALE, FRAME_HEIGHT * E_SCALE);
        self.Background:SetSize(BG_WIDTH * E_SCALE, BG_HEIGHT * E_SCALE);
        self.BrushMask:SetSize(2 * BG_HEIGHT * E_SCALE, BG_HEIGHT * E_SCALE);
        self.Title:SetWidth(TITLE_MAX_WIDTH * E_SCALE);
        self.Header:ClearAllPoints();
        self.Title:ClearAllPoints();
        self.Header:SetPoint("LEFT", self, "BOTTOMLEFT", TEXT_OFFSET_X * E_SCALE, 68 * E_SCALE);
        self.Title:SetPoint("LEFT", self, "BOTTOMLEFT", TEXT_OFFSET_X * E_SCALE, (self.titleOffsetY or 28) * E_SCALE);
        self.QuestIcon:SetPoint("CENTER", self, "BOTTOMLEFT", 54 * E_SCALE, (self.iconOffsetY or 42) * E_SCALE);
        self.QuestIcon:SetSize(128 * E_SCALE, 128 * E_SCALE);
        self.maskToX = 1 + FRAME_WIDTH * E_SCALE;
    end

    local function OnUpdate_FadeIn(self, elapsed)
        self.t = self.t + elapsed;
        local x = easeFunc(self.t, 0, self.maskToX, 2.0);
        if self.t > 2.0 then
            x = self.maskToX;
            self:SetScript("OnUpdate", nil);
        end
        self.BrushMask:SetPoint("LEFT", self, "LEFT", x, 0);

        self.alpha = self.alpha + 2 * elapsed;
        if self.alpha > 1 then
            self.alpha = 1;
        end
        self:SetAlpha(self.alpha);
    end

    function QuestPopupFrameMixin:FadeIn()
        self.t = 0;
        self.alpha = 0;
        self:SetScript("OnUpdate", OnUpdate_FadeIn);
        OnUpdate_FadeIn(self, 0);
        self:Show();
    end

    local function FadeOut_OnUpdate(self, elapsed)
        self.alpha = self.alpha - 2 * elapsed;
        if self.alpha <= 0 then
            self.alpha = 0;
            self:Close();
            self:SetScript("OnUpdate", nil);
        end
        self:SetAlpha(self.alpha);
    end

    function QuestPopupFrameMixin:FadeOut()
        if self:IsVisible() then
            self.t = 0;
            self.alpha = self:GetAlpha();
            self:SetScript("OnUpdate", FadeOut_OnUpdate);
        end
    end

    function QuestPopupFrameMixin:OnMouseDown()
        --self:FadeIn();
    end

    function QuestPopupFrameMixin:OnMouseUp(button)
        local isFocused = self:IsMouseMotionFocus();

        if button == "RightButton" and self.allowRightClickClose and isFocused then
            --Accepted quest popup closes on RightClick
            self:Close(true);
            return
        end

        if isFocused then
            --We allow both Left/Right clicks to view quest offer
            if self.questID then
                ShowQuestOffer(self.questID);
                self:Close();
                return
            end
        end
    end

    function QuestPopupFrameMixin:OnEnter()
        self:PauseAutoCloseTimer(true);
        self.Highlight:Show();
    end

    function QuestPopupFrameMixin:OnLeave()
        self:PauseAutoCloseTimer(false);
        self.Highlight:Hide();
    end

    function QuestPopupFrameMixin:PauseAutoCloseTimer(state)
        if self.CloseButton then
            self.CloseButton:PauseAutoCloseTimer(state);
        end
    end

    function QuestPopupFrameMixin:OnShow()
        self.isActive = true;
        WidgetManager:ChainAdd(self);
    end

    function QuestPopupFrameMixin:OnHide()
        --QuestAlert is child of UIParent, but we don't want to trigger anything is the Frame becomes hidden due to UIParent
        self.Highlight:Hide();
        self.questChanged = true;
    end

    function QuestPopupFrameMixin:OnEvent(event, ...)
        if event == "QUEST_FINISHED" then
            local questID = GetQuestID();
            if self.isReroutedQuest and ((not questID) or questID ~= self.questID) then
               self:Close();
            end
        end
    end

    function QuestPopupFrameMixin:SetTitle(title)
        self.Title:SetText("");
        self.Title:SetMaxLines(1);
        FontUtil:SetAutoScalingText(self.Title, title);
        C_Timer.After(0.0, function()
            if self.Title:IsTruncated() then
                local scale = self.Title:GetTextScale();
                self.Title:SetMaxLines(2);
                self.Title:SetTextScale(1.1)
                self.Title:SetTextScale(scale);
            end
        end)
    end

    function QuestPopupFrameMixin:SetQuestDataByID(questID)
        if questID ~= self.questID then
            self.questChanged = true;
        end

        self.questID = questID;

        if not QuestWidgets[questID] then
            QuestWidgets[questID] = self;
        end

        local name = API.GetQuestName(questID);
        if name and name ~= "" then
            self.requestCounter = nil;
            self:SetTitle(name);
            return true
        else
            return false
        end
    end

    function QuestPopupFrameMixin:SetLayout(layout)
        if layout == self.layout then
            return
        else
            self.layout = layout;
        end

        if layout == "offer" then
            self.titleOffsetY = 32;
            self.iconOffsetY = 60;
            self.Background:SetTexCoord(0, 576/1024, 0, 128/1024);
            self.QuestIcon:SetTexCoord(576/1024, 704/1024, 0, 128/1024);
            self.Highlight:SetTexCoord(0, 576/1024, 256/1024, 384/1024);
        elseif layout == "accepted" then
            self.titleOffsetY = 28;
            self.iconOffsetY = 42;
            self.Background:SetTexCoord(0, 576/1024, 128/1024, 256/1024);
            self.QuestIcon:SetTexCoord(704/1024, 832/1024, 0, 128/1024);
            self.Highlight:SetTexCoord(0.99, 1, 0.99, 1);   --Hidden
        end

        self:UpdateScale();
    end

    function QuestPopupFrameMixin:ShowCloseButton(state, autoCloseCountdown)
        if state then
            if not self.CloseButton then
                self.CloseButton = WidgetManager:CreateAutoCloseButton(self, true);
                self.CloseButton:SetPoint("CENTER", self, "TOPRIGHT", -48*E_SCALE, -8*E_SCALE);
            end
            self.CloseButton:Show();
            if autoCloseCountdown then
                self.CloseButton:SetCountdown(autoCloseCountdown);
            else
                self.CloseButton:StopCountdown();
            end
        else
            if self.CloseButton then
                self.CloseButton:Hide();
            end
        end
    end

    function QuestPopupFrameMixin:Close(fromRightClick)
        self.isActive = false;
        self:Hide();
        WidgetManager:ChainRemove(self);
        if self.questID then
            RemoveAutoQuestPopUp(self.questID);
            API.RemoveQuestObjectiveTrackerQuestPopUp(self.questID);
            if QuestWidgets[self.questID] == self then
                QuestWidgets[self.questID] = nil;
            end

            if self.isReroutedQuest then
                self.isReroutedQuest = nil;
                if fromRightClick and GetQuestID() == self.questID then
                    addon.FlagQuestDeclined();
                    CloseQuest();
                end
            end

            self.questID = nil;
            self:UnregisterEvent("QUEST_FINISHED");
        end
    end

    function QuestPopupFrameMixin:OnCountdownFinished()
        --self:Close();
        self:FadeOut();
    end

    function QuestPopupFrameMixin:RequestQuestData(questID)
        if not self.requestCounter then
            self.requestCounter = 0;
        end
        self.requestCounter = self.requestCounter + 1;
        if self.requestCounter < 4 then
            After(0.25, function()
                if self.questID == questID then
                    self[self.method](self, questID);
                end
            end);
        else
            if self:IsShown() then
                if self.questID == questID then
                    self:Close();
                end
            end
        end
    end

    --For different Quest Types
    function QuestPopupFrameMixin:SetQuestOffer(questID, questStartItemID, isReroutedQuest)
        self.method = "SetQuestOffer";
        self.isReroutedQuest = isReroutedQuest;

        self:SetLayout("offer");
        if self:SetQuestDataByID(questID) then
            ThemeUtil:SetFontColor(self.Header, "DarkModeGrey70");
            ThemeUtil:SetFontColor(self.Title, "DarkModeGold");
            self.Header:SetText(L["New Quest Available"]);
            self.QuestIcon.AnimBounce:Play();

            local canBeClosed = isReroutedQuest or false;
            self:ShowCloseButton(canBeClosed);
            self.allowRightClickClose = canBeClosed;

            if self.questChanged then
                self.questChanged = nil;
                self:FadeIn();
            end

            if isReroutedQuest then
                self:RegisterEvent("QUEST_FINISHED");
            else
                self:UnregisterEvent("QUEST_FINISHED");
            end

            if API.IsControllerMode() then
                After(1, function()
                    if (not API.IsPlayerOnQuest(questID)) and GetQuestID() == questID then
                        AcceptQuest();
                    end
                end);
            end
        else
            self:RequestQuestData(questID);
        end
    end

    function QuestPopupFrameMixin:SetAcceptedQuest(questID, questStartItemID)
        self.method = "SetAcceptedQuest";
        self:SetLayout("accepted");
        self:UnregisterEvent("QUEST_FINISHED");
        if self:SetQuestDataByID(questID) then
            ThemeUtil:SetFontColor(self.Header, "DarkModeGrey70");
            ThemeUtil:SetFontColor(self.Title, "DarkModeGrey90");
            self.Header:SetText(L["Quest Accepted"]);
            self.QuestIcon.AnimBounce:Stop();
            self:ShowCloseButton(true, 8);
            self.allowRightClickClose = true;
            self:FadeIn();
        else
            self:RequestQuestData(questID);
        end
    end

    function CreateQuestPopup()
        local f = CreateFrame("Frame", nil, UIParent, "DUIQuestPopupTemplate");    --Inherits the game's UI Scale from UIParent
        f:SetIgnoreParentAlpha(true);
        f:Hide();
        API.Mixin(f, QuestPopupFrameMixin);
        f:OnLoad();
        f:SetScript("OnMouseDown", f.OnMouseDown);
        f:SetScript("OnMouseUp", f.OnMouseUp);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnShow", f.OnShow);
        f:SetScript("OnHide", f.OnHide);
        f:SetScript("OnEvent", f.OnEvent);
        f.widgetName = L["Auto Quest Popup"];
        return f
    end
end

do  --Create Popup
    --Regarding Blizzard Objective Tracker:
    --See ObjectiveTrackerModuleMixin:Update, LayoutContents, AutoQuestPopupTrackerMixin:AddAutoQuestObjectives
    --Due to methods mentioned above, "OFFER" type of QuestPopups will still appear dispite muting QUEST_DETAIL on QuestFrame.
    --This doesn't negatively affect us in any way. But It could be a disorienting since our popups are on the left and the ObjectiveTracker is on the right.

    local FramePool = {};

    function WidgetManager:AcquireQuestPopup()
        local f;
        for widget in pairs(FramePool) do
            if not widget.isActive then
                f = widget;
                break
            end
        end

        if not f then
            f = CreateQuestPopup();
            FramePool[f] = true;
        end

        f.isActive = true;

        return f
    end

    ---Add reroute the current Quest Detail to a popup, left click to view in DUI
    ---@param questStartItemID number? payload from QUEST_DETAIL
    ---@param isReroutedQuest boolean? Some quest are repeatedly pushed to the player unless they accept it (Uniting the Isles).
    ---In such case, we add the quest to our popup but don't use Blizzard's popup API, otherwise the player will see another one in Objective Tracker
    function WidgetManager:AddAutoQuestPopUp(questStartItemID, isReroutedQuest)
        --This method is called in Core.lua
        local questID = GetQuestID();
        if questID and questID ~= 0 then
            local popUpType = "OFFER";
            if isReroutedQuest or AddAutoQuestPopUp(questID, popUpType) then
                local f = QuestWidgets[questID];
                if not f then
                    f = self:AcquireQuestPopup();
                end

                if API.IsPlayerOnQuest(questID) then
                    f:SetAcceptedQuest(questID, questStartItemID);
                    self:UnregisterEvent("QUEST_ACCEPTED");
                else
                    f:SetQuestOffer(questID, questStartItemID, isReroutedQuest);
                    self:RegisterEvent("QUEST_ACCEPTED");   --TO-DO: Unregister if player turns down the offer
                end

                if PlayAutoAcceptQuestSound then
                    PlayAutoAcceptQuestSound();
                end
            else

            end
        end
    end

    function WidgetManager:RemoveQuestPopUpByID(questID)
        --Triggered by DialogueUI:HandleQuestDetail()
        if QuestWidgets[questID] then
            QuestWidgets[questID]:Close();
        end
    end

    function WidgetManager:RemoveAllQuestPopUps()
        for widget in pairs(FramePool) do
            widget:Close();
        end
    end

    function WidgetManager:QUEST_ACCEPTED(questID)
        if questID and QuestWidgets[questID] then
            self:UnregisterEvent("QUEST_ACCEPTED");
            QuestWidgets[questID]:SetAcceptedQuest(questID);
        end
    end


    local function Settings_AutoQuestPopup(dbValue)
        if dbValue == false then
            WidgetManager:RemoveAllQuestPopUps()
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.AutoQuestPopup", Settings_AutoQuestPopup);
end


--[[
C_Timer.After(3, function()
    local f = WidgetManager:AcquireQuestPopup();
    f:SetAcceptedQuest(72291);
    local b = WidgetManager:AcquireQuestPopup();
    b:SetQuestOffer(83719); --72291 72481
end);
--]]
