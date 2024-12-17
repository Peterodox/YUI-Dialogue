local _, addon = ...
local API = addon.API;
local L = addon.L;
local ThemeUtil = addon.ThemeUtil;
local QUEST_ERROR_TYPES = addon.QUEST_ERROR_TYPES;      --See AlertFrame.lua
local Round = API.Round;
local IsContainerItem = API.IsContainerItem;

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


local MainFrame, LoadingIndicator, PrimaryItemButton;


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
            fontString.width = 0;
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

        local fs;
        local numLines = 0;

        for i, text in ipairs(paragraphs) do
            if text and text ~= "" and text ~= " " then
                numLines = numLines + 1;
                fs = self.fontStringPool:Acquire();
                fs:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", 0, -textHeight);
                fs:SetText(text);
                ThemeUtil:SetFontColor(fs, colorKey);
                local width = fs:GetWrappedWidth();
                if width > maxTextWidth then
                    maxTextWidth = width;
                end
                fs.width = width;
                textHeight = Round(textHeight + fs:GetHeight() + PARAGRAPH_SPACING);
            end
        end
        textHeight = textHeight - PARAGRAPH_SPACING;

        if numLines < 2 then
            local reposition;
            if textHeight < 24 then
                reposition = true;
                textHeight = 24;
            end
            if maxTextWidth < ITEM_TEXT_WIDTH then
                maxTextWidth = ITEM_TEXT_WIDTH;
            end
            if fs and reposition then
                fs:ClearAllPoints();
                fs:SetPoint("LEFT", self.ContentFrame, "LEFT", 0.5*(maxTextWidth - fs.width), 0);
            end
        end

        self.bodyHeight = textHeight;
        self.bodyWidth = maxTextWidth;

        self.fadeOutDelay = API.Clamp(1.0*numLines, 5, 10);
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
                if IsContainerItem(itemID) and isUsable then
                    anyContainer = true;
                    local itemButton = QuestFlyout:SetupItemButton(name, icon, itemID);
                    itemButton:ClearAllPoints();
                    itemButton:SetParent(self);
                    itemButton:SetPoint("TOP", self, "BOTTOM", 0, -24);
                    itemButton:ShowButton();
                    break
                end
            end
        end

        if anyContainer then
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

            end
        elseif event == "QUEST_TURNED_IN" then
            local questID, xpReward, moneyReward = ...
            if questID == self.questID then
                self:SetWatchedQuest(nil);
                self.Alert:SetText(L["Quest Complete Alert"]);
                self:FadeIn(true);
                LoadingIndicator:FadeOut();
                if self.rawText then
                    API.PrintQuestCompletionText(self.rawText);
                    self.rawText = nil;
                end
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
        elseif event == "LOOT_OPENED" then
            self:SetFrameStrata("MEDIUM");
        elseif event == "LOOT_CLOSED" then
            self:SetFrameStrata("FULLSCREEN_DIALOG");
        end
    end

    function QuestFlyoutFrameMixin:OnShow()
        self:SetFrameStrata("FULLSCREEN_DIALOG");
        self:Raise();
        self:RegisterEvent("LOOT_OPENED");
        self:RegisterEvent("LOOT_CLOSED");
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
            self:UnregisterEvent("LOOT_OPENED");
            self:UnregisterEvent("LOOT_CLOSED");
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
        self.rawText = questData.rawText;
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
        MainFrame:SetQuestData(questData);
        self:PlaceFrameAtCursor();

        --MainFrame:FadeIn(true); --debug
        --MainFrame.Alert:SetText(L["Quest Complete Alert"]);
    end

    function QuestFlyout:SetupItemButton(name, icon, itemID)
        if not PrimaryItemButton then
            PrimaryItemButton = API.CreateItemActionButton(nil);
        end
        local allowPressKeyToUse = addon.GetDBBool("QuickSlotUseHotkey");
        PrimaryItemButton:SetUsableItem(itemID, allowPressKeyToUse);
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