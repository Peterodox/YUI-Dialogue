local _, addon = ...
local API = addon.API;
local L = addon.L;
local GetDBValue = addon.GetDBValue;
local TooltipFrame = addon.SharedTooltip;


local DBKEY_POSITION = "WidgetManagerPosition";

local Round = API.Round;
local CreateFrame = CreateFrame;
local GetCursorPosition = GetCursorPosition;
local UIParent = UIParent;

local MainAnchor = CreateFrame("Frame");    --Used as the anchor for docking/chaining pop-ups
MainAnchor:SetSize(268, 44);
MainAnchor:SetClampedToScreen(true);
MainAnchor:SetPoint("CENTER", UIParent, "LEFT", 24, 32);
MainAnchor:Hide();

local WidgetManager = CreateFrame("Frame");
addon.WidgetManager = WidgetManager;


local DragFrame = CreateFrame("Frame");
do  --Emulate Drag gesture
    function DragFrame:StopWatching()
        self:SetParent(nil);
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        self.x, self.y = nil, nil;
        self.x0, self.y0 = nil, nil;
        self.ownerX, self.ownerY = nil, nil;
        self.delta = nil;
        self:UnregisterEvent("GLOBAL_MOUSE_UP");

        if self.owner then
            if self.owner.isMoving then
                --This method may get called during PreDrag, when the owner isn't moving
                if WidgetManager.isEditMode and MainAnchor:IsMouseOver() and (self.owner.dbkeyPosition ~= DBKEY_POSITION) then
                    if self.owner.ResetPosition then
                        self.owner:ResetPosition();
                    end

                else
                    if self.owner.SavePosition then
                        self.owner:SavePosition();
                    end
                end

                if self.owner.OnDragStop then
                    self.owner:OnDragStop();
                end
            end
            self.owner.isMoving = nil;
            self.owner = nil;
        end
    end

    function DragFrame:StartWatching(owner)
        --Start watching Drag gesture when MouseDown on owner
        self:SetParent(owner);
        self.owner = owner;

        if not owner:IsVisible() then
            self:StopWatching();
            return
        end

        self.x0, self.y0 = GetCursorPosition();
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_PreDrag);
        self:RegisterEvent("GLOBAL_MOUSE_UP");
    end

    function DragFrame:SetOwnerPosition()
        self.x , self.y = GetCursorPosition();
        self.x = (self.x - self.x0) / self.scale;
        self.y = (self.y - self.y0) / self.scale;
        self.owner:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.x + self.ownerX, self.y + self.ownerY);
    end

    function DragFrame:OnUpdate_PreDrag(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.016 then
            self.t = 0;
            self.x , self.y = GetCursorPosition();
            self.delta = (self.x - self.x0)*(self.x - self.x0) + (self.y - self.y0)*(self.y - self.y0);
            if self.delta >= 16 then     --Threshold
                --Actual Dragging start
                self.owner.isMoving = true;
                self.scale = self.owner:GetEffectiveScale();
                self.x0, self.y0 = GetCursorPosition();
                self.ownerX = self.owner:GetLeft();
                self.ownerY = self.owner:GetBottom();
                self.owner:ClearAllPoints();
                if self.owner.OnDragStart then
                    self.owner:OnDragStart();
                end
                self:SetOwnerPosition();
                self:SetScript("OnUpdate", self.OnUpdate_OnDrag);
            end
        end
    end

    function DragFrame:OnUpdate_OnDrag(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.008 then
            self.t = 0;
            self:SetOwnerPosition();
        end
    end

    DragFrame:SetScript("OnHide", function()
        DragFrame:StopWatching()
    end);

    DragFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "GLOBAL_MOUSE_UP" then
            DragFrame:StopWatching();
        end
    end);
end

do  --Draggable Widget
    local WidgetBaseMixin = {};

    function WidgetBaseMixin:SavePosition()
        if not self.dbkeyPosition then return end;

        local x = self:GetLeft();
        local _, y = self:GetCenter();

        if not x and y then return end;

        local position = {
            Round(x),
            Round(y);
        };

        addon.SetDBValue(self.dbkeyPosition, position);
        addon.SettingsUI:RequestUpdate();
    end

    function WidgetBaseMixin:ResetPosition(fromSettingsUI)
        if not self.dbkeyPosition then return end;

        if self:IsUsingCustomPosition() then
            addon.SetDBValue(self.dbkeyPosition, nil);
        end
        self:LoadPosition();
        addon.SettingsUI:RequestUpdate();

        if fromSettingsUI then
            WidgetManager:TogglePopupAnchor(true)
        end
    end

    function WidgetBaseMixin:IsUsingCustomPosition()
        if not self.dbkeyPosition then return end;
        return GetDBValue(self.dbkeyPosition) ~= nil
    end

    function WidgetBaseMixin:LoadPosition()
        if not self.dbkeyPosition then return end;
        local position = GetDBValue(self.dbkeyPosition);
        self:ClearAllPoints();
        if position then
            self:SetPoint("LEFT", UIParent, "BOTTOMLEFT", position[1], position[2]);
        else
            if self.isChainable and self:IsVisible() then
                WidgetManager:ChainAdd(self);
            else
                local viewportWidth = API.GetBestViewportSize();
                self:SetPoint("LEFT", nil, "CENTER", Round(-0.5*viewportWidth + 24), 32);
            end
        end
    end

    local function WidgetBaseMixin_OnMouseDown(self, button)
        if button == "LeftButton" then
            DragFrame:StartWatching(self);
        end

        if self.OnMouseDown then
            self:OnMouseDown(button);
        end
    end

    local function WidgetBaseMixin_OnMouseUp(self, button)
        if self.OnMouseUp then
            self:OnMouseUp(button);
        end
    end

    function WidgetManager:CreateWidget(dbkeyPosition, widgetName)
        local f = CreateFrame("Frame");
        f:SetClampedToScreen(true);
        f:SetMovable(true);
        API.Mixin(f, WidgetBaseMixin);
        f.dbkeyPosition = dbkeyPosition;
        f.widgetName = widgetName;
        f:SetScript("OnMouseDown", WidgetBaseMixin_OnMouseDown);
        f:SetScript("OnMouseUp", WidgetBaseMixin_OnMouseUp);
        return f
    end
end

do  --Auto Close Button
    local PI = math.pi;

    local function Countdown_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        self.progress = self.t / self.duration;

        if self.progress >= 1 then
            self.progress = nil;
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            self.Swipe1:Hide();
            self.isCountingDown = nil;
            if self.owner.OnCountdownFinished then
                self.owner:OnCountdownFinished();
            end
        elseif self.progress >= 0.5 then
            self.SwipeMask1:SetRotation((self.progress/0.5 - 1) * PI);
            self.Swipe2:Hide();
        else
            self.SwipeMask2:SetRotation((self.progress/0.5 - 1) * PI);
        end
    end

    local AutoCloseButtonMixin = {};

    function AutoCloseButtonMixin:SetCountdown(second)
        if second and second > 0 then
            self.duration = second;
            self.t = 0;
            self.Swipe1:Show();
            self.Swipe2:Show();
            self.SwipeMask1:SetRotation(0);
            self.SwipeMask2:SetRotation(-PI);
        else
            self.duration = 1;
            self.t = 1;
            self.Swipe1:Hide();
            self.Swipe2:Hide();
        end
        self.isCountingDown = true;
        self:SetScript("OnUpdate", Countdown_OnUpdate);
    end

    function AutoCloseButtonMixin:StopCountdown()
        if self.isCountingDown then
            self:SetScript("OnUpdate", nil);
            self.t = nil;
            self.progress = nil;
            self.isCountingDown = nil;
            self.Swipe1:Hide();
            self.Swipe2:Hide();
        end
    end

    function AutoCloseButtonMixin:PauseAutoCloseTimer(state)
        if self.isCountingDown then
            if state then
                self:SetScript("OnUpdate", nil);
            else
                self:SetScript("OnUpdate", Countdown_OnUpdate);
            end
        end
    end

    function AutoCloseButtonMixin:SetTheme(themeID)
        self.themeID = themeID;
        if themeID == 1 then
            self.CloseButtonTexture:SetTexCoord(0, 0.25, 0, 0.25);
            self.Swipe1:SetTexCoord(0.125, 0.25, 0.25, 0.5)
            self.Swipe2:SetTexCoord(0, 0.125, 0.25, 0.5);
        elseif themeID == 3 then
            self.CloseButtonTexture:SetTexCoord(0.75, 1, 0, 0.25);
            self.Swipe1:SetTexCoord(0.875, 1, 0.25, 0.5)
            self.Swipe2:SetTexCoord(0.75, 0.875, 0.25, 0.5);
        else
            self.CloseButtonTexture:SetTexCoord(0.25, 0.5, 0, 0.25);
            self.Swipe1:SetTexCoord(0.375, 0.5, 0.25, 0.5)
            self.Swipe2:SetTexCoord(0.25, 0.375, 0.25, 0.5);
        end
    end

    function AutoCloseButtonMixin:OnEnter()
        self:PauseAutoCloseTimer(true);
        if self.owner.OnEnter then
            self.owner:OnEnter()
        end
    end

    function AutoCloseButtonMixin:OnLeave()
        self:PauseAutoCloseTimer(false);
        if self.owner.OnLeave then
            self.owner:OnLeave()
        end
    end

    function AutoCloseButtonMixin:OnClick()
        if self.owner.Close then
            self.owner:Close(true);
        end
    end

    function AutoCloseButtonMixin:SetInteractable(state)
        if state then
            self:SetTheme(self.themeID);
            self:EnableMouse(true);
            self:EnableMouseMotion(true);
        else
            self.CloseButtonTexture:SetTexCoord(0, 0.25, 0.5, 0.75);
            self.Swipe1:SetTexCoord(0.375, 0.5, 0.5, 0.75)
            self.Swipe2:SetTexCoord(0.25, 0.375, 0.5, 0.75);
            self:EnableMouse(false);
            self:EnableMouseMotion(false);
        end
    end

    function WidgetManager:CreateAutoCloseButton(parent)
        local f = CreateFrame("Button", nil, parent);
        API.Mixin(f, AutoCloseButtonMixin);
        f.owner = parent;

        local CLOSE_BUTTON_SIZE = 34;
        f:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);

        local bt = f:CreateTexture(nil, "OVERLAY");
        f.CloseButtonTexture = bt;

        bt:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);
        bt:SetPoint("CENTER", f, "CENTER", 0, 0);

        local function CreateSwipe(isRight)
            local sw = f:CreateTexture(nil, "OVERLAY", nil, 1);
            sw:SetSize(CLOSE_BUTTON_SIZE/2, CLOSE_BUTTON_SIZE);
            if isRight then
                sw:SetPoint("LEFT", bt, "CENTER", 0, 0);
                sw:SetTexCoord(0.375, 0.5, 0.25, 0.5);
            else
                sw:SetPoint("RIGHT", bt, "CENTER", 0, 0);
                sw:SetTexCoord(0.25, 0.375, 0.25, 0.5);
            end
            local mask = f:CreateMaskTexture(nil, "OVERLAY", nil, 1);
            sw:AddMaskTexture(mask);
            mask:SetTexture("Interface/AddOns/DialogueUI/Art/BasicShapes/Mask-RightWhite", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
            mask:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);
            mask:SetPoint("CENTER", bt, "CENTER", 0, 0);
            sw:Hide();
            return sw, mask
        end

        f.Swipe1, f.SwipeMask1 = CreateSwipe(true);
        f.Swipe2, f.SwipeMask2 = CreateSwipe();
        f.SwipeMask2:SetRotation(-PI);

        local highlight = f:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);
        highlight:SetPoint("CENTER", f, "CENTER", 0, 0);

        local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/WidgetCloseButton.png";
        bt:SetTexture(file);
        highlight:SetTexture(file);
        highlight:SetTexCoord(0.5, 0.75, 0, 0.25);
        highlight:SetBlendMode("ADD");
        highlight:SetVertexColor(0.5, 0.5, 0.5);

        f.Swipe1:SetTexture(file);
        f.Swipe2:SetTexture(file);

        f:SetTheme(2);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);
        f:RegisterForClicks("LeftButtonUp", "RightButtonUp");

        return f
    end
end

do  --Position Chain, Dock
    --New widget will be put to the top
    local GAP_Y = 20;

    local pairs = pairs;
    local ipairs = ipairs;
    local ChainedFrames = {};
    local ChainIndex = 0;

    function WidgetManager:ChainContain(widget)
        if ChainedFrames[widget] then
            return true
        else
            return false
        end
    end

    function WidgetManager:ChainAdd(widget)
        if not self:ChainContain(widget) then
            ChainIndex = ChainIndex + 1;
            ChainedFrames[widget] = ChainIndex;
            self:ChainLayout();
            return true
        end
    end

    function WidgetManager:ChainRemove(widget)
        widget.currentPosition = nil;

        if self:ChainContain(widget) then
            ChainedFrames[widget] = nil;
            self:ChainLayout();
            return true
        end
    end

    function WidgetManager:ChainLayout(animate)
        local widgets = {};
        local n = 0;

        for widget, index in pairs(ChainedFrames) do
            n = n + 1;
            widget.order = index;
            widgets[n] = widget;
        end

        self.widgets = widgets;
        self.numWidgets = n;

        if self.isEditMode then
            WidgetManager:UpdateLinkIndicator();
        end

        if n == 0 then return end;

        table.sort(widgets, function(a, b)
            return a.order < b.order
        end);

        local offsetY = 0;

        --[[    --Use BOTTOMLEFT as anchor
        for i, widget in ipairs(widgets) do
            widget.targetPosition = offsetY;
            widget.anchorDirty = true;
            offsetY = offsetY + Round(widget:GetHeight()) + GAP_Y;
        end
        --]]

        --Use LEFT as anchor
        for i, widget in ipairs(widgets) do
            if i > 0 then
                offsetY = Round(offsetY + widget:GetHeight() * 0.5)
            end
            widget.targetPosition = offsetY;
            widget.anchorDirty = true;
            offsetY = Round(offsetY + widget:GetHeight() * 0.5 + GAP_Y);
        end

        animate = true;
        self:ChainPosition(animate);
    end

    function WidgetManager:ChainGetActive()
        local widgets = {};
        local n = 0;
        for widget, index in pairs(ChainedFrames) do
            if widget:IsShown() then
                n = n + 1;
                widgets[n] = widget;
            end
        end
        return widgets
    end

    local function ChainPosition_OnUpdate(self, elapsed)
        local complete = true;
        local a = 16 * elapsed;
        local diff;
        local delta;
        local widget;

        for i = 1, self.numWidgets do
            widget = self.widgets[i];
            if widget.currentPosition then
                diff = widget.targetPosition - widget.currentPosition;
                if diff ~= 0 then
                    delta = elapsed * 16 * diff;
                    if diff >= 0 and (diff < 1 or (widget.currentPosition + delta >= widget.targetPosition)) then
                        widget.currentPosition = widget.targetPosition;
                        complete = complete and true;
                    elseif diff <= 0 and (diff > -1 or (widget.currentPosition + delta <= widget.targetPosition)) then
                        widget.currentPosition = widget.targetPosition;
                        complete = complete and true;
                    else
                        widget.currentPosition = widget.currentPosition + delta;
                        complete = false;
                    end

                    if widget.anchorDirty then
                        widget.anchorDirty = nil;
                        widget:ClearAllPoints();
                    end

                    widget:SetPoint("LEFT", MainAnchor, "BOTTOMLEFT", 0, widget.currentPosition);
                end
            else
                if widget.anchorDirty then
                    widget.anchorDirty = nil;
                    widget:ClearAllPoints();
                end
                widget:SetPoint("LEFT", MainAnchor, "BOTTOMLEFT", 0, widget.targetPosition);
                widget.currentPosition = widget.targetPosition;
            end
        end

        if complete then
            self:SetScript("OnUpdate", nil);
        end
    end

    function WidgetManager:ChainPosition(animate)
        if animate  then
            self:SetScript("OnUpdate", ChainPosition_OnUpdate);
        else
            self:SetScript("OnUpdate", nil);
            local widget;
            local y;
            for i = 1, self.numWidgets do
                widget = self.widgets[i];
                if widget.anchorDirty then
                    widget.anchorDirty = nil;
                    widget:ClearAllPoints();
                end
                y = widget.targetPosition;
                widget:SetPoint("LEFT", MainAnchor, "BOTTOMLEFT", 0, y);
                widget.currentPosition = y;
            end
        end
    end
end

do  --Change Main Anchor Position
    local AnchorPosition = WidgetManager:CreateWidget(DBKEY_POSITION);
    AnchorPosition:Hide();
    AnchorPosition:SetPoint("LEFT", MainAnchor, "LEFT", 0, 0);

    function AnchorPosition:SetPoint(...)
        MainAnchor:SetPoint(...)
    end

    function AnchorPosition:ClearAllPoints()
        MainAnchor:ClearAllPoints();
    end

    function AnchorPosition:Init()
        self.Init = nil;

        local E_SCALE = 0.5;
        local FRAME_WIDTH, FRAME_HEIGHT = 536, 88;
        local BG_WIDTH, BG_HEIGHT = 576, 128;
        local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestPopup.png";

        self:SetSize(FRAME_WIDTH * E_SCALE, FRAME_HEIGHT * E_SCALE);

        local Background = self:CreateTexture(nil, "OVERLAY");
        Background:SetPoint("CENTER", self, "CENTER", 0, 0);
        Background:SetSize(BG_WIDTH * E_SCALE, BG_HEIGHT * E_SCALE);
        Background:SetTexture(file);
        Background:SetTexCoord(0, 576/1024, 384/1024, 512/1024);

        local Text = self:CreateFontString(nil, "OVERLAY", "DUIFontFamily_Serif_16", 2);
        Text:SetPoint("CENTER", self, "CENTER", 0, 0);
        Text:SetJustifyH("CENTER");
        Text:SetJustifyV("MIDDLE");
        Text:SetTextColor(0, 0, 0);
        Text:SetShadowColor(1, 1, 1, 0.5);
        Text:SetShadowOffset(2, -2);
        Text:SetText(L["Popup Position"]);
    end

    function AnchorPosition:OnMouseUp(button)
        if button == "RightButton" and self:IsMouseMotionFocus() then
            self:Hide();
        elseif button == "MiddleButton" then
            self:ResetPosition();
        end
    end

    function AnchorPosition:ShowLinkIndicator(state)
        if state then
            if not self.linkPool then
                local function OnEnter(f)
                    if f.owner then
                        local tooltipText;
                        if f.owner.widgetName then
                            tooltipText = string.format(L["Widget Is Docked Named"], f.owner.widgetName);
                        else
                            tooltipText = L["Widget Is Docked Generic"];
                        end
                        f.tooltipText = tooltipText;
                        TooltipFrame.ShowWidgetTooltip(f);
                    end
                end

                local function OnLeave(f)
                    TooltipFrame.HideTooltip();
                end

                local function OnAcquire(f)
                    local level = self:GetFrameLevel() - 1;
                    f:SetFrameLevel(level);
                    local px = API.GetPixelForWidget(f, 1);
                    f.Icon:SetSize(64*px, 64*px);
                    f:SetSize(40*px, 40*px);
                end

                local function OnCreate()
                    local f = CreateFrame("Frame", nil, self);
                    local Icon = f:CreateTexture(nil, "OVERLAY", nil, -1);
                    f.Icon = Icon;
                    Icon:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestPopup.png");
                    Icon:SetTexCoord(832/1024, 896/1024, 0, 64/1024);
                    Icon:SetPoint("CENTER", f, "CENTER", 0, 0);
                    OnAcquire(f);
                    f:SetScript("OnEnter", OnEnter);
                    f:SetScript("OnLeave", OnLeave);
                    return f
                end

                local function OnRemove(f)
                    f:Hide();
                    f:ClearAllPoints();
                end

                self.linkPool = API.CreateObjectPool(OnCreate, OnRemove, OnAcquire);
            end
            WidgetManager:UpdateLinkIndicator();
        else
            if self.linkPool then
                self.linkPool:Release();
            end
        end
    end


    function WidgetManager:UpdateLinkIndicator()
        if AnchorPosition.linkPool then
            AnchorPosition.linkPool:Release();

            local widgets = WidgetManager:ChainGetActive();
            local f;
            for _, widget in ipairs(widgets) do
                f = AnchorPosition.linkPool:Acquire();
                f.owner = widget;
                f:SetPoint("CENTER", widget, "TOP", 0, 0);
            end
        end
    end

    function WidgetManager:TogglePopupAnchor(state)
        if state == nil then
            state = not AnchorPosition:IsShown();
        end

        if state then
            self.isEditMode = true;
            if AnchorPosition.Init then
                AnchorPosition:Init();
            end
            AnchorPosition:LoadPosition();
            AnchorPosition:Show();
            AnchorPosition:SetFrameStrata("FULLSCREEN_DIALOG");
            AnchorPosition:SetFrameLevel(128);
            AnchorPosition:ShowLinkIndicator(true);
        else
            self.isEditMode = false;
            AnchorPosition:Hide();
            AnchorPosition:ShowLinkIndicator(false);
            TooltipFrame.HideTooltip();
        end
    end

    function WidgetManager:ResetPosition()
        AnchorPosition:ResetPosition();
    end

    function WidgetManager:IsUsingCustomPosition()
        return AnchorPosition:IsUsingCustomPosition()
    end


    local function Settings_WidgetManagerDummy(dbValue)
        AnchorPosition:LoadPosition();
    end
    addon.CallbackRegistry:Register("SettingChanged.WidgetManagerDummy", Settings_WidgetManagerDummy);
end

do  --Event Handler
    --Events and their handlers are set in other Widget sub-modules
    function WidgetManager:OnEvent(event, ...)
        if self[event] then
            self[event](self, ...);
        end
    end
    WidgetManager:SetScript("OnEvent", WidgetManager.OnEvent);
end

do  --Loot Message Processor
    local PLAYER_GUID, PLAYER_NAME;
    local match = string.match;
    local tonumber = tonumber;

    local function GetPlayerGUID()
        PLAYER_GUID = UnitGUID("player");
        PLAYER_NAME = UnitName("player");
    end
    addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", GetPlayerGUID);


    local LootMessageProcessorMixin = {};

    function LootMessageProcessorMixin:CHAT_MSG_LOOT_RETAIL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid)
        --Payloads are different on Classic!
        if guid ~= PLAYER_GUID then return end;
        self:ProcessLootMessage(text);
    end

    function LootMessageProcessorMixin:CHAT_MSG_LOOT_CLASSIC(text, _, _, _, playerName)
        if playerName ~= PLAYER_NAME then return end;
        self:ProcessLootMessage(text);
    end

    function LootMessageProcessorMixin:OnItemLooted(item)
        --Override
    end

    function LootMessageProcessorMixin:ProcessLootMessage_ItemID(text)
        local itemID = match(text, "item:(%d+)", 1);
        if itemID then
            itemID = tonumber(itemID);
            if itemID then
                self:OnItemLooted(itemID);
            end
        end
    end

    function LootMessageProcessorMixin:ProcessLootMessage_ItemLink(text)
        local link = match(text, "|H(item:[:%d]+)|h", 1);
        if link then
            self:OnItemLooted(link);
        end
    end

    if addon.IsToCVersionEqualOrNewerThan(100000) then
        LootMessageProcessorMixin.CHAT_MSG_LOOT = LootMessageProcessorMixin.CHAT_MSG_LOOT_RETAIL;
    else
        LootMessageProcessorMixin.CHAT_MSG_LOOT = LootMessageProcessorMixin.CHAT_MSG_LOOT_CLASSIC;
    end

    function WidgetManager:AddLootMessageProcessor(f, mode)
        f.CHAT_MSG_LOOT = LootMessageProcessorMixin.CHAT_MSG_LOOT;
        mode = mode or "ItemID";

        if mode == "ItemID" then
            f.ProcessLootMessage = LootMessageProcessorMixin.ProcessLootMessage_ItemID;
        elseif mode == "ItemLink" then
            f.ProcessLootMessage = LootMessageProcessorMixin.ProcessLootMessage_ItemLink;
        end

        return f
    end
end