local _, addon = ...
local API = addon.API;
local L = addon.L;
local Round = API.Round;
local TooltipFrame = addon.SharedTooltip;
local ThemeUtil = addon.ThemeUtil;

local CreateFrame = CreateFrame;
local time = time;

local ButtonMixin = {};
local HeaderWidgetManger = CreateFrame("Frame");
addon.HeaderWidgetManger = HeaderWidgetManger;

local BASE_TEXTURE = "Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestWidgetButton.png";

local WIDGET_SPACING = 8;
local PADDING_TEXT_BUTTON_V = 4;
local PADDING_TEXT_BUTTON_H = 8;
local ICON_SIZE = 14;
local ICON_TEXT_GAP = 2;

do  --HeaderWidgetManger
    function HeaderWidgetManger:SetOwner(parent)
        --DialogueUI Quest Header
        self.parent = parent;
        self:SetParent(parent);
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
        button.args = nil;
    end

    local function OnAcquireButton(button)
        button.ButtonText:SetWidth(0);
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

    function HeaderWidgetManger:AddAccountQuest()
        local f = self.buttonPool:Acquire();
        f:SetAccountQuest();
    end

    function HeaderWidgetManger:AddQuestRemainingTime(seconds)
        local f = self.buttonPool:Acquire();
        f:SetRemainingTime(seconds);
    end

    function HeaderWidgetManger:AddQuestLineQuest(questLineName, questLineID, questID, uiMapID, achievementID)
        local f = self.buttonPool:Acquire();
        f:SetQuestLineQuest(questLineName, questLineID, questID, uiMapID, achievementID);
    end

    function HeaderWidgetManger:AddBtWQuestChain(chainName, onEnterFunc, onClickFunc)
        local f = self.buttonPool:Acquire();
        f:SetBtWQuestChain(chainName, onEnterFunc, onClickFunc);
        self:RemoveWidgetByType("QuestLine");
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

    function HeaderWidgetManger:RemoveWidgetByType(widgetType)
        local i = 1;
        local widget = self.widgets[i];
        local anyChange;

        while widget do
            if widget.type == widgetType then
                local f = table.remove(self.widgets, i);
                self.buttonPool.Remove(f);
                anyChange = true;
            else
                i = i + 1;
            end
            widget = self.widgets[i];
        end

        if anyChange then
            self:LayoutWidgets();
        end
    end

    function HeaderWidgetManger:DoesWidgetExist(widgetType)
        for _, widget in ipairs(self.widgets) do
            if widget.type == widgetType then
                return true
            end
        end
    end

    function HeaderWidgetManger:RequestQuestData(questID, isRequery)
        self:OnHide();
        self.questID = questID;

        local anyChange;
        if (not self:DoesWidgetExist("Account")) and API.IsAccountQuest(questID) then
            self:AddAccountQuest();
            anyChange = true;
        end

        local hasQuestLineOnMap, questLineName, questLineID, uiMapID, achievementID = API.GetQuestLineInfo(questID);
        if hasQuestLineOnMap then
            if questLineName then
                if not self:DoesWidgetExist("BTW") then
                    self:AddQuestLineQuest(questLineName, questLineID, questID, uiMapID, achievementID);
                    anyChange = true;
                end
            elseif not isRequery then
                local function OnQuestLoaded(id)
                    if self.questID == id then
                        self:RequestQuestData(questID, true);
                    end
                end
                addon.CallbackRegistry:LoadQuest(questID, OnQuestLoaded);
            end
        end

        if anyChange then
            self:LayoutWidgets();
        end
    end

    function HeaderWidgetManger:OnHide()
        if self.t then
            self:SetScript("OnUpdate", nil);
            self.t = nil;
        end
    end
    HeaderWidgetManger:SetScript("OnHide", HeaderWidgetManger.OnHide);
end


do  --ButtonMixin
    function ButtonMixin:Layout()
        self.ButtonText:SetJustifyH("LEFT");

        local buttonHeight = self.ButtonText:GetHeight() + 2 * PADDING_TEXT_BUTTON_V;
        local minButtonWidth = 4 * buttonHeight;

        local textWidth = self.ButtonText:GetWrappedWidth();
        if self.ButtonText:IsTruncated() then
            textWidth = self.ButtonText:GetWidth();
        end

        local buttonWidth;
        local iconTextGap = self.iconTextGap or ICON_TEXT_GAP;
        self.ButtonText:ClearAllPoints();
        self.Icon:ClearAllPoints();

        if self.clickable then
            --Clickable button has background
            local iconLeftOffset = 2*ICON_TEXT_GAP;
            if self.useIcon then
                self.Icon:SetSize(ICON_SIZE, ICON_SIZE);
                self.ButtonText:SetPoint("LEFT", self.Icon, "RIGHT", iconTextGap, 0);
                buttonWidth = iconLeftOffset + ICON_SIZE + iconTextGap + textWidth + PADDING_TEXT_BUTTON_H;
            else
                buttonWidth = PADDING_TEXT_BUTTON_H + textWidth + PADDING_TEXT_BUTTON_H;
            end

            local extraOffset = 0;
            if buttonWidth < minButtonWidth then
                extraOffset = 0.5 * (minButtonWidth - buttonWidth);
                buttonWidth = minButtonWidth;
            end

            if self.useIcon then
                self.Icon:SetPoint("LEFT", self, "LEFT", iconLeftOffset + extraOffset, 0);
            else
                self.ButtonText:SetPoint("LEFT", self, "LEFT", PADDING_TEXT_BUTTON_H + extraOffset, 0);
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
        if state then
            self.ButtonText:SetFontObject("DUIFont_ItemSelect");
        else
            self.ButtonText:SetFontObject("DUIFont_Item");
        end
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
        self.type = "Campaign";
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
        self.type = "Time";
        self.uiOrder = 1;
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
        self.type = "Tag";
        self.iconTextGap = 2;
        self:SetIcon(icon);
        self:SetText(name);
        self:SetClickable(false);
    end

    function ButtonMixin:SetAccountQuest()
        self.type = "Account";
        self.uiOrder = 4;
        self:SetIcon("Interface/AddOns/DialogueUI/Art/Icons/Warband.png");
        self:SetText(ACCOUNT_QUEST_LABEL);
        self:SetClickable(false);
    end
    
    local function QuestLineQuest_OnEnter(self)
        if not self.args then return end;

        TooltipFrame:SetOwner(self, "ANCHOR_NONE");
        TooltipFrame:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);
        TooltipFrame:AddLeftLine(L["Story Progress"], 1, 0.82, 0, true);

        local achievementID = self.args.achievementID;
        local numCriteria = GetAchievementNumCriteria(achievementID);
		local numCompleted = 0;
        local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo;
        local _, completed;

		for i = 1, numCriteria do
			_, _, completed = GetAchievementCriteriaInfo(achievementID, i);
			if completed then
				numCompleted = numCompleted + 1;
			end
		end

        TooltipFrame:AddLeftLine(L["Format Chapter Progress"]:format(numCompleted, numCriteria));

        local quests = C_QuestLine.GetQuestLineQuests(self.args.questLineID);
        if quests then
            local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted;
            local numQuests = #quests;
            numCompleted = 0;
            for _, questID in ipairs(quests) do
                if IsQuestFlaggedCompleted(questID) then
                    numCompleted = numCompleted + 1;
                end
            end
            TooltipFrame:AddLeftLine(L["Format Quest Progress"]:format(numCompleted, numQuests));
        end

        TooltipFrame:Show();
    end

    function ButtonMixin:SetQuestLineQuest(questLineName, questLineID, questID, uiMapID, achievementID)
        self.type = "QuestLine";
        self.uiOrder = 3;
        self.args = {
            questLineID = questLineID,
            questID = questID,
            uiMapID = uiMapID,
            achievementID = achievementID,
        };
        self:SetIcon(nil);
        self.Icon:SetTexture(BASE_TEXTURE);
        self.Icon:SetTexCoord(132/512, 164/512, 0, 32/512);
        self.ButtonText:SetWidth(160);
        self:SetText(questLineName);
        self:SetClickable(false);
        self.onEnterFunc = QuestLineQuest_OnEnter;
    end

    function ButtonMixin:SetBtWQuestChain(chainName, onEnterFunc, onclickFunc)
        self.type = "BTW";
        self.uiOrder = 0;
        self.useIcon = true;
        self.iconTextGap = 2;
        self.Icon:SetTexture(BASE_TEXTURE);
        self.Icon:SetTexCoord(132/512, 164/512, 0, 32/512);
        self.ButtonText:SetWidth(160);
        self:SetText(chainName);
        self:SetClickable(true);
        self.onEnterFunc = onEnterFunc;
        self.onClickFunc = onclickFunc;
    end
end