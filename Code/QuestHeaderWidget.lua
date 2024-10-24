local _, addon = ...
local API = addon.API;
local L = addon.L;
local Round = API.Round;
local TooltipFrame = addon.SharedTooltip;
local ThemeUtil = addon.ThemeUtil;

local CreateFrame = CreateFrame;
local time = time;

local ButtonMixin = {};
local HeaderWidgetManger = {};
addon.HeaderWidgetManger = HeaderWidgetManger;

local BASE_TEXTURE = "Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestWidgetButton.png";

local WIDGET_SPACING = 8;
local PADDING_TEXT_BUTTON_V = 4;
local PADDING_TEXT_BUTTON_H = 8;
local ICON_SIZE = 14;
local ICON_TEXT_GAP = 2;

do  --HeaderWidgetManger
    function HeaderWidgetManger:SetParent(parent)
        --DialogueUI Quest Header
        self.parent = parent;
    end

    function HeaderWidgetManger:SetAnchorTo(anchorTo)
        --QuestTitle FontString
        self.anchorTo = anchorTo;
    end

    local function CreateButton()
        local f = CreateFrame("Button", nil, HeaderWidgetManger.parent, "DUIDialogHeaderWidgetTemplate");
        API.Mixin(f, ButtonMixin);
        f.Background:SetTexture(BASE_TEXTURE);
        f.Background:SetTexCoord(0, 128/512, 0/512, 32/512);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);
        return f
    end

    local function RemoveButton(button)
        button:Hide();
        button:ClearAllPoints();
        button.uiOrder = nil;
        button.onEnterFunc = nil;
        button.onClickFunc = nil;
        button.iconTextGap = nil;
    end

    local function OnAcquireButton(button)
        table.insert(HeaderWidgetManger.widgets, button);
        API.UpdateTextureSliceScale(button.Background);
    end

    HeaderWidgetManger.buttonPool = API.CreateObjectPool(CreateButton, RemoveButton, OnAcquireButton);

    function HeaderWidgetManger:ReleaseAllWidgets()
        self.uiOrder = 100;
        self.widgets = {};
        self.buttonPool:Release();
    end

    local function SortFunc_Order(a, b)
        return a.uiOrder < b.uiOrder
    end

    function HeaderWidgetManger:LayoutWidgets()
        if #self.widgets > 0 then
            local offsetY = 0;
            local isDarkMode = ThemeUtil:IsDarkMode();

            for i, widget in ipairs(self.widgets) do
                if not widget.uiOrder then
                    self.uiOrder = self.uiOrder + 1;
                    widget.uiOrder = self.uiOrder;
                end

                if widget.clickable then
                    offsetY = PADDING_TEXT_BUTTON_V;
                end

                if isDarkMode then
                    widget.SetHighlighted = ButtonMixin.SetHighlighted_Dark;
                else
                    widget.SetHighlighted = ButtonMixin.SetHighlighted_Brown;
                end
                widget:SetHighlighted(false);

                widget:Layout();
            end

            table.sort(self.widgets, SortFunc_Order);

            for i, widget in ipairs(self.widgets) do
                widget:ClearAllPoints();
                if i == 1 then
                    widget:SetPoint("BOTTOMLEFT", self.anchorTo, "TOPLEFT", 0, offsetY);
                else
                    widget:SetPoint("LEFT", self.widgets[i - 1], "RIGHT", WIDGET_SPACING, 0);
                end
            end
        end
    end

    function HeaderWidgetManger:AddCampaign(campaignName, campaignID)
        local f = self.buttonPool:Acquire();
        f:SetCampaign(campaignName, campaignID);
    end

    function HeaderWidgetManger:AddQuestTag(tagName, tagIcon)
        local f = self.buttonPool:Acquire();
        f:SetQuestTagNameAndIcon(tagName, tagIcon);
    end

    function HeaderWidgetManger:AddQuestRemainingTime(seconds)
        local f = self.buttonPool:Acquire();
        f:SetRemainingTime(seconds);
    end

    function HeaderWidgetManger:AddBtWQuestChain(chainName, onEnterFunc, onClickFunc)
        local f = self.buttonPool:Acquire();
        f:SetBtWQuestChain(chainName, onEnterFunc, onClickFunc);
    end

    function HeaderWidgetManger:OnFontSizeChanged()
        --Unused. We reload the QuestDetail after font change
        if self.parent and self.parent:IsShown() then
            if self.widgets and #self.widgets > 0 then
                for _, widget in ipairs(self.widgets) do
                    widget:Layout();
                end
                self:LayoutWidgets();
            end
        end
    end
end


do  --ButtonMixin
    function ButtonMixin:Layout()
        local buttonHeight = self.ButtonText:GetHeight() + 2 * PADDING_TEXT_BUTTON_V;
        local minButtonWidth = 4 * buttonHeight;

        local textWidth = self.ButtonText:GetWrappedWidth();
        local buttonWidth;
        local iconTextGap = self.iconTextGap or ICON_TEXT_GAP;
        self.ButtonText:ClearAllPoints();
        self.Icon:ClearAllPoints();

        if self.clickable then
            --Clickable button has background
            local iconLeftOffset = ICON_TEXT_GAP;
            if self.useIcon then
                self.Icon:SetPoint("LEFT", self, "LEFT", iconLeftOffset, 0);
                self.ButtonText:SetPoint("LEFT", self, "LEFT", iconLeftOffset + ICON_SIZE + iconTextGap, 0);
                buttonWidth = iconLeftOffset + ICON_SIZE + iconTextGap + textWidth + PADDING_TEXT_BUTTON_H;
            else
                self.ButtonText:SetPoint("LEFT", self, "LEFT", PADDING_TEXT_BUTTON_H, 0);
                buttonWidth = PADDING_TEXT_BUTTON_H + textWidth + PADDING_TEXT_BUTTON_H;
            end
            if buttonWidth < minButtonWidth then
                buttonWidth = minButtonWidth;
            end
        else
            if self.useIcon then
                self.Icon:SetPoint("LEFT", self, "LEFT", 0, 0);
                self.ButtonText:SetPoint("LEFT", self, "LEFT", ICON_SIZE + iconTextGap, 0);
                buttonWidth = ICON_SIZE + iconTextGap + textWidth;
            else
                self.ButtonText:SetPoint("LEFT", self, "LEFT", 0, 0);
                buttonWidth = textWidth;
            end
        end

        self:SetSize(Round(buttonWidth), Round(buttonHeight));
    end

    function ButtonMixin:SetIcon(icon)
        self.useIcon = icon ~= nil;
        self.Icon:SetTexture(icon);
        self.Icon:SetTexCoord(0, 1, 0, 1);
    end

    function ButtonMixin:SetText(text)
        self.ButtonText:SetText(text);
    end

    function ButtonMixin:SetHighlighted_Brown(state)
        if state then
            self.Background:SetTexCoord(0, 128/512, 36/512, 68/512);
        else
            self.Background:SetTexCoord(0, 128/512, 0/512, 32/512);
        end
    end

    function ButtonMixin:SetHighlighted_Dark(state)
        if state then
            self.Background:SetTexCoord(0, 128/512, 108/512, 140/512);
        else
            self.Background:SetTexCoord(0, 128/512, 72/512, 104/512);
        end
    end

    ButtonMixin.SetHighlighted = ButtonMixin.SetHighlighted_Brown;

    function ButtonMixin:OnEnter()
        self:SetHighlighted(true);
        if self.onEnterFunc then
            self.onEnterFunc(self);
        end
    end

    function ButtonMixin:OnLeave()
        self:SetHighlighted(false);
        TooltipFrame:HideTooltip();
    end

    function ButtonMixin:OnClick()
        if self.clickable and self.onClickFunc then
            self.onClickFunc(self);
        end
    end

    function ButtonMixin:SetClickable(state)
        self.clickable = state;
        self.Background:SetShown(state);
    end

    local function CampaignName_OnEnter(self)
        local tooltip = TooltipFrame;
        tooltip:Hide();

        if self.campaignID then
            tooltip:SetOwner(self, "ANCHOR_NONE");
            tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0);

            local campaignInfo = C_CampaignInfo.GetCampaignInfo(self.campaignID);
            tooltip:SetTitle(campaignInfo.name);
            tooltip:AddLeftLine(L["Campaign Quest"] or "Campaign", 1, 1, 1);
            if campaignInfo.description then
                tooltip:AddLeftLine(campaignInfo.description, 1, 0.82, 0);
            end

            tooltip:Show();
        end
    end

    function ButtonMixin:SetCampaign(campaignName, campaignID)
        self.uiOrder = 2;
        self.ButtonText:SetFontObject("DUIFont_Item");
        self:SetIcon(nil);
        self:SetClickable(false);
        self:SetText(campaignName);
        self.campaignID = campaignID;
        self.onEnterFunc = CampaignName_OnEnter;
    end

    local function RemainingTime_OnEnter(self)
        local tooltip = TooltipFrame;
        tooltip:Hide();

        if self.seconds then
            tooltip:SetOwner(self, "ANCHOR_NONE");
            tooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);
            local seconds = self.seconds - time() + self.fromTime;
            if seconds < 0 then
                seconds = 0;
            end
            tooltip:AddLeftLine(L["Format Time Left"]:format(API.SecondsToTime(seconds, true)), 1, 1, 1);
            tooltip:Show();
        end
    end

    function ButtonMixin:SetRemainingTime(seconds)
        --QuestRemainingTime
        self.uiOrder = 1;
        self.ButtonText:SetFontObject("DUIFont_Item");
        --self:SetIcon(nil);
        self.useIcon = true;
        self.iconTextGap = 2;
        self.Icon:SetTexture(BASE_TEXTURE);
        self.Icon:SetTexCoord(164/512, 196/512, 0, 32/512);
        self:SetClickable(false);
        self.seconds = seconds;
        self.fromTime = time();
        local text = API.SecondsToTime(seconds, true, true);
        self:SetText(text);
        self.onEnterFunc = RemainingTime_OnEnter;
    end

    function ButtonMixin:SetQuestTagNameAndIcon(name, icon)
        self.ButtonText:SetFontObject("DUIFont_Item");
        self.iconTextGap = 2;
        self:SetIcon(icon);
        self:SetText(name);
        self:SetClickable(false);
    end

    function ButtonMixin:SetBtWQuestChain(chainName, onEnterFunc, onclickFunc)
        self.uiOrder = 0;
        self.useIcon = true;
        self.iconTextGap = 2;
        self.Icon:SetTexture(BASE_TEXTURE);
        self.Icon:SetTexCoord(132/512, 164/512, 0, 32/512);
        self.ButtonText:SetFontObject("DUIFont_ItemSelect");
        self:SetText(chainName);
        self:SetClickable(true);
        self.onEnterFunc = onEnterFunc;
        self.onClickFunc = onclickFunc;
    end
end