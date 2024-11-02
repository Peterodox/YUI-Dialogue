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

local UIParent = UIParent;
local GetCursorPosition = GetCursorPosition;

local MainFrame;

local DEBUG_QUEST_DATA = {
    questID = 1,
    title = "Candy Bucket";
    paragraphs = {"Candy buckets like this are located in inns throughout the realms. Go ahead... take some!"};
    rewards = {},
};


local QuestFlyoutFrameMixin = {};
do
    function QuestFlyoutFrameMixin:Init()
        local grey = 0.2;
        local alpha = 0.9;

        self.Init = nil;
        self:SetBackgroundColor(0, 0, 0, alpha);
        self:UpdatePixel();
        self:SetFrameStrata("FULLSCREEN_DIALOG");

        local QuestText = self:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Paragraph");
        self.QuestText = QuestText;
        QuestText:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        QuestText:SetWidth(TEXT_WIDTH);
        QuestText:SetSpacing(TEXT_SPACING);
        QuestText:SetJustifyH("LEFT");
        QuestText:SetJustifyV("TOP");

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


        local ContentFrame = CreateFrame("Frame", nil, self);
        self.ContentFrame = ContentFrame;
        ContentFrame:SetAllPoints(true);

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

        self:SetScript("OnHide", self.OnHide);
    end

    function QuestFlyoutFrameMixin:SetLineSpacing(lineSpacing)
        local extrude = 6 * lineSpacing;
        self:SetBackgroundExtrude(extrude);
        self.TitleFrame:SetBackgroundExtrude(5 * lineSpacing);
        self.QuestText:SetSpacing(lineSpacing);
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

    end

    function QuestFlyoutFrameMixin:OnUpdate_FadeIn(elapsed)
        self.alpha = self.alpha + 8 * elapsed;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
            self:FadeOut(4);
        end
        self:SetAlpha(self.alpha);
    end

    function QuestFlyoutFrameMixin:FadeIn()
        self.alpha = self:GetAlpha();
        self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
        self:EnableMouseScript(true);
        self:Show();
    end

    function QuestFlyoutFrameMixin:OnUpdate_FadeOut(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0 then
            self.alpha = self.alpha - self.fadeOutSpeed * elapsed;
            if self.alpha <= 0 then
                self.alpha = 0;
                self:SetScript("OnUpdate", nil);
                self:Hide();
            end
            self:SetAlpha(self.alpha);
        end
    end

    function QuestFlyoutFrameMixin:FadeOut(delay)
        --Allow re-fade-in when mouseover
        delay = delay or 0;
        self.alpha = self:GetAlpha();
        self.t = -delay;
        self.fadeOutSpeed = 4;
        self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
    end

    function QuestFlyoutFrameMixin:Close()
        self.alpha = self:GetAlpha();
        self.t = 1.0;
        self.fadeOutSpeed = 5;
        self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
        self:EnableMouseScript(false);
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
                self:FadeIn();
            end
        elseif event == "UI_ERROR_MESSAGE" then

            local errorType, message = ...
            if QUEST_ERROR_TYPES[errorType] then
                self:SetWatchedQuest(nil);
                self:DisplayErrorMessage(message);
            end
        elseif event == "CHAT_MSG_SYSTEM" then
            local message = ...
            if string.find(message, L["Quest Failed Pattern"]) then
                self:SetWatchedQuest(nil);
                self:DisplayErrorMessage(message);
            end
        end
    end

    function QuestFlyoutFrameMixin:OnHide()
        if not self:IsShown() then
            self:ReleaseAllObjects();
            --self:UnregisterAllEvents();   --debug
            self:SetAlpha(0);
            self:ClearAllPoints();
            self.t = 0;
            self:SetScript("OnUpdate", nil);
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
        self:Layout();
    end

    function QuestFlyoutFrameMixin:DisplayErrorMessage(message)
        local data = self.questData
        if data then
            self:Hide();
            self:ReleaseAllObjects();
            data.paragraphs = API.SplitParagraph(message);
            data.questID = nil;
            data.rewards = nil;
            data.isError = true;
            self:SetQuestData(data);
            self:FadeIn();
            --QuestFlyout:PlaceFrameAtCursor();
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

    if MainFrame then
        MainFrame.QuestText:SetWidth(TEXT_WIDTH);
        MainFrame:SetLineSpacing(lineSpacing);
    end
end
addon.CallbackRegistry:Register("TextSpacingChanged", TextSpacingChanged);


do
    function QuestFlyout:PlaceFrameAtCursor()
        local x, y = GetCursorPosition();
        y = y + 32;
        MainFrame:ClearAllPoints();
        MainFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x, y);
        --Convert the anchor to top
        local height = MainFrame:GetHeight();
        y = y + height;
        MainFrame:ClearAllPoints();
        MainFrame:SetPoint("TOP", UIParent, "BOTTOMLEFT", x, y);
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

        questData = questData or DEBUG_QUEST_DATA;
        MainFrame:SetQuestData(questData);
        self:PlaceFrameAtCursor();
        --MainFrame:FadeIn(); --debug
    end
end

C_Timer.After(0, function()
    QuestFlyout:SetQuestData(DEBUG_QUEST_DATA);
end)