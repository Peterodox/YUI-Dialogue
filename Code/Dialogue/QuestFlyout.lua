local _, addon = ...
local API = addon.API;
local L = addon.L;
local ThemeUtil = addon.ThemeUtil;
local QUEST_ERROR_TYPES = addon.QUEST_ERROR_TYPES;      --See AlertFrame.lua
local Round = API.Round;

local QuestFlyout = {};
addon.QuestFlyout = QuestFlyout;

local TEXT_SPACING  = 4;
local PARAGRAPH_SPACING = 16;
local TEXT_WIDTH = 256;
local ITEM_TEXT_WIDTH = 192;

local UIParent = UIParent;
local GetCursorPosition = GetCursorPosition;
local GetQuestItemInfo = GetQuestItemInfo;
local GetQuestItemLink = GetQuestItemLink;
local GetItemCount = C_Item.GetItemCount;


local MainFrame, LoadingIndicator, PrimaryItemButton;

local DEBUG_QUEST_DATA = {
    questID = 1,
    title = "Candy Bucket";
    paragraphs = {"Candy buckets like this are located in inns throughout the realms. Go ahead... take some!"};
    rewards = {},
};

local ContainerItemData = {};

local QuestFlyoutFrameMixin = {};
do
    function QuestFlyoutFrameMixin:Init()
        local grey = 0.2;
        local alpha = 0.9;

        self.Init = nil;
        self:SetBackgroundColor(0, 0, 0, alpha);
        self:UpdatePixel();
        self:SetFrameStrata("FULLSCREEN_DIALOG");

        local ContentFrame = CreateFrame("Frame", nil, self);
        self.ContentFrame = ContentFrame;
        ContentFrame:SetAllPoints(true);

        local Alert = self:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Title_16");
        self.Alert = Alert;
        Alert:SetPoint("CENTER", self, "CENTER", 0, 0);
        Alert:SetJustifyH("CENTER");
        Alert:SetJustifyV("MIDDLE");

        local TitleFrame = addon.CreateResizableBackground(self);
        self.TitleFrame = TitleFrame;
        TitleFrame:ClearAllPoints();
        TitleFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0);
        TitleFrame:SetBackgroundColor(1, 1, 1, alpha);

        local colorHigh = CreateColor(0.1, 0.1, 0.1, 1);
        local colorLow = CreateColor(grey, grey, grey, 1);
        TitleFrame.Background:SetGradient("VERTICAL", colorLow, colorHigh);
        TitleFrame:UpdatePixel();

        local Title = TitleFrame:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Paragraph");
        self.Title = Title;
        Title:SetPoint("LEFT", TitleFrame, "LEFT", 0, 0);
        Title:SetJustifyH("LEFT");
        Title:SetJustifyV("TOP");

        local debugBG = self:CreateTexture(nil, "ARTWORK");
        debugBG:SetAllPoints(true);
        --debugBG:SetColorTexture(1, 0, 0, 0.5);

        self:SetLineSpacing(TEXT_SPACING);

        self:SetClampedToScreen(true);
        self:SetClampRectInsets(-12, 12, 36, -12);

        --Object Pools
        local function CreateFontString()
            local fontString = ContentFrame:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Paragraph");
            return fontString
        end

        local function RemoveFontString(fontString)
            fontString:SetText(nil);
            fontString:Hide();
            fontString:ClearAllPoints();
        end

        local function OnAcquireFontString(fontString)
            fontString:SetSpacing(TEXT_SPACING);
            fontString:SetWidth(TEXT_WIDTH);
        end

        self.fontStringPool = API.CreateObjectPool(CreateFontString, RemoveFontString, OnAcquireFontString);

        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);

        self.AnimIn = self:CreateAnimationGroup(nil, "DUIQuestFlyoutAnimationTemplate");
    end

    function QuestFlyoutFrameMixin:SetLineSpacing(lineSpacing)
        local extrude = 6 * lineSpacing;
        self:SetBackgroundExtrude(extrude);
        self.TitleFrame:SetBackgroundExtrude(5 * lineSpacing);
        self.TitleFrame:ClearAllPoints();
        self.TitleFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2 * lineSpacing, 4 * lineSpacing);
        if self:IsShown() then
            self:Layout();
        end
    end

    function QuestFlyoutFrameMixin:Layout()
        local offset = 0;
        local textWidth = self.bodyWidth;
        local textHeight = self.bodyHeight;
        local width = Round(textWidth + 2*offset);
        local height = Round(textHeight + 2*offset);
        self:SetBackgroundSize(width, height);

        textWidth = self.Title:GetWrappedWidth();
        textHeight = self.Title:GetHeight();
        width = Round(textWidth + 2*offset);
        height = Round(textHeight + 2*offset);
        self.TitleFrame:SetBackgroundSize(width, height);
    end

    function QuestFlyoutFrameMixin:SetQuestText(title, paragraphs)
        self:ReleaseAllObjects();

        self.Title:SetText(title);
        ThemeUtil:SetFontColor(self.Title, "DarkModeGrey90");

        local textHeight = 0;
        local maxTextWidth = 0;

        local colorKey;
        if self.questData.isError then
            colorKey = "WarningRed";
        else
            colorKey = "DarkModeGrey70";
        end

        for i, text in ipairs(paragraphs) do
            local fs = self.fontStringPool:Acquire();
            fs:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", 0, -textHeight);
            fs:SetText(text);
            ThemeUtil:SetFontColor(fs, colorKey);
            local width = fs:GetWrappedWidth();
            if width > maxTextWidth then
                maxTextWidth = width;
            end
            textHeight = textHeight + Round(textHeight + fs:GetHeight() + PARAGRAPH_SPACING);
        end
        textHeight = textHeight - PARAGRAPH_SPACING;

        self.bodyHeight = textHeight;
        self.bodyWidth = maxTextWidth;
    end

    function QuestFlyoutFrameMixin:SetQuestRewards(rewards)
        if not rewards then return end;

        local itemID, icon, name, isUsable, method, index;
        local anyContainer = false;

        for _, data in ipairs(rewards) do
            method = data[1];
            if method == "SetRewardItem" then
                index = data[2];
                name, icon, itemID, isUsable = QuestFlyout:GetRewardItemInfo(index);
                if (itemID and ContainerItemData[itemID]) and isUsable then
                    anyContainer = true;
                    local itemButton = QuestFlyout:SetupItemButton(name, icon, itemID);
                    itemButton:ClearAllPoints();
                    itemButton:SetParent(self);
                    itemButton:SetPoint("TOP", self, "BOTTOM", 0, -24);
                    itemButton:Show();
                    break
                end
            end
        end

        if anyContainer then
            self.fadeOutDelay = 5;
        else
            self.fadeOutDelay = 5;
        end
    end

    function QuestFlyoutFrameMixin:OnUpdate_FadeIn(elapsed)
        self.alpha = self.alpha + 5 * elapsed;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
            self:StartFadeOutDelay(self.fadeOutDelay);
        end
        self:SetAlpha(self.alpha);
    end

    function QuestFlyoutFrameMixin:FadeIn(playAnimation)
        self.alpha = self:GetAlpha();
        self.isClosing = nil;
        self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
        self:EnableMouseScript(true);
        self:Show();
        
        self.AnimIn:Stop();
        if playAnimation then
            self.AnimIn:Play();
        end
    end

    function QuestFlyoutFrameMixin:OnUpdate_FadeOutDelay(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0 then
            self:SetScript("OnUpdate", nil);
            self:Close();
        end
    end

    function QuestFlyoutFrameMixin:StartFadeOutDelay(delay)
        --Allow re-fade-in when mouseover
        delay = delay or 0;
        self.alpha = self:GetAlpha();
        self.t = -delay;
        self.isClosing = false;
        self:SetScript("OnUpdate", self.OnUpdate_FadeOutDelay);
    end

    function QuestFlyoutFrameMixin:OnUpdate_Close(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0 then
            self.alpha = self.alpha - 5 * elapsed;
            if self.alpha <= 0 then
                self.alpha = 0;
                self:SetScript("OnUpdate", nil);
                self:Hide();
            end
            self:SetAlpha(self.alpha);
        end
    end

    function QuestFlyoutFrameMixin:Close()
        self.alpha = self:GetAlpha();
        self.t = 1.0;
        self.isClosing = true;
        self:SetScript("OnUpdate", self.OnUpdate_Close);
        self:EnableMouseScript(false);

        if PrimaryItemButton then
            PrimaryItemButton:SetButtonEnabled(false);
            PrimaryItemButton:ReleaseActionButton();
        end
    end

    function QuestFlyoutFrameMixin:EnableMouseScript(state)
        if state then
            self:EnableMouse(true);
            self:EnableMouseMotion(true);
        else
            self:EnableMouse(false);
            self:EnableMouseMotion(false);
        end
    end

    function QuestFlyoutFrameMixin:ReleaseAllObjects()
        self.fontStringPool:Release();
    end

    function QuestFlyoutFrameMixin:OnEvent(event, ...)
        --print(event, ...)
        if event == "GLOBAL_MOUSE_DOWN" then
            if self:IsShown() then
                if self:IsMouseOver() then
                    self:Close();
                end
            else
                --QuestFlyout:SetQuestData(DEBUG_QUEST_DATA);
            end
        elseif event == "QUEST_TURNED_IN" then
            local questID, xpReward, moneyReward = ...
            if questID == self.questID then
                self:SetWatchedQuest(nil);
                self.Alert:SetText(L["Quest Complete Alert"]);
                self:FadeIn(true);
                LoadingIndicator:FadeOut();
            end
        elseif event == "UI_ERROR_MESSAGE" then

            local errorType, message = ...
            if QUEST_ERROR_TYPES[errorType] then
                self:SetWatchedQuest(nil);
                self:DisplayErrorMessage(message);
                LoadingIndicator:FadeOut();
            end
        elseif event == "CHAT_MSG_SYSTEM" then
            local message = ...
            if string.find(message, L["Quest Failed Pattern"]) then
                self:SetWatchedQuest(nil);
                self:DisplayErrorMessage(message);
                LoadingIndicator:FadeOut();
            end
        end
    end

    function QuestFlyoutFrameMixin:OnShow()
        self:SetFrameStrata("FULLSCREEN_DIALOG");
        self:Raise();
    end

    function QuestFlyoutFrameMixin:OnHide()
        if not self:IsShown() then
            self:ReleaseAllObjects();
            --self:UnregisterAllEvents();   --debug
            self:SetAlpha(0);
            self:ClearAllPoints();
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            if PrimaryItemButton then
                PrimaryItemButton:Hide();
            end
        end
    end

    function QuestFlyoutFrameMixin:SetWatchedQuest(questID)
        --ERR_QUEST_FAILED_BAG_FULL_S
        self.questID = questID;
        if questID then
            self:RegisterEvent("QUEST_TURNED_IN");
            self:RegisterEvent("UI_ERROR_MESSAGE");
            self:RegisterEvent("CHAT_MSG_SYSTEM");
        else
            self:UnregisterEvent("QUEST_TURNED_IN");
            self:UnregisterEvent("UI_ERROR_MESSAGE");
            self:UnregisterEvent("CHAT_MSG_SYSTEM");
        end
    end

    function QuestFlyoutFrameMixin:SetQuestData(questData)
        self.questData = questData;
        self:SetQuestText(questData.title, questData.paragraphs);
        self:SetQuestRewards(questData.rewards);
        self:SetWatchedQuest(questData.questID);
        API.SetTextColorByIndex(self.Alert, 3);  --Green
        self:Layout();
    end

    function QuestFlyoutFrameMixin:DisplayErrorMessage(message)
        local data = self.questData;
        if data then
            self.Alert:SetText(nil);
            self:Hide();
            self:ReleaseAllObjects();
            data.paragraphs = API.SplitParagraph(message);
            data.questID = nil;
            data.isError = true;
            self:SetQuestData(data);
            self:FadeIn();
            --QuestFlyout:PlaceFrameAtCursor();
        else

        end
    end
end

local function TextSpacingChanged(lineSpacing, paragraphSpacing, baseFontSize)
    TEXT_SPACING = lineSpacing;
    PARAGRAPH_SPACING = paragraphSpacing;

    local fontSizeMultiplier = baseFontSize / 12;
    if fontSizeMultiplier < 1 then
        fontSizeMultiplier = 1;
    end

    TEXT_WIDTH = Round(256 * fontSizeMultiplier);
    ITEM_TEXT_WIDTH = Round(192 * fontSizeMultiplier);

    if MainFrame then
        MainFrame:SetLineSpacing(lineSpacing);
    end
end
addon.CallbackRegistry:Register("TextSpacingChanged", TextSpacingChanged);


local ItemButtonMixin = {};
do  --Quest Flyout ItemButton
    function ItemButtonMixin:OnEnter()
        if self.enabled then
            self:ShowHighlight(true);
        else
            self:ShowHighlight(false);
        end
    end

    function ItemButtonMixin:OnLeave()
        self:ShowHighlight(false);
    end

    function ItemButtonMixin:SetButtonText(text)
        self.ButtonText:SetWidth(ITEM_TEXT_WIDTH);
        self.ButtonText:SetText(text);
        self:Layout();
    end

    function ItemButtonMixin:OnMouseDown()

    end

    function ItemButtonMixin:OnMouseUp()

    end

    function ItemButtonMixin:Layout()
        local textPaddingV = 12;
        local textPaddingH = 12;
        local hotkeyFramePadding = 6;

        local buttonWidth = self.textLeftOffset + self.ButtonText:GetWrappedWidth() + textPaddingH;

        self.ButtonText:ClearAllPoints();
        if self.HotkeyFrame and self.HotkeyFrame:IsShown() then
            self.HotkeyFrame:ClearAllPoints();
            self.HotkeyFrame:SetPoint("LEFT", self.TextBackground, "LEFT", self.textLeftOffset, 0);
            self.ButtonText:SetPoint("LEFT", self.HotkeyFrame, "RIGHT", hotkeyFramePadding, 0);
            buttonWidth = buttonWidth + self.HotkeyFrame:GetWidth() + hotkeyFramePadding;
        else
            self.ButtonText:SetPoint("LEFT", self.TextBackground, "LEFT", self.textLeftOffset, 0);
        end

        local buttonHeight = Round(self.ButtonText:GetHeight() + 2 * textPaddingV);
        local minButtonWidth = 3 * buttonHeight;

        if buttonWidth < minButtonWidth then
            buttonWidth = minButtonWidth;
        end
        buttonWidth = Round(buttonWidth);

        local coordLeft = 1 - 0.125 * buttonWidth/buttonHeight;
        if coordLeft < 0 then
            coordLeft = 0;
        end

        self.TextBackground:SetSize(buttonWidth, buttonHeight);
        self.TextBackground:SetTexCoord(coordLeft, 1, (self.colorIndex - 1) * 0.125, self.colorIndex * 0.125);
        self.TextHighlight:SetTexCoord(coordLeft, 1, (self.colorIndex - 1) * 0.125, self.colorIndex * 0.125);

        self:SetWidth(Round(self.iconEffectiveWidth + buttonWidth));
    end

    function ItemButtonMixin:SetItemByID(itemID, name, icon)
        --debug
        self.itemID = itemID;
        icon = icon or C_Item.GetItemIconByID(itemID);
        if (not name) or name == "" then
            name = C_Item.GetItemNameByID(itemID);
        end
        self.Icon:SetTexture(icon);
        self:SetButtonText(name);
    end

    function ItemButtonMixin:SetColorIndex(colorIndex)
        colorIndex = colorIndex or 1;
        colorIndex = (colorIndex > 5 and 1) or colorIndex;
        self.colorIndex = colorIndex;
        ThemeUtil:SetFontColor(self.ButtonText, "DarkModeGold");
    end

    function ItemButtonMixin:ShowHighlight(state)
        if state then
            self.TextHighlight:Show();
            self.BorderHighlight:Show();
        else
            self.TextHighlight:Hide();
            self.BorderHighlight:Hide();
        end
    end

    function ItemButtonMixin:SetButtonEnabled(isEnabled)
        self.enabled = isEnabled;
        local colorKey;

        if isEnabled then
            colorKey = "DarkModeGold";
            if self.ActionButton and self.ActionButton:IsFocused() then
                self:ShowHighlight(true);
            else
                self:ShowHighlight(false);
            end
            self.TextBackground:SetDesaturated(false);
            self.IconBorder:SetDesaturated(false);
            self.Icon:SetDesaturated(false);
            self.Icon:SetVertexColor(1, 1, 1);
            self:EnableMouse(true);
            self:EnableMouseMotion(true);
        else
            colorKey = "DarkModeGrey70";
            self:ShowHighlight(false);
            self.TextBackground:SetDesaturated(true);
            self.IconBorder:SetDesaturated(true);
            self.Icon:SetDesaturated(true);
            self.Icon:SetVertexColor(0.6, 0.6, 0.6);
            self:EnableMouse(false);
            self:EnableMouseMotion(false);
        end

        ThemeUtil:SetFontColor(self.ButtonText, colorKey);
    end

    function ItemButtonMixin:GetActionButton()
        local ActionButton = addon.AcquireSecureActionButton("QuestAutoCompleteFlyout");
        if ActionButton then
            self.ActionButton = ActionButton;
            ActionButton:SetScript("OnEnter", function()
                self:OnEnter();
            end);
            ActionButton:SetScript("OnLeave", function()
                self:OnLeave();
            end);
            ActionButton:SetScript("PostClick", function(f, button)
                self:OnMouseUp(button);
            end);
            ActionButton:SetParent(self);
            ActionButton:SetFrameStrata(self:GetFrameStrata());
            ActionButton:SetFrameLevel(self:GetFrameLevel() + 5);
            ActionButton.onEnterCombatCallback = function()
                self:SetButtonEnabled(false);
            end;
            self:SetButtonEnabled(true);
            return ActionButton
        else
            self:SetButtonEnabled(false);
        end
    end

    function ItemButtonMixin:ReleaseActionButton()
        if self.ActionButton then
            self.ActionButton:Release();
        end
    end

    function ItemButtonMixin:SetUsableItem(itemID, name, icon)
        local allowPressKeyToUse = addon.GetDBBool("PressKeyToOpenContainer") and (addon.GetDBValue("InputDevice") == 1);
        local ActionButton = self:GetActionButton();
        local nameReady;

        if ActionButton then
            nameReady = ActionButton:SetUseItemByID(itemID, "AnyButton", allowPressKeyToUse, name);
            ActionButton:CoverObject(self, 4);
        end

        if allowPressKeyToUse then
            if not self.HotkeyFrame then
                local f = CreateFrame("Frame", nil, self, "DUIDialogHotkeyTemplate");
                self.HotkeyFrame = f;
                f:SetTheme(2);
                f:SetKey("SPACE");
            end
            self.HotkeyFrame:Show();
            self.HotkeyFrame:UpdateBaseHeight();

            if not nameReady then
                self:RequestUpdateItem(0.2);
            end
        else
            if self.HotkeyFrame then
                self.HotkeyFrame:Hide();
            end
        end

        self:SetItemByID(itemID, name, icon);
        self:RegisterEvent("PLAYER_REGEN_ENABLED");
        self:RegisterEvent("BAG_UPDATE_DELAYED");
        self:RegisterEvent("LOOT_OPENED");
        self:RegisterEvent("LOOT_CLOSED");
        self:SetScript("OnEvent", self.OnEvent);

        local count = GetItemCount(self.itemID);
        if count > 0 then
            self:SetButtonEnabled(true);
        else
            self:SetButtonEnabled(false);
            self:ReleaseActionButton();
        end
    end

    function ItemButtonMixin:OnHide()
        if not self:IsShown() then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:UnregisterEvent("PLAYER_REGEN_ENABLED");
            self:UnregisterEvent("BAG_UPDATE_DELAYED");
            self:UnregisterEvent("LOOT_OPENED");
            self:UnregisterEvent("LOOT_CLOSED");
            self:ReleaseActionButton();
        end
    end

    function ItemButtonMixin:OnUpdate_BagUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > self.delay then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:UpdateItem();
        end
    end

    function ItemButtonMixin:UpdateItem()
        if self.itemID then
            self:SetUsableItem(self.itemID);
        else
            self:SetButtonEnabled(false);
            self:ReleaseActionButton();
        end
    end

    function ItemButtonMixin:RequestUpdateItem(delay)
        delay = delay or 0.033;
        self.delay = delay;
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_BagUpdate);
    end

    function ItemButtonMixin:OnEvent(event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            if self.itemID then
                self:SetUsableItem(self.itemID);
            end
        elseif event == "BAG_UPDATE_DELAYED" then
            if self.itemID then
                self:RequestUpdateItem();
            end
        elseif event == "LOOT_OPENED" then
            MainFrame:SetFrameStrata("MEDIUM");
        elseif event == "LOOT_CLOSED" then
            MainFrame:SetFrameStrata("FULLSCREEN_DIALOG");
        end
    end

    function QuestFlyout:CreateItemButton(parent)
        local f = CreateFrame("Frame", nil, parent, "DUIQuestFlyoutButtonTemplate");
        local texture = "Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestFlyoutButton.png";

        local borderSize = 52;
        local iconSize = 64/96 * borderSize;
        f.iconEffectiveWidth = 64/96 * borderSize;
        f.textLeftOffset = 40/96 * borderSize;

        local textBgLeftOffset = 64/96 * borderSize;
        f.TextBackground:ClearAllPoints();
        f.TextBackground:SetPoint("LEFT", f, "LEFT", textBgLeftOffset, 0);

        f:SetHeight(72/96 * borderSize);

        f.TextBackground:SetTexture(texture);
        f.TextHighlight:SetTexture(texture);

        f.Icon:SetTexCoord(0.0625, 0.9275, 0.0625, 0.9275);
        f.Icon:SetSize(iconSize, iconSize);

        f.IconBorder:SetTexture(texture);
        f.IconBorder:SetTexCoord(416/512, 1, 416/512, 1);
        f.IconBorder:SetSize(borderSize, borderSize);
        f.BorderHighlight:SetTexture(texture);
        f.BorderHighlight:SetTexCoord(416/512, 1, 416/512, 1);
        f.BorderHighlight:SetSize(borderSize, borderSize);

        API.Mixin(f, ItemButtonMixin);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnMouseDown", f.OnMouseDown);
        f:SetScript("OnMouseUp", f.OnMouseUp);
        f:SetScript("OnHide", f.OnHide);

        f:SetColorIndex(2);

        f.Icon:SetTexture(132940);

        return f
    end
end


do
    function QuestFlyout:PlaceFrameAtCursor()
        local x, y = GetCursorPosition();
        local cursorOffset = 80;

        local uiHeight = UIParent:GetHeight();
        if uiHeight then
            local scale = UIParent:GetEffectiveScale();
            local minY = uiHeight * 0.5 * scale;
            if y < minY then
                y = minY;
            end
        end

        y = y + cursorOffset;
        MainFrame:ClearAllPoints();
        MainFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x, y);
        --Convert the anchor to top
        local height = MainFrame:GetHeight();
        y = y + height;
        MainFrame:ClearAllPoints();
        MainFrame:SetPoint("TOP", UIParent, "BOTTOMLEFT", x, y);
    end

    function QuestFlyout:ShowLoadingIndicator()
        local x, y = GetCursorPosition();
        LoadingIndicator:ClearAllPoints();
        LoadingIndicator:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);
        LoadingIndicator:Show();
    end

    function QuestFlyout:Remove()
        if MainFrame then
            MainFrame:Hide();
        end
    end

    function QuestFlyout:SetQuestData(questData)
        if not MainFrame then
            MainFrame = addon.CreateResizableBackground(UIParent, QuestFlyoutFrameMixin);
            MainFrame:Hide();
            MainFrame:SetIgnoreParentScale(true);
            MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
            MainFrame:Init();
            MainFrame:SetAlpha(0);

            --debug
            MainFrame:SetScript("OnEvent", MainFrame.OnEvent);
            MainFrame:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end

        if not LoadingIndicator then
            LoadingIndicator = addon.CreateLoadingIndicator(UIParent);
            LoadingIndicator:SetIgnoreParentScale(true);
            LoadingIndicator:SetMaxShownTime(3);
        end

        self:ShowLoadingIndicator();

        MainFrame:Hide();
        questData = questData or DEBUG_QUEST_DATA;
        MainFrame:SetQuestData(questData);
        self:PlaceFrameAtCursor();

        --MainFrame:FadeIn(true); --debug
        --MainFrame.Alert:SetText(L["Quest Complete Alert"]);
    end

    function QuestFlyout:SetupItemButton(name, icon, itemID)
        if not PrimaryItemButton then
            PrimaryItemButton = self:CreateItemButton();
        end
        PrimaryItemButton:SetColorIndex(ContainerItemData[itemID]);
        PrimaryItemButton:SetUsableItem(itemID);
        return PrimaryItemButton
    end

    function QuestFlyout:GetRewardItemInfo(index)
        local questInfoType = "reward";
        local name, texture, count, quality, isUsable, itemID, questRewardContextFlags = GetQuestItemInfo(questInfoType, index);    --no itemID in Classic
        if not itemID then
            local link = GetQuestItemLink(questInfoType, index);
            if link then
                itemID = API.GetItemIDFromHyperlink(link);
            end
        end
        return name, texture, itemID, isUsable
    end
end


ContainerItemData = {
    --[itemID] = colorIndex,
    [37586] = 2,
    [224784] = 2,
    [229354] = 3,
    [226263] = 5,
    [226273] = 3,
    [225571] = 2,
    [225572] = 2,
    [225573] = 2,
};


do  --debug
    --[[
    C_Timer.After(0, function()
        local ib = QuestFlyout:CreateItemButton();
        ib:SetUsableItem(37582);
        ib:SetPoint("CENTER", UIParent, "CENTER", 0, 32);
    end)

    function TTT()
        QuestFlyout:SetQuestData()
    end
    --]]
end