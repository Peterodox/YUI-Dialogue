local _, addon = ...
local L = addon.L;
local API = addon.API;
local CallbackRegistry = addon.CallbackRegistry;
local CameraUtil = addon.CameraUtil;
local ThemeUtil = addon.ThemeUtil;
local TooltipFrame = addon.SharedTooltip;
local KeyboardControl = addon.KeyboardControl;
local NameplateGossip = addon.NameplateGossip;
local AlertFrame = addon.AlertFrame;    --top right of the screen
local ExperienceBar = addon.CreateStatusBar(nil, "xp");
local ChatFrame = addon.ChatFrame;
local FriendshipBar = addon.FriendshipBar;
local PlaySound = addon.PlaySound;
local IsAutoSelectOption = addon.IsAutoSelectOption;
local GetDBBool = addon.GetDBBool;
local SwipeEmulator = addon.SwipeEmulator;
local GossipDataProvider = addon.GossipDataProvider;
local HeaderWidgetManger = addon.HeaderWidgetManger;
local IS_MODERN_WOW = not addon.IS_CLASSIC;

local FadeFrame = API.UIFrameFade;
local CloseGossipInteraction = API.CloseGossipInteraction;
local IsPlayingCutscene = API.IsPlayingCutscene;

-- User Settings
local FRAME_SIZE_MULTIPLIER = 1.1;  --Default: 1.1
local SCROLLDOWN_THEN_ACCEPT_QUEST = false;
local INPUT_DEVICE_GAME_PAD = false;
--local ALWAYS_GOSSIP = false;
--local SHOW_NPC_NAME = false;
--local MARK_HIGHEST_SELL_PRICE = false;
------------------

local PADDING_H = 26.0;
local PADDING_TOP = 48.0;
local PADDING_BOTTOM = 36.0;
local BUTTON_HORIZONTAL_GAP = 8.0;
local FRAME_OFFSET_RATIO = 3/4;     --Center align to 1/4 of the WorldFrame width (to the right)

local FONT_SIZE = 12;
local TEXT_SPACING = FONT_SIZE*0.35;                --Font Size /3
local PARAGRAPH_SPACING = 4*TEXT_SPACING;           --4 * TEXT_SPACING
local PARAGRAPH_BUTTON_SPACING = 2*FONT_SIZE;       --Font Size * 2

local CreateFrame = CreateFrame;
local C_CampaignInfo = C_CampaignInfo;
local C_GossipInfo = C_GossipInfo;
local GetGossipText = API.GetGossipText;
local CloseQuest = CloseQuest;
local GetOptions = C_GossipInfo.GetOptions;
local GetAvailableQuests = C_GossipInfo.GetAvailableQuests;
local GetActiveQuests = C_GossipInfo.GetActiveQuests;
local ForceGossip = C_GossipInfo.ForceGossip;


local QuestIsFromAreaTrigger = API.QuestIsFromAreaTrigger;
local GetQuestText = API.GetQuestText;  --usage GetQuestText("type")    type: Detail, Progress, Complete, Greeting
local GetQuestTitle = GetTitleText;
local GetObjectiveText = GetObjectiveText;
local GetNumQuestItems = GetNumQuestItems;
local GetNumQuestCurrencies = GetNumQuestCurrencies;
local GetQuestID = GetQuestID;
local IsQuestCompletable = IsQuestCompletable;
local IsQuestItemHidden = IsQuestItemHidden;
local GetQuestMoneyToGet = GetQuestMoneyToGet;
local GetMoney = GetMoney;
local GetNumAvailableQuests = GetNumAvailableQuests;
local GetAvailableTitle = GetAvailableTitle;
local GetNumActiveQuests = GetNumActiveQuests;
local GetAvailableQuestInfo = API.GetAvailableQuestInfo;
local GetActiveQuestID = API.GetActiveQuestID;
local GetActiveTitle = GetActiveTitle;
local GetSuggestedGroupSize = API.GetSuggestedGroupSize;
local UnitExists = UnitExists;
local UnitName = UnitName;
local SetPortraitTexture = SetPortraitTexture;
local AcceptQuest = AcceptQuest;
local GetQuestPortraitGiver = GetQuestPortraitGiver;
local GetNumQuestChoices = GetNumQuestChoices;
local AcknowledgeAutoAcceptQuest = API.AcknowledgeAutoAcceptQuest;


local After = C_Timer.After;
local tinsert = table.insert;
local tsort = table.sort;
local find = string.find;

local Easing_Func = addon.EasingFunctions.outSine;
local Round = API.Round;

local MainFrame;

local SETTINGS_UI_VISIBLE = false;


local SharedVignette = CreateFrame("Frame");
SharedVignette:Hide();
addon.SharedVignette = SharedVignette;


DUIDialogBaseMixin = {};

function DUIDialogBaseMixin:CalculateBestFrameHeight()
    local viewportWidth, viewportHeight = API.GetBestViewportSize();
    local heightRatio = 0.618;
    local frameHeight = heightRatio * viewportHeight;
    local heightInPixel = API.GetSizeInPixel(self:GetEffectiveScale(), frameHeight);

    if heightInPixel < 640 then
        --Switch to low resolution textures?
    end

    return frameHeight
end

local Schematic = {
    ["BackgroundFrame.ClipFrame.BackgroundDecor"] = {width = 360, height = 360},
    ["FrontFrame.FooterDivider"] = {width = 392, height = 34},
    ["FrontFrame.HeaderDivider"] = {width = 392, height = 34},

    ["FrontFrame.Header"] = {width = 358, height = 51, point = "TOP", relativePoint = "TOP", x = 0, y = -28},
    ["FrontFrame.Header.Portrait"] = {width = 34, height = 34, point = "CENTER", relativePoint = "TOPLEFT", x = 23, y = -23},
    ["FrontFrame.Header.Divider"] = {width = 358, height = 51},
    ["FrontFrame.Header.Title"] = {point = "LEFT", relativePoint = "LEFT", x = 53, y = 2},
    ["FrontFrame.Header.TopLight"] = {width = 358, height = 34},
    ["FrontFrame.Header.WarbandCompleteAlert"] = {width = 44, height = 44, point = "CENTER", relativePoint = "TOPRIGHT", x = -25, y = -20},

    ["FrontFrame.QuestPortrait"] = {maxSizeMultiplier = 1.1, width = 170, height = 170, point = "TOP", relativePoint = "TOPRIGHT", x = 66, y = -64},
    ["FrontFrame.QuestPortrait.Model"] = {maxSizeMultiplier = 1.1, width = 78, height = 78, point = "CENTER", relativePoint = "TOP", x = 0, y = -71},
    ["FrontFrame.QuestPortrait.Name"] = {maxSizeMultiplier = 1.1, width = 70, height = 48, point = "CENTER", relativePoint = "BOTTOM", x = 0, y = 42},
};

local function SetupObjectSize(root, key, data)
    local obj = root;

    for k in string.gmatch(key, "%w+") do
        obj = obj[k];
    end

    local a = FRAME_SIZE_MULTIPLIER;
    if data.maxSizeMultiplier and a > data.maxSizeMultiplier then
        a = data.maxSizeMultiplier;
    end

    if data.width then
        obj:SetSize(data.width * a, data.height * a);
    end

    if data.point then
        obj:SetPoint(data.point, obj:GetParent(), data.relativePoint, data.x * a, data.y * a);
    end
end

function DUIDialogBaseMixin:UpdateFrameBaseOffset(viewportWidth)
    if not viewportWidth then
        viewportWidth = API.GetBestViewportSize();
    end

    local offsetRatio = FRAME_OFFSET_RATIO;
    local frameOffsetX = Round(viewportWidth*(offsetRatio - 0.5));
    ChatFrame:ClearAllPoints();

    if addon.IsDBValue("FrameOrientation", 1) then
        frameOffsetX = -frameOffsetX;
        ChatFrame:SetPoint("BOTTOMRIGHT", ExperienceBar, "TOPRIGHT", -8, 8);
    else
        ChatFrame:SetPoint("BOTTOMLEFT", ExperienceBar, "TOPLEFT", 8, 8);
    end

    self.frameOffsetX = frameOffsetX;
    self:ClearAllPoints();
    self:SetPoint("CENTER", nil, "CENTER", frameOffsetX, 0);
end

function DUIDialogBaseMixin:UpdateFrameSize()
    local viewportWidth, viewportHeight = API.GetBestViewportSize();

    AlertFrame:ClearAllPoints();
    local alertFrameOffset = 36;
    AlertFrame:SetPoint("TOPRIGHT", nil, "CENTER", 0.5*viewportWidth - alertFrameOffset, 0.5*viewportHeight - alertFrameOffset);

    ExperienceBar:SetPoint("BOTTOM", nil, "BOTTOM", 0, -2);
    ExperienceBar:SetBarWidth(viewportWidth);
    ExperienceBar:SetHeight(8);
    ExperienceBar:SetNumCompartment(20);

    FriendshipBar:ClearAllPoints();
    FriendshipBar:SetPoint("CENTER", self, "TOP", 0, 0);

    local frameRatio = 0.85;
    local frameHeight = self:CalculateBestFrameHeight() * FRAME_SIZE_MULTIPLIER;
    local frameWidth = API.Round(frameHeight * frameRatio);
    frameHeight = API.Round(frameHeight);
    self:SetSize(frameWidth, frameHeight);

    local paddingH = PADDING_H * FRAME_SIZE_MULTIPLIER;
    local paddingTop = PADDING_TOP * FRAME_SIZE_MULTIPLIER;
    local paddingBottom = PADDING_BOTTOM * FRAME_SIZE_MULTIPLIER;

    self.frameWidth = frameWidth;
    self.frameHeight = frameHeight;
    self.halfFrameWidth = Round(0.5* (frameWidth - 2*paddingH - BUTTON_HORIZONTAL_GAP));
    self.quarterFrameWidth = Round(0.25* (frameWidth - 2*paddingH - 3*BUTTON_HORIZONTAL_GAP));

    self:UpdateFrameBaseOffset(viewportWidth);

    self.FrontFrame:SetPoint("TOPLEFT", self, "TOPLEFT", paddingH, 0);
    self.FrontFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -paddingH, 0);

    local parchmentWidth = 546.13 * FRAME_SIZE_MULTIPLIER;  --API.GetPixelForScale(1, 1024);
    local parchmentheight = 136.53 * FRAME_SIZE_MULTIPLIER; --API.GetPixelForScale(1, 256);

    self.Parchments[1]:SetSize(parchmentWidth, parchmentheight);
    self.Parchments[3]:SetSize(parchmentWidth, parchmentheight);

    for key, data in pairs(Schematic) do
        SetupObjectSize(self, key, data);
    end

    local AcceptButton = self:AcquireAcceptButton();
    AcceptButton:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", paddingH, paddingBottom);
    AcceptButton:SetButtonWidth(self.halfFrameWidth);

    local GoodbyeButton = self:AcquireExitButton();
    GoodbyeButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -paddingH, paddingBottom);
    GoodbyeButton:SetButtonWidth(self.halfFrameWidth);

    --Resize Footer
    local footerButtonHeight = GoodbyeButton:GetHeight();
    local footerOffset = Round(footerButtonHeight + paddingBottom + BUTTON_HORIZONTAL_GAP*2);    --Default: 96     Affected by GoddbyeButton height

    self.FrontFrame.FooterDivider:ClearAllPoints();
    self.FrontFrame.FooterDivider:SetPoint("CENTER", self.FrontFrame, "BOTTOM", 0, footerOffset);
    self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -42);
    self.ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, footerOffset);

    local scrollFrameBaseHeight = self.ScrollFrame:GetHeight();
    self.ScrollFrame.range = 0;
    self.scrollFrameBaseHeight = scrollFrameBaseHeight;
    self.scrollViewHeight = scrollFrameBaseHeight;

    local contentWidth = frameWidth;
    local contentHeight = Round(scrollFrameBaseHeight);
    self.ContentFrame:SetWidth(Round(contentWidth));
    self.ContentFrame:SetHeight(contentHeight);     --Irrelevant
    self.ContentFrame:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, 0);
    self.ContentFrame:SetPoint("BOTTOMRIGHT", self.ScrollFrame, "BOTTOMRIGHT", 0, 0);
    self.contentWidth = contentWidth;

    self.InputBox:ClearAllPoints();
    self.InputBox:SetPoint("LEFT", self, "LEFT", PADDING_H, 0);
    self.InputBox:SetPoint("RIGHT", self, "RIGHT", -PADDING_H, 0);

    if self.optionButtonPool then
        local buttonWidth = self.frameWidth - 2*PADDING_H*FRAME_SIZE_MULTIPLIER;
        local function UpdateButtonWidth(button)
            button:SetButtonWidth(buttonWidth);
        end
        self.optionButtonPool:ProcessAllObjects(UpdateButtonWidth);
    end

    if self.itemButtonPool then
        local buttonWidth = self.halfFrameWidth;
        local function UpdateButtonWidth(button)
            button:SetButtonWidth(buttonWidth);
        end
        self.itemButtonPool:ProcessAllObjects(UpdateButtonWidth);
    end

    if self.smallItemButtonPool then
        local buttonWidth = self.quarterFrameWidth;
        local function UpdateButtonWidth(button)
            button:SetButtonWidth(buttonWidth);
        end
        self.smallItemButtonPool:ProcessAllObjects(UpdateButtonWidth);
    end
end

function DUIDialogBaseMixin:OnLoad()
    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);

    MainFrame = self;
    addon.DialogueUI = self;

    --TooltipFrame:SetParent(self);
    TooltipFrame:SetShowDelay(0.25);

    AlertFrame:SetParent(self);
    ChatFrame:SetParent(self);
    FriendshipBar:SetParent(self);

    ExperienceBar:SetParent(self);
    ExperienceBar:OnLoad();
    ExperienceBar:Show();
    ExperienceBar:SetFrameStrata("BACKGROUND");
    ExperienceBar:SetFixedFrameStrata(true);

    addon.Banner:SetParent(self);

    self.ButtonHighlight = self.ContentFrame.ButtonHighlight;
    self.RewardSelection = self.ContentFrame.RewardSelection;
    self.GamePadFocusIndicator = CreateFrame("Frame", nil, self.FrontFrame, "DUIDialogHotkeyTemplate");
    self.GamePadFocusIndicator:SetIgnoreParentAlpha(true);

    API.DisableSharpening(self.ButtonHighlight.BackTexture);

    local headerFrame = self.FrontFrame.Header;

    HeaderWidgetManger:SetOwner(headerFrame);
    HeaderWidgetManger:SetAnchorTo(headerFrame.Title);

    --Warband Completed Alert
    local wb = headerFrame.WarbandCompleteAlert;
    self.WarbandCompleteAlert = wb;
    wb.tooltipText = L["Quest Completed On Account"];
    wb:SetScript("OnEnter", TooltipFrame.ShowWidgetTooltip);
    wb:SetScript("OnLeave", TooltipFrame.HideTooltip);
    API.DisableSharpening(wb.Icon);


    --Frame Background
    self.Parchments = {};

    for i = 1, 3 do
        local piece = self.BackgroundFrame:CreateTexture(nil, "BACKGROUND", nil, -1);
        self.Parchments[i] = piece;
    end

    self.Parchments[1]:SetTexCoord(0, 1, 0, 256/2048);
    self.Parchments[1]:SetPoint("CENTER", self, "TOP", 0, 0);

    self.Parchments[3]:SetTexCoord(0, 1, 896/2048, 1152/2048);
    self.Parchments[3]:SetPoint("CENTER", self, "BOTTOM", 0, 0);

    self.Parchments[2]:SetTexCoord(0, 1, 256/2048, 896/2048);
    self.Parchments[2]:SetPoint("TOPLEFT", self.Parchments[1], "BOTTOMLEFT", 0, 0);
    self.Parchments[2]:SetPoint("BOTTOMRIGHT", self.Parchments[3], "TOPRIGHT", 0, 0);

    self.BackgroundDecor = self.BackgroundFrame.ClipFrame.BackgroundDecor;


    --ScrollFrame
    addon.InitEasyScrollFrame(self.ScrollFrame, self.FrontFrame.HeaderDivider, self.FrontFrame.FooterDivider)
    self:ResetScroll();

    local offsetPerScroll = 96;

    local function ScrollFrame_OnMouseWheel(f, delta)
        if delta > 0 then
            f:ScrollBy(-offsetPerScroll);
        else
            f:ScrollBy(offsetPerScroll);
        end

        SwipeEmulator:StopWatching();
    end
    self.ScrollFrame.OnMouseWheel = ScrollFrame_OnMouseWheel;
    self.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);


    --Object Pools
    local function CreateFontString()
        local fontString = self.ContentFrame:CreateFontString(nil, "ARTWORK", "DUIFont_Quest_Paragraph");
        fontString:SetSpacing(TEXT_SPACING);
        return fontString
    end

    local function RemoveFontString(fontString)
        fontString:SetText(nil);
        fontString:Hide();
        fontString:ClearAllPoints();
        fontString.ttsFlag = nil;
        fontString.isTranslation = nil;
    end

    local function OnAcquireFontString(fontString)
        fontString:SetSpacing(TEXT_SPACING);
    end

    self.fontStringPool = API.CreateObjectPool(CreateFontString, RemoveFontString, OnAcquireFontString);


    local function CreateOptionButton()
        local button = CreateFrame("Button", nil, self.ContentFrame, "DUIDialogOptionButtonTemplate");
        button:SetButtonWidth(self.frameWidth - 2*PADDING_H*FRAME_SIZE_MULTIPLIER);
        button:SetOwner(self);
        return button
    end

    local function RemoveOptionButton(button)
        button:Hide();
        button:ClearAllPoints();
        button.HotkeyFrame = nil;
        button.type = nil;
        button.hasQuestType = nil;
        button.rightFrameWidth = nil;
        button.extraObjects = nil;
    end

    local function OnAcquireOptionButton(button)
        button:ResetVisual();
    end

    self.optionButtonPool = API.CreateObjectPool(CreateOptionButton, RemoveOptionButton, OnAcquireOptionButton);


    local function CreateTextBackground()
        local texture = self.ContentFrame:CreateTexture(nil, "BORDER");
        local corner = 8;
        texture:SetTextureSliceMargins(corner, corner, corner, corner);
        texture:SetTextureSliceMode(1);
        texture:SetTexture(ThemeUtil:GetTextureFile("SubHeaderBackground.png"));
        texture:SetSize(36, 36);
        return texture
    end

    local function RemoveTextBackground(texture)
        texture:ClearAllPoints();
        texture:Hide();
    end

    self.textBackgroundPool = API.CreateObjectPool(CreateTextBackground, RemoveTextBackground);


    local function CreateItemButton()
        local button = CreateFrame("Button", nil, self.ContentFrame, "DUIDialogItemButtonTemplate");
        button:SetButtonWidth(self.halfFrameWidth);
        return button
    end

    local function RemoveItemButton(itemButton)
        itemButton:OnRelease();
    end

    local function OnAcquireItemButton(itemButton)
        itemButton:SetAlpha(1);
        itemButton:SetBackgroundTexture(1);
    end

    self.itemButtonPool = API.CreateObjectPool(CreateItemButton, RemoveItemButton, OnAcquireItemButton);


    local function CreateSmallItemButton()
        local button = CreateFrame("Button", nil, self.ContentFrame, "DUIDialogSmallItemButtonTemplate");
        button:SetButtonWidth(self.quarterFrameWidth);
        return button
    end

    local function RemoveSmallItemButton(itemButton)
        itemButton:OnRelease();
    end

    self.smallItemButtonPool = API.CreateObjectPool(CreateSmallItemButton, RemoveSmallItemButton);


    local function CreateQuestTypeFrame()
        local f = CreateFrame("Frame", nil, self, "DUIDialogQuestTypeFrameTemplate");
        return f
    end

    local function RemoveFrame(f)
        f:Remove();
        f:SetParent(self);
    end

    self.questTypeFramePool = API.CreateObjectPool(CreateQuestTypeFrame, RemoveFrame);


    local function CreateIconFrame()
        local f = CreateFrame("Frame", nil, self, "DUIDialogIconFrameTemplate");
        return f
    end

    self.iconFramePool = API.CreateObjectPool(CreateIconFrame, RemoveFrame);


    local function CreateHotkeyFrame()
        local f = CreateFrame("Frame", nil, self, "DUIDialogHotkeyTemplate");
        return f
    end

    local function RemoveHotkeyFrame(f)
        f:Hide();
        f:ClearAllPoints();
        f:SetParent(self);
    end

    self.hotkeyFramePool = API.CreateObjectPool(CreateHotkeyFrame, RemoveHotkeyFrame);

    self:UpdateFrameSize();

    API.SetPlayCutsceneCallback(function()
        self:HideUI();
    end);

    SharedVignette:AddOwner(self);

    self.isGameLoading = true;
    self:RegisterEvent("LOADING_SCREEN_DISABLED");
end

function DUIDialogBaseMixin:LoadTheme()
    local prefix = ThemeUtil:GetTexturePath();
    local parchmentFile = prefix.."Parchment.png";
    local themeID = ThemeUtil:GetThemeID();

    for _, piece in ipairs(self.Parchments) do
        piece:SetTexture(parchmentFile);
    end

    local ff = self.FrontFrame;

    ff.Header.Divider:SetTexture(parchmentFile);
    ff.Header.Divider:SetTexCoord(0, 0.65625, 0.56640625, 0.61328125);

    ff.Header.TopLight:SetTexture(parchmentFile);
    ff.Header.TopLight:SetTexCoord(0, 0.65625, 0.65234375, 0.68359375);

    ff.FooterDivider:SetTexture(parchmentFile);
    ff.FooterDivider:SetTexCoord(0, 0.71875, 0.6875, 0.71875);    --0, 0.65625, 0.6171875, 0.6484375

    ff.HeaderDivider:SetTexture(parchmentFile);
    ff.HeaderDivider:SetTexCoord(0, 0.71875, 0.72265625, 0.75390625);    --0, 0.65625, 0.6484375, 0.6171875

    ff.QuestPortrait.FrontTexture:SetTexture(parchmentFile);
    ff.QuestPortrait.FrontTexture:SetTexCoord(0, 0.3125, 0.84375, 1);
    ff.QuestPortrait:SetTheme(themeID);

    self.WarbandCompleteAlert.Icon:SetTexture(parchmentFile);
    self.WarbandCompleteAlert.Icon:SetTexCoord(0.71875, 0.8125, 0.56640625, 0.61328125);

    self.RewardSelection.FrontTexture:SetTexture(prefix.."RewardChoice-Highlight.png");
    self.RewardSelection.BackTexture:SetTexture(prefix.."RewardChoice-Highlight-Back.png");
    self.RewardSelection.BackTexture:SetVertexColor(0.65, 0, 0);

    if self.CopyTextButton then
        self.CopyTextButton:SetTheme(themeID);
    end

    if self.TTSButton then
        self.TTSButton:SetTheme(themeID);
    end

    if self.textBackgroundPool then
        local bgFile = ThemeUtil:GetTextureFile("SubHeaderBackground.png");
        local function SetBackGround(texture)
            texture:SetTexture(bgFile);
        end
        self.textBackgroundPool:ProcessAllObjects(SetBackGround);
    end

    if self.optionButtonPool then
        local method = "LoadTheme";
        self.optionButtonPool:CallAllObjects(method);
    end

    if self.itemButtonPool then
        local method = "LoadTheme";
        self.itemButtonPool:CallAllObjects(method);
    end

    if self.hotkeyFramePool then
        local method = "LoadTheme";
        self.hotkeyFramePool:CallAllObjects(method);
    end

    self.GamePadFocusIndicator:LoadTheme();

    if self.AcceptButton then
        self.AcceptButton:LoadTheme();
    end

    if self.ExitButton then
        self.ExitButton:LoadTheme();
    end

    FriendshipBar:LoadTheme();
    TooltipFrame:LoadTheme();

    self.ButtonHighlight.artID = nil;

    self:OnSettingsChanged();
end

function DUIDialogBaseMixin:ReleaseAllObjects()
    self.textHistory = {};
    self.highlightedButton = nil;
    self.fontStringPool:Release();
    self.optionButtonPool:Release();
    self.textBackgroundPool:Release();
    self.itemButtonPool:Release();
    self.smallItemButtonPool:Release();
    self.questTypeFramePool:Release();
    self.iconFramePool:Release();
    self.hotkeyFramePool:Release();

    self:ResetScroll();
    self:HighlightButton(nil);
    self:HighlightRewardChoice(nil);
    self:ResetGamePadObjects();

    KeyboardControl:ResetKeyActions();
end

function DUIDialogBaseMixin:AcquireFontString()
    return self.fontStringPool:Acquire();
end

function DUIDialogBaseMixin:AcquireAcceptButton(enableHotkey)
    if not self.AcceptButton then
        self.AcceptButton = CreateFrame("Button", nil, self, "DUIDialogOptionButtonTemplate");   --self.FrontFrame
        self.AcceptButton.HotkeyFrame = CreateFrame("Frame", nil, self.AcceptButton, "DUIDialogHotkeyTemplate");
        self.AcceptButton:SetOwner(self);
        self.AcceptButton:SetButtonAcceptQuest();
        self.AcceptButtonLock = CreateFrame("Frame", nil, self.AcceptButton, "DUIDialogOptionButtonLockTemplate");
        self.AcceptButton.ButtonLock = self.AcceptButtonLock;
        self.AcceptButton:SetButtonWidth(self.halfFrameWidth);
    end

    if not self.AcceptButton:IsMouseOver() then
        self.AcceptButton:ResetVisual();
    end

    self.AcceptButton:Hide();   --Trigger new OnEnter
    self.AcceptButton:Show();

    if enableHotkey then
        KeyboardControl:SetAction("Confirm", self.AcceptButton);
    end

    return self.AcceptButton
end

function DUIDialogBaseMixin:AcquireExitButton()
    if not self.ExitButton then
        self.ExitButton = CreateFrame("Button", nil, self, "DUIDialogOptionButtonTemplate"); --self.FrontFrame
        self.ExitButton.HotkeyFrame = CreateFrame("Frame", nil, self.ExitButton, "DUIDialogHotkeyTemplate");
        self.ExitButton:SetOwner(self);
        self.ExitButton:SetButtonExitGossip();
        self.ExitButton:SetButtonWidth(self.halfFrameWidth);
    end

    self.ExitButton:ResetVisual();
    self.ExitButton:Hide();
    self.ExitButton:Show();

    KeyboardControl:SetAction("Exit", self.ExitButton);

    return self.ExitButton
end

function DUIDialogBaseMixin:AcquireOptionButton()
    return self.optionButtonPool:Acquire();
end

function DUIDialogBaseMixin:SetSelectedGossipIndex(gossipOrderIndex)
    self.selectedGossipIndex = gossipOrderIndex;
end

function DUIDialogBaseMixin:SetAcceptCurrentQuest()
    self:SetConsumeGossipClose(false);
end

function DUIDialogBaseMixin:FlagPreviousGossipButtons()
    self:HighlightButton(nil);

    local index = self.selectedGossipIndex;

    self.optionButtonPool:ProcessActiveObjects(
        function(optionButton)
            if optionButton.type == "gossip" then
                optionButton:FlagAsPreviousGossip(index);
            else
                optionButton:Disable();
            end
        end
    );
end

function DUIDialogBaseMixin:AcquireLeftFontString(fontObject)
    local fs = self:AcquireFontString();
    if fontObject then
        fs:SetFontObject(fontObject);
    else
        fs:SetFontObject("DUIFont_Quest_Paragraph");
    end
    fs:SetJustifyV("TOP");
    fs:SetJustifyH("LEFT");
    return fs
end

function DUIDialogBaseMixin:AcquireAndSetSubHeader(text)
    local background = self.textBackgroundPool:Acquire();
    local fs = self:AcquireFontString();
    fs:SetFontObject("DUIFont_Quest_SubHeader");
    fs:SetJustifyV("TOP");
    fs:SetJustifyH("LEFT");
    fs:SetText(text);

    local width = fs:GetWrappedWidth();
    local paddingH = 8;
    local paddingV = 4;

    local backgroundWidth = Round(width + 2*paddingH);
    local backgroudHeight = 12 + 2*paddingV;
    background:SetSize(backgroundWidth, backgroudHeight);
    background.size = backgroudHeight + paddingV + TEXT_SPACING;

    fs:SetPoint("LEFT", background, "LEFT", paddingH, 0);

    return background
end

function DUIDialogBaseMixin:UseQuestLayout(state)
    local forceUpdate = SETTINGS_UI_VISIBLE == true;
    local isQuestChanged;

    if state then
        local questID = GetQuestID();
        isQuestChanged = self.questID ~= questID;
        self.questID = questID;

        if (not self.questLayout) or forceUpdate then
            self.questLayout = true;
            local topOffset = (28 + 40) * FRAME_SIZE_MULTIPLIER;
            self.scrollViewHeight = self.scrollFrameBaseHeight - 40 * FRAME_SIZE_MULTIPLIER;
            --self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", PADDING_H, -PADDING_TOP + topOffset);
            self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -topOffset);
            self.FrontFrame.Header:Show();
            self.FrontFrame.HeaderDivider:Hide();
            FriendshipBar:Hide();
        end

        local unit = UnitExists("npc") and "npc" or "player";
        SetPortraitTexture(self.FrontFrame.Header.Portrait, unit);

        if ThemeUtil:IsDarkMode() then
            self.FrontFrame.Header.Portrait:SetVertexColor(1, 1, 1);
        else
            self.FrontFrame.Header.Portrait:SetVertexColor(1, 0.9, 0.78);
        end

        self.keepGossipHistory = false;
        self.hasActiveGossipQuests = false;
        self.activeQuestButtons = {};

        if questID and API.IsQuestFlaggedCompletedOnAccount(questID) then
            self.WarbandCompleteAlert:Show();
            self.FrontFrame.Header.Title:SetPoint("RIGHT", self.FrontFrame.Header, "RIGHT", -56, 2);
            CallbackRegistry:TriggerOnNextUpdate("WarbandCompleteAlert.Show", self.FrontFrame.Header, self.WarbandCompleteAlert);
        else
            self.WarbandCompleteAlert:Hide();
            self.FrontFrame.Header.Title:SetPoint("RIGHT", self.FrontFrame.Header, "RIGHT", -8, 2);
        end

    elseif self.questLayout ~= false or forceUpdate then
        self.questLayout = false;
        self.questID = nil;
        self.questIsFromGossip = nil;
        self.scrollViewHeight = self.scrollFrameBaseHeight;
        --self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", PADDING_H, -PADDING_TOP);
        self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -42);
        self.FrontFrame.Header:Hide();
        self.BackgroundDecor:Hide();
        self.FrontFrame.QuestPortrait:FadeOut();
        self.WarbandCompleteAlert:Hide();
        CallbackRegistry:Trigger("StopViewingQuest");
    end

    return isQuestChanged
end

function DUIDialogBaseMixin:UpdateQuestTitle(method)
    local text = GetQuestTitle();

    local headerFrame = self.FrontFrame.Header;
    local title = headerFrame.Title;
    local subtitle = headerFrame.Subtitle;
    local subtitleFrame = headerFrame.SubtitleMouseOverFrame;

    subtitle:SetText(nil);
    subtitleFrame:Hide();

    title:SetFontObject("DUIFont_Quest_Title_18");
    title:SetJustifyV("BOTTOM");
    title:SetJustifyH("LEFT");
    title:SetText(text);

    local numLines = title:GetNumLines();
    if numLines > 1 then
        title:SetFontObject("DUIFont_Quest_Title_16");
        numLines = title:GetNumLines();
        if numLines > 1 then
            title:SetFontObject("DUIFont_Quest_Paragraph");
        end
    end

    HeaderWidgetManger:ReleaseAllWidgets();

    local questID = self.questID;
    local campaignID = C_CampaignInfo and C_CampaignInfo.GetCampaignID(questID);

    if campaignID and campaignID ~= 0 then
        local campaignInfo = C_CampaignInfo.GetCampaignInfo(campaignID);
        if campaignInfo then
            HeaderWidgetManger:AddCampaign(campaignInfo.name, campaignID)
        end
    else
        local questTagID = API.GetQuestTag(questID);
        if questTagID then
            --print("questTagID", questTagID) --debug
            local tagName, tagIcon = API.GetQuestTagNameIcon(questTagID);
            if tagName then
                HeaderWidgetManger:AddQuestTag(tagName, tagIcon);
            end
        end

        local isRecurring, seconds = API.GetRecurringQuestTimeLeft(questID);
        if isRecurring and seconds then
            HeaderWidgetManger:AddQuestRemainingTime(seconds);
        end

        HeaderWidgetManger:RequestQuestData(questID);
    end

    local decor = API.GetQuestBackgroundDecor(questID);
    self.BackgroundDecor:SetTexture(decor);
    self.BackgroundDecor:Show();

    CallbackRegistry:Trigger("ViewingQuest", questID, method);

    HeaderWidgetManger:LayoutWidgets();

    return 6 * (FRAME_SIZE_MULTIPLIER)   --Accounted for Header Size
end

function DUIDialogBaseMixin:ScrollTo(value)
    self.ScrollFrame:ScrollTo(value);
end

function DUIDialogBaseMixin:ScrollBy(offset)
    self.ScrollFrame:ScrollBy(offset);
end

function DUIDialogBaseMixin:ScrollToBottom()
    self.ScrollFrame:ScrollToBottom();
end

function DUIDialogBaseMixin:IsScrollAtBottom()
    if not self:IsScrollable() then
        return true
    end

    local current = self.ScrollFrame.scrollTarget or self.ScrollFrame.value;
    local range = self.ScrollFrame.range;
    return current + 0.5 > range;
end

function DUIDialogBaseMixin:ResetScroll()
    self.ScrollFrame:ResetScroll();
end

function DUIDialogBaseMixin:SetScrollable(scrollable)
    --Using ClipFrame (clipChildren or ScrollChild) breaks pixel-perfect
    --Setting parent to ScrollChild dynamically, so we can still have good looking stroke
    --Animation: ContentFrame has childChildren = true during unscroll animation

    local forceUpdate = SETTINGS_UI_VISIBLE == true;

    if scrollable and ((not self.ContentFrame.scrollable) or forceUpdate) then
        self.ContentFrame.scrollable = true;
        self.ContentFrame:ClearAllPoints();
        self.ContentFrame:SetParent(self.ScrollFrame.ScrollChild);
        self.ContentFrame:SetPoint("TOPLEFT", self.ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
        self.ContentFrame:SetWidth(self.contentWidth);

    elseif (not scrollable) and (self.ContentFrame.scrollable or forceUpdate) then
        self.ContentFrame.scrollable = false;
        self.ContentFrame:ClearAllPoints();
        self.ContentFrame:SetParent(self);
        self.ContentFrame:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, 0);
        self.ContentFrame:SetPoint("BOTTOMRIGHT", self.ScrollFrame, "BOTTOMRIGHT", 0, 0);
    end

    if scrollable then
        local useTop = not self.questLayout;
        self.ScrollFrame:SetUseOverlapBorder(useTop, true);
    else
        self.ScrollFrame:SetUseOverlapBorder(false, false);
    end

    SwipeEmulator:SetOwner(self.ScrollFrame);
    SwipeEmulator:SetScrollable(scrollable, self.ScrollFrame);
end

function DUIDialogBaseMixin:IsScrollable()
    return self.ContentFrame.scrollable == true
end

function DUIDialogBaseMixin:SetScrollRange(contentHeight)
    self.contentHeight = contentHeight;

    local scrollViewHeight = self.scrollViewHeight; --self.ScrollFrame:GetHeight();  --affected by intro animation!
    local range = contentHeight - scrollViewHeight + PARAGRAPH_SPACING;
    local scrollable;

    if range > 0 then
        scrollable = true;

        if range < 12 then
            range = 12;
        end
        range = Round(range + 36);

        self.ScrollFrame.range = range;
        self.FrontFrame.FooterDivider:SetAlpha(1);
    else
        scrollable = false;
        self.ScrollFrame.range = 0;
    end

    self:SetScrollable(scrollable);
end


local function SortFunc_GossipOrder(a, b)
	return a.orderIndex < b.orderIndex;
end

local GOSSIP_QUEST_LABEL = L["Gossip Quest Option Prepend"] or "(Quest)";

local function SortFunc_GossipPrioritizeQuest(a, b)
    if a.flags and b.flags and (a.flags ~= b.flags) then
        return a.flags > b.flags
    end

    local isQuestA = find(a.name, GOSSIP_QUEST_LABEL);
    local isQuestB = find(b.name, GOSSIP_QUEST_LABEL);

    if isQuestA ~= nil and isQuestB == nil then
        return true
    elseif isQuestA == nil and isQuestB ~= nil then
        return false
    end

    if a.icon ~= b.icon and (a.icon == 132053 or b.icon == 132053) then
        --Sort non-regular gossip icon to the top (e.g. Merchant)
        return a.icon ~= 132053
    end

	return a.orderIndex < b.orderIndex
end
addon.SortFunc_GossipPrioritizeQuest = SortFunc_GossipPrioritizeQuest;

local function SortFunc_PrioritizeCompleteQuest(a, b)
    if a.isComplete ~= b.isComplete then
        return a.isComplete
    elseif a.isAvailableQuest ~= b.isAvailableQuest then
        return a.isAvailableQuest
    else
        return a.originalOrder < b.originalOrder
    end
end

function DUIDialogBaseMixin:FadeInContentFrame()
    if self:IsShown() and not SETTINGS_UI_VISIBLE then
        FadeFrame(self.ContentFrame, 0.35, 1, 0);
        PlaySound("SOUNDKIT.IG_QUEST_LIST_OPEN");
    else
        self.ContentFrame:SetAlpha(1);
    end
end

function DUIDialogBaseMixin:InsertText(offsetY, text, fontObject)
	--Add no spacing
	local fs = self:AcquireLeftFontString(fontObject);
	fs:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
	fs:SetPoint("RIGHT", self.ContentFrame, "RIGHT", -PADDING_H * FRAME_SIZE_MULTIPLIER, 0);
	fs:SetText(text);
	offsetY = Round(offsetY + fs:GetHeight());
	return offsetY
end

function DUIDialogBaseMixin:InsertParagraph(offsetY, paragraphText, fontObject)
	--Add paragrah spacing
	return self:InsertText(offsetY + PARAGRAPH_SPACING, paragraphText, fontObject);
end

function DUIDialogBaseMixin:FormatParagraph(offsetY, text, ttsFlag)
    local paragraphs = API.SplitParagraph(text);
	local firstObject, lastObject;
    if paragraphs and #paragraphs > 0 then
        for i, paragraphText in ipairs(paragraphs) do
            local fs = self:AcquireLeftFontString();
            if not firstObject then
                firstObject = fs;
            end
            fs:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
            fs:SetPoint("RIGHT", self.ContentFrame, "RIGHT", -PADDING_H * FRAME_SIZE_MULTIPLIER, 0);
            fs:SetText(paragraphText);
            offsetY = Round(offsetY + fs:GetHeight() + PARAGRAPH_SPACING);
            lastObject = fs;
            fs.ttsFlag = ttsFlag;
        end
        offsetY = offsetY - PARAGRAPH_SPACING;
    else
        --For QuestGreeting where the NPC says nothing
        local fs = self:AcquireLeftFontString();
        firstObject = fs;
        fs:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
        fs:SetPoint("RIGHT", self.ContentFrame, "RIGHT", -PADDING_H * FRAME_SIZE_MULTIPLIER, 0);
        fs:SetText(" ");
        lastObject = fs;
    end

    return offsetY, firstObject, lastObject
end

function DUIDialogBaseMixin:FormatDualParagraph(offsetY, text1, text2)
    --For Dual-language addons
    --Format: paragraph1, translatedPargraph1, paragraph2, translatedPargraph2, ...

    local paragraphs2 = text2 and API.SplitParagraph(text2);
    if paragraphs2 and #paragraphs2 > 0 then
        local paragraphs1 = API.SplitParagraph(text1);
        if paragraphs1 and #paragraphs1 > 0 then
            local firstObject, lastObject;
            local maxIndex = math.max(#paragraphs1, #paragraphs2);
            local sources = {paragraphs1, paragraphs2};
            for i = 1, maxIndex do
                for j = 1, 2 do
                    local para = sources[j];
                    if para[i] then
                        local fs = self:AcquireLeftFontString((j == 2 and "DUIFont_Quest_MultiLanguage") or "DUIFont_Quest_Paragraph");
                        if not firstObject then
                            firstObject = fs;
                        end
                        fs:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
                        fs:SetPoint("RIGHT", self.ContentFrame, "RIGHT", -PADDING_H * FRAME_SIZE_MULTIPLIER, 0);
                        fs:SetText(para[i]);
                        offsetY = Round(offsetY + fs:GetHeight() + PARAGRAPH_SPACING);
                        lastObject = fs;
                        fs.isTranslation = j == 2;
                    end
                end
            end
            offsetY = offsetY - PARAGRAPH_SPACING;
            return offsetY, firstObject, lastObject
        else
            return self:FormatParagraph(offsetY, text1)
        end
    else
        return self:FormatParagraph(offsetY, text1)
    end
end

local function ConcatenateNPCName(text)
    if GetDBBool("ShowNPCNameOnPage") and UnitExists("npc") then
        local name = UnitName("npc");
        if text and name and name ~= "" then
            return name..": "..text
        end
    end

    return text
end

function DUIDialogBaseMixin:HandleInitialLoadingComplete()
    if self.deferredEvent then
        --We handle quests that are auto accepted upon logging in
        --If the player talks to an NPC immediately after the initial loading screen, our UI won't turn visible
        local questID = GetQuestID();
        if (self.deferredEvent == "GOSSIP_SHOW" or self.deferredEvent == "QUEST_GREETING") or (questID and questID ~= 0) then    --Some quests are auto accepted and closed by the game
            self:ShowUI(self.deferredEvent);
        end
        self.deferredEvent = nil;
    end
end

function DUIDialogBaseMixin:IsGossipHandledExternally()
    --Some addons handle goosip options (Override in SupportedAddons)
    --InteractiveWormholes
    return false
end

local function HandleAutoSelect(options, activeQuests, availableQuests, anyOption, anyActiveQuest, anyAvailableQuest, numAvailableQuests)
    --If returning true, the main UI should not be shown

    if anyOption == nil then
        anyOption = options and #options > 0;
    end

    if anyActiveQuest == nil then
        anyActiveQuest = activeQuests and #activeQuests > 0;
    end

    if anyAvailableQuest == nil then
        numAvailableQuests = availableQuests and #availableQuests
        anyAvailableQuest = numAvailableQuests and numAvailableQuests > 0;
    end

    local autoSelectGossip = GetDBBool("AutoSelectGossip");
    local autoCompleteQuest = GetDBBool("AutoCompleteQuest");

    if (autoSelectGossip or autoCompleteQuest) and (not anyOption) and (not anyActiveQuest) and (numAvailableQuests == 1) then
        local firstQuestID = availableQuests[1].questID;
        if GossipDataProvider:ShouldAutoAcceptQuest(firstQuestID) then
            C_GossipInfo.SelectAvailableQuest(firstQuestID);
            API.PrintMessage(L["Auto Select"], availableQuests[1].title);
            return true
        end
    end

    local onlyOption = #options == 1;

    if (not (anyActiveQuest or anyAvailableQuest)) and (onlyOption) and ( (not GetDBBool("ForceGossip")) or (GetDBBool("ForceGossipSkipGameObject") and API.IsInteractingWithGameObject()) ) and (not ForceGossip()) then
        if options[1].selectOptionWhenOnlyOption then
            C_GossipInfo.SelectOptionByIndex(options[1].orderIndex);
            return true
        end

        if autoSelectGossip and IsAutoSelectOption(options[1].gossipOptionID, true) then
            C_GossipInfo.SelectOption(options[1].gossipOptionID);
            API.PrintMessage(L["Auto Select"], options[1].name);
            return true
        end
    end

    if (not anyAvailableQuest) and autoSelectGossip then
        for i, data in ipairs(options) do
            if IsAutoSelectOption(data.gossipOptionID, onlyOption) then
                C_GossipInfo.SelectOption(data.gossipOptionID);
                API.PrintMessage(L["Auto Select"], data.name);
                return true
            end
        end
    end

    return false
end
addon.DialogueHandleAutoSelect = HandleAutoSelect;

function DUIDialogBaseMixin:HandleGossip()
    if self:IsGossipHandledExternally() then
        if self:IsShown() then
            CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
            self.interactionIsContinuing = true;
            self:Hide();
        else
            self.interactionIsContinuing = nil;
        end
        return false
    end

    local availableQuests = GetAvailableQuests();
    local activeQuests = GetActiveQuests();
    local options = GetOptions() or {};

    tsort(options, SortFunc_GossipPrioritizeQuest);

    local numAvailableQuests = availableQuests and #availableQuests or 0;
    local anyActiveQuest = activeQuests and #activeQuests > 0;
    local anyAvailableQuest = numAvailableQuests > 0;
    local anyQuest = anyActiveQuest or anyAvailableQuest;
    local anyOption = options and #options > 0;

    self.hasActiveGossipQuests = anyActiveQuest;
    self.numAvailableQuests = numAvailableQuests;

    --[[    --NameplateGossip isn't in use
    if (not(anyQuest or anyOption)) and NameplateGossip:ShouldUseNameplate() then
        local success = addon.NameplateGossip:RequestDisplayGossip();
        if success then
            self.keepGossipHistory = false;
            return false
        end
    end
    --]]

    local autoCompleteQuest = GetDBBool("AutoCompleteQuest");

    if HandleAutoSelect(options, activeQuests, availableQuests, anyOption, anyActiveQuest, anyAvailableQuest, numAvailableQuests) then
        return false
    end

    local fromOffsetY = 0;
    local hasPreviousGossip = false;

    if self.questLayout or (not self.keepGossipHistory) then
        self:ReleaseAllObjects();
    else
        self:ResetGamePadObjects();
        KeyboardControl:ResetKeyActions();
        fromOffsetY = self.contentHeight or fromOffsetY;
        if fromOffsetY > 0 then
            --Has previous gossip history
            hasPreviousGossip = true;
            fromOffsetY = fromOffsetY + PADDING_TOP;
            self:FlagPreviousGossipButtons();
        end

        if fromOffsetY >= 5000 then
            --Clear previous history 
            fromOffsetY = 0;
            hasPreviousGossip = false;
            self:ReleaseAllObjects();
        end
    end

    local offsetY = fromOffsetY;

    self:UseQuestLayout(false);

    local firstObject, lastObject;
    local button;

    --Welcome text
    local gossipText = GetGossipText();
    if self.hintText then
        gossipText = self.hintText.."\n\n"..gossipText;
        self.hintText = nil;
    end

    gossipText = ConcatenateNPCName(gossipText);
    offsetY, firstObject, lastObject = self:FormatParagraph(offsetY, gossipText, addon.TTSFlags.Gossip);

    local hotkeyIndex = 0;
    local hotkey;

    local enableGossipHotkey = anyOption and (not INPUT_DEVICE_GAME_PAD);
    if GetDBBool("DisableHotkeyForTeleport") then
        enableGossipHotkey = enableGossipHotkey and GossipDataProvider:IsGossipHotkeyEnabled();
    end

    local anyNewOrCompleteQuest = anyAvailableQuest;
    if not anyNewOrCompleteQuest then
        for i, questInfo in ipairs(activeQuests) do
            if questInfo.isComplete then
                anyNewOrCompleteQuest = true;
                break
            end
        end
    end

    local showGossipFirst = (options[1] and options[1].flags == 1) or (not anyNewOrCompleteQuest);

    if showGossipFirst then
        --Show gossip first if there is a (Quest) Gossip
        local hintGossipData;

        if GetDBBool("ShowDialogHint") then
            for i, data in ipairs(options) do
                if not hintGossipData then
                    if GossipDataProvider:DoesOptionHaveHint(data.gossipOptionID) then
                        hintGossipData = data;
                        break
                    end
                end
            end
        end

        if hintGossipData then
            hotkeyIndex = hotkeyIndex + 1;
            button = self:AcquireOptionButton();
            if enableGossipHotkey then
                hotkey = KeyboardControl:SetIndexedAction(hotkeyIndex, button);
            else
                hotkey = nil;
            end
            button:SetGossipHint(hintGossipData, hotkey);
            local spacing = -PARAGRAPH_SPACING;
            button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, spacing);
            lastObject = button;
        end

        for i, data in ipairs(options) do
            hotkeyIndex = hotkeyIndex + 1;
            button = self:AcquireOptionButton();
            if enableGossipHotkey then
                hotkey = KeyboardControl:SetIndexedAction(hotkeyIndex, button);
            else
                hotkey = nil;
            end
            button:SetGossip(data, hotkey);

            if i == 1 and not hintGossipData then
                local spacing = -PARAGRAPH_SPACING;
                button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, spacing);
            else
                button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, 0);
            end

            lastObject = button;

            self:IndexGamePadObject(button);
        end
    end


    --Quest
    local questIndex = 0;
    local quests = {};
    self.activeQuestButtons = {};

    for i, questInfo in ipairs(availableQuests) do
        questIndex = questIndex + 1;
        questInfo.isOnQuest = false;
        questInfo.isAvailableQuest = true;
        questInfo.isComplete = false;
        questInfo.originalOrder = questIndex;
        questInfo.index = i;
        quests[questIndex] = questInfo;
    end

    for i, questInfo in ipairs(activeQuests) do
        questIndex = questIndex + 1;
        questInfo.isOnQuest = true;     --there is a delay between C_Gossip and C_QuestLog.IsOnQuest
        questInfo.isAvailableQuest = false;
        if questInfo.isComplete == nil then
            questInfo.isComplete = false;
        elseif questInfo.isComplete then
            anyNewOrCompleteQuest = true;
            if autoCompleteQuest then
                if GossipDataProvider:ShouldAutoCompleteQuest(questInfo.questID) then
                    C_GossipInfo.SelectActiveQuest(questInfo.questID);
                    return false
                end
            end
        end
        questInfo.originalOrder = questIndex;
        questInfo.index = i;
        quests[questIndex] = questInfo;
    end

    tsort(quests, SortFunc_PrioritizeCompleteQuest);

    local lastQuestComplete, lastQuestAvailable;

    for i, questInfo in ipairs(quests) do
        hotkeyIndex = hotkeyIndex + 1;
        button = self:AcquireOptionButton();
        hotkey = KeyboardControl:SetIndexedAction(hotkeyIndex, button);

        if questInfo.isAvailableQuest then
            button:SetAvailableQuest(questInfo, questInfo.index, hotkey);
        else
            button:SetActiveQuest(questInfo, questInfo.index, hotkey);
            tinsert(self.activeQuestButtons, button);
        end

        if i == 1 or (questInfo.isAvailableQuest ~= lastQuestAvailable) or (questInfo.isComplete ~= lastQuestComplete) then
            button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -PARAGRAPH_BUTTON_SPACING);
            lastQuestAvailable = questInfo.isAvailableQuest;
            lastQuestComplete = questInfo.isComplete;
        else
            button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -1);
        end

        lastObject = button;

        self:IndexGamePadObject(button);
    end


    --Options
    if not showGossipFirst then
        local hintGossipData;

        if GetDBBool("ShowDialogHint") then
            for i, data in ipairs(options) do
                if not hintGossipData then
                    if GossipDataProvider:DoesOptionHaveHint(data.gossipOptionID) then
                        hintGossipData = data;
                        break
                    end
                end
            end
        end

        if hintGossipData then
            hotkeyIndex = hotkeyIndex + 1;
            button = self:AcquireOptionButton();
            if enableGossipHotkey then
                hotkey = KeyboardControl:SetIndexedAction(hotkeyIndex, button);
            else
                hotkey = nil;
            end
            button:SetGossipHint(hintGossipData, hotkey);
            local spacing = (anyQuest and -PARAGRAPH_BUTTON_SPACING) or -PARAGRAPH_SPACING;
            button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, spacing);
            lastObject = button;
        end

        for i, data in ipairs(options) do
            hotkeyIndex = hotkeyIndex + 1;
            button = self:AcquireOptionButton();
            if enableGossipHotkey then
                hotkey = KeyboardControl:SetIndexedAction(hotkeyIndex, button);
            else
                hotkey = nil;
            end
            button:SetGossip(data, hotkey);

            if i == 1 and not hintGossipData then
                local spacing = (anyQuest and -PARAGRAPH_BUTTON_SPACING) or -PARAGRAPH_SPACING;
                button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, spacing);
            else
                button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, 0);
            end

            lastObject = button;

            self:IndexGamePadObject(button);
        end
    end


    self.AcceptButton:Hide();
    local GoodbyeButton = self:AcquireExitButton();
    GoodbyeButton:SetButtonExitGossip();

    if not (#options > 0 or anyQuest) then
        --If there is no options, allow pressing SPACE to goodbye
        KeyboardControl:SetAction("Confirm", GoodbyeButton);
    end

    local objectHeight = firstObject:GetTop() - lastObject:GetBottom();
    local contentHeight = fromOffsetY + objectHeight;  --self.ContentFrame:GetTop()
    contentHeight = contentHeight + (hasPreviousGossip and PARAGRAPH_SPACING or 0);     --Compensate for the top divider
    self:SetScrollRange(contentHeight);

    if hasPreviousGossip then
        local scrollRangeDiff = objectHeight - self.scrollViewHeight + PARAGRAPH_SPACING;
        local extraScroll = 0;
        if scrollRangeDiff > 0 then
            extraScroll = scrollRangeDiff + 2*PARAGRAPH_SPACING;
        end
        local actualRange = Round(fromOffsetY - PARAGRAPH_SPACING + extraScroll);
        self.ScrollFrame.range = actualRange;
        self.ScrollFrame:SetUseOverlapBorder(true, true);
        self:SetScrollable(true);

        FadeFrame(self.ContentFrame, 0.35, 1, 0);

        if extraScroll == 0 then
            self:ScrollToBottom();
        else
            self:ScrollTo(fromOffsetY - PARAGRAPH_SPACING);
        end
    else
        self:FadeInContentFrame();
    end

    FriendshipBar:RequestUpdate();

    return true
end

function DUIDialogBaseMixin:HandleQuestDetail(playFadeIn)
    self:ReleaseAllObjects();
    local isQuestChanged = self:UseQuestLayout(true);
    playFadeIn = playFadeIn or isQuestChanged;

    if self.handlerArgs and self.handlerArgs[1] and self.handlerArgs[1] ~= 0 then
        local questStartItemID = self.handlerArgs[1];
        local icon = C_Item.GetItemIconByID(questStartItemID);
        if icon then
            self.FrontFrame.Header.Portrait:SetTexture(icon);
        end
    end


    --Title
    local offsetY = self:UpdateQuestTitle("Detail");

    --Detail
    local translatedObjectiveText;
    offsetY, translatedObjectiveText = self:FormatQuestText(offsetY, "Detail");

    --Objectives
    local objectiveText = GetObjectiveText();
    if objectiveText then
        --Subtitle: Quest Objectives
        offsetY = offsetY + PARAGRAPH_SPACING;
        local subheader = self:AcquireAndSetSubHeader(L["Quest Objectives"]);
        subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
        offsetY = Round(offsetY + subheader.size);

        --Objective Texts
        if translatedObjectiveText then
            offsetY = self:FormatDualParagraph(offsetY, objectiveText, translatedObjectiveText, addon.TTSFlags.QuestObjective);
        else
            offsetY = self:FormatParagraph(offsetY, objectiveText, addon.TTSFlags.QuestObjective);
        end

        local groupNum = GetSuggestedGroupSize();
        if groupNum and groupNum > 0 then
            local groupText = L["Format Suggested Players"]:format(groupNum);
            offsetY = self:InsertParagraph(offsetY, groupText);
        end
    end

    --Model
    local portraitDisplayID, questPortraitText, questPortraitName, mountPortraitDisplayID, portraitModelSceneID = GetQuestPortraitGiver();
    --debug portrait
    --portraitDisplayID = 115995;
    --questPortraitName = "King Anduin Wrynn Pam Testing Long";

    if portraitDisplayID then
        if portraitDisplayID == -1 then
            --player

        elseif portraitDisplayID > 0 then
            self.FrontFrame.QuestPortrait:SetPortrait(portraitDisplayID, questPortraitName);
        end

        if questPortraitText and questPortraitText ~= "" and questPortraitText ~= objectiveText then
            offsetY = self:InsertParagraph(offsetY, questPortraitText);
        end
    else
        self.FrontFrame.QuestPortrait:FadeOut();
    end

    --Rewards
    local rewardList;
    rewardList, self.chooseItems = addon.BuildRewardList();

    if rewardList and #rewardList > 0 then
        self:RegisterEvent("QUEST_ITEM_UPDATE");

        offsetY = offsetY + PARAGRAPH_SPACING;
        local subheader = self:AcquireAndSetSubHeader( (#rewardList == 1 and L["Reward"]) or L["Rewards"] );
        subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
        offsetY = Round(offsetY + subheader.size);

        offsetY = self:FormatRewards(offsetY, rewardList);
    end

    self:SetScrollRange(offsetY);

    local AcceptButton = self:AcquireAcceptButton(true);
    local ExitButton = self:AcquireExitButton();

    if API.IsQuestAutoAccepted() or API.IsPlayerOnQuest(self.questID) then
        AcceptButton:SetButtonAlreadyOnQuest();
        ExitButton:SetButtonCloseAutoAcceptQuest();
        KeyboardControl:SetAction("Confirm", ExitButton);
        self.acknowledgeAutoAcceptQuest = true;
    else
        AcceptButton:SetButtonAcceptQuest();
        ExitButton:SetButtonDeclineQuest(self.questIsFromGossip);
    end

    if playFadeIn then
        self:FadeInContentFrame();
    end

    addon.WidgetManager:RemoveQuestPopUpByID(self.questID);

    return true
end

function DUIDialogBaseMixin:HandleQuestAccepted(questID, classicQuestID)
    --QUEST_ACCEPTED (In Classic) questLogIndex, questID
    if self.handler == "HandleQuestDetail" then
        local currentQuestID = GetQuestID();
        if classicQuestID then
            questID = classicQuestID;
        end
        if (currentQuestID and currentQuestID ~= 0) and (questID and questID == currentQuestID) then
            local AcceptButton = self:AcquireAcceptButton(true);
            local ExitButton = self:AcquireExitButton();
            AcceptButton:SetButtonAlreadyOnQuest();
            ExitButton:SetButtonCloseAutoAcceptQuest();
        end
    end
end

local function CalulateLockDuration(rawCopper)
    if (not rawCopper) or (rawCopper <= 0) then
        return 1
    end

    local playerMoney = GetMoney();
    if playerMoney <= 0 then
        playerMoney = 1
    end

    if (rawCopper > 5000000) or (rawCopper/playerMoney) > 0.05 then   --500G or 5% of max money
        return 4
    else
        return 1
    end
end

function DUIDialogBaseMixin:HandleQuestProgress(playFadeIn)
    self:ReleaseAllObjects();
    local isQuestChanged = self:UseQuestLayout(true);
    playFadeIn = playFadeIn or isQuestChanged;

    local canComplete = IsQuestCompletable();
    if canComplete and GetDBBool("AutoCompleteQuest") then
        local questID = GetQuestID();
        local title = GetQuestTitle();
        if GossipDataProvider:ShouldAutoCompleteQuest(questID, title) and CompleteQuest then
            CompleteQuest();
            return false
        end
    end

    --Title
    local offsetY = self:UpdateQuestTitle("Progress");

    --Progress
    offsetY = self:FormatQuestText(offsetY, "Progress");

    --Required Items
    local numRequiredItems = GetNumQuestItems();
    local numRequiredCurrencies = GetNumQuestCurrencies();
    local numRequiredMoney = GetQuestMoneyToGet();
    local lockDuration; --Lock "Continue" if the quest costs gold

    if numRequiredItems > 0 or numRequiredMoney > 0 or numRequiredCurrencies > 0 then

        -- If there's money required then anchor and display it
        if numRequiredMoney > 0 then
            lockDuration = CalulateLockDuration(numRequiredMoney);

            offsetY = offsetY + PARAGRAPH_SPACING;
            local subheader = self:AcquireAndSetSubHeader(L["Costs"]);
            subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
            offsetY = Round(offsetY + subheader.size);

            local itemList = {
                {"SetRequiredMoney", numRequiredMoney, small = true}
            };

            offsetY = self:FormatRewards(offsetY, itemList);
        end

        local itemList = {};

        local actualNumRequiredItems = 0;
        for index = 1, numRequiredItems do
            local hidden = IsQuestItemHidden(index);
            if hidden == 0 then
                table.insert(itemList, {"SetRequiredItem", index});
                actualNumRequiredItems = actualNumRequiredItems + 1;
            end
        end

        -- Show the "Required Items" text if needed.
        local anyActualItems = (actualNumRequiredItems + numRequiredCurrencies > 0);

        if anyActualItems then
            offsetY = offsetY + PARAGRAPH_SPACING;
            local subheader = self:AcquireAndSetSubHeader(L["Requirements"]);
            subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
            offsetY = Round(offsetY + subheader.size);
        end

        for index = 1, numRequiredCurrencies do
            table.insert(itemList, {"SetRequiredCurrency", index});
        end

        offsetY = self:FormatRewards(offsetY, itemList);
    end

    if not canComplete then
        local objcetiveProgress = API.GetQuestLogProgress(self.questID);
        if objcetiveProgress then
            offsetY = offsetY + PARAGRAPH_SPACING;
            local subheader = self:AcquireAndSetSubHeader(L["Quest Objectives"]);
            subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
            offsetY = Round(offsetY + subheader.size);
            self:InsertText(offsetY, objcetiveProgress);
        end
    end

    local ContinueButton = self:AcquireAcceptButton(canComplete);
    ContinueButton:SetButtonContinueQuest(canComplete, lockDuration);

    local CancelButton = self:AcquireExitButton();
    CancelButton:SetButtonCancelQuestProgress(self.questIsFromGossip);

    if not canComplete then
        KeyboardControl:SetAction("Confirm", CancelButton);
    end

    self:SetScrollRange(offsetY);

    if playFadeIn then
        self:FadeInContentFrame();
    end

    return true
end

function DUIDialogBaseMixin:IsRewardChosen()
    local numRewardChoices = GetNumQuestChoices() or 0;
    local choiceID = self.rewardChoiceID;
    return numRewardChoices <= 1 or (choiceID ~= nil);
end

function DUIDialogBaseMixin:FormatQuestText(offsetY, method)
    local text = ConcatenateNPCName(GetQuestText(method));
    local translatedObjectiveText;
    if text then
        local processed = false;

        if API.GetQuestTextExternal then
            local title, text1, text2 = API.GetQuestTextExternal(self.questID, method);
            if title and text1 then
                offsetY = self:InsertParagraph(offsetY, title, "DUIFont_Quest_MultiLanguage");

                offsetY = offsetY + PARAGRAPH_SPACING;
                offsetY = self:FormatDualParagraph(offsetY, text, text1);
                translatedObjectiveText = text2;
                processed = true;
            end
        end

        if not processed then
            offsetY = offsetY + PARAGRAPH_SPACING;
            offsetY = self:FormatParagraph(offsetY, text, addon.TTSFlags.QuestObjective);
        end
    end
    return offsetY, translatedObjectiveText
end

function DUIDialogBaseMixin:HandleQuestComplete(playFadeIn)
    self:ReleaseAllObjects();

    --Rewards
    self.rewardChoiceID = nil;
    local questComplete = true;
    local rewardList;
    rewardList, self.chooseItems = addon.BuildRewardList(questComplete);

    if GetDBBool("AutoCompleteQuest") and (not self.chooseItems) then
        local questID = GetQuestID();
        local title = GetQuestTitle();
        if GossipDataProvider:ShouldAutoCompleteQuest(questID, title) then
            local completionText = GetQuestText("Complete");
            local questData = {
                questID = questID,
                title = title,
                paragraphs = API.SplitParagraph(completionText or L["Quest Complete Alert"]);
                rawText = completionText,
                rewards = rewardList,
            };

            local isAutoComplete = true;
            API.CompleteCurrentQuest(0, isAutoComplete);
            addon.QuestFlyout:SetQuestData(questData);

            return false
        end
    end

    local isQuestChanged = self:UseQuestLayout(true);
    playFadeIn = playFadeIn or isQuestChanged;

    --Title
    local offsetY = self:UpdateQuestTitle("Complete");

    --Progress
    offsetY = self:FormatQuestText(offsetY, "Complete");

    if rewardList and #rewardList > 0 then
        self:RegisterEvent("QUEST_ITEM_UPDATE");

        offsetY = offsetY + PARAGRAPH_SPACING;
        local subheader = self:AcquireAndSetSubHeader( (#rewardList == 1 and L["Reward"]) or L["Rewards"] );
        subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
        offsetY = Round(offsetY + subheader.size);

        offsetY = self:FormatRewards(offsetY, rewardList);
    end

    local CompleteButton = self:AcquireAcceptButton(true);
    CompleteButton:SetButtonCompleteQuest();

    local CancelButton = self:AcquireExitButton();
    CancelButton:SetButtonCancelQuestProgress();

    self:SetScrollRange(offsetY);

    if playFadeIn then
        self:FadeInContentFrame();
    end

    return true
end

function DUIDialogBaseMixin:HandleQuestGreeting()
    self:ReleaseAllObjects();
    self:UseQuestLayout(false);

    local offsetY = 0;
    local firstObject, lastObject;

	--local material = QuestFrame_GetMaterial();

    local geetingText = ConcatenateNPCName(GetQuestText("Greeting"));
    offsetY, firstObject, lastObject = self:FormatParagraph(offsetY, geetingText, addon.TTSFlags.Gossip);


    local questIndex = 0;
    local quests = {};
    self.activeQuestButtons = {};

    local numAvailableQuests = GetNumAvailableQuests();

    for i = 1, numAvailableQuests do
        questIndex = questIndex + 1;

        local title = GetAvailableTitle(i);
        local isTrivial, frequency, isRepeatable, isLegendary, questID = GetAvailableQuestInfo(i);

        local questInfo = {
            index = i,
            title = title,
            isComplete = false,
            questID = questID or 0,
            isOnQuest = false,
            isTrivial = isTrivial,
            frequency = frequency,
            repeatable = isRepeatable,
            isLegendary = isLegendary,
            isAvailableQuest = true,
            originalOrder = questIndex;
            --isImportant
        };

        quests[questIndex] = questInfo;
	end


    local numActiveQuests = GetNumActiveQuests();

    for i = 1, numActiveQuests do
        questIndex = questIndex + 1;

        local title, isComplete = GetActiveTitle(i);
        local questID = GetActiveQuestID(i);

        if GetDBBool("AutoCompleteQuest") then
            if GossipDataProvider:ShouldAutoCompleteQuest(questID) and SelectActiveQuest then
                SelectActiveQuest(i);
                return false
            end
        end

        local questInfo = {
            index = i,
            title = title,
            isComplete = isComplete,
            questID = questID,
            isAvailableQuest = false,
            isOnQuest = true,
            originalOrder = questIndex,
        };

        quests[questIndex] = questInfo;
    end

    tsort(quests, SortFunc_PrioritizeCompleteQuest);


    local lastQuestComplete, lastQuestAvailable;
    local hotkeyIndex = 0;
    local hotkey;
    local button;

    for i, questInfo in ipairs(quests) do
        hotkeyIndex = hotkeyIndex + 1;
        button = self:AcquireOptionButton();
        hotkey = KeyboardControl:SetIndexedAction(hotkeyIndex, button);

        if questInfo.isAvailableQuest then
            button:SetGreetingAvailableQuest(questInfo, questInfo.index, hotkey);
        else
            button:SetGreetingActiveQuest(questInfo, questInfo.index, hotkey);
            tinsert(self.activeQuestButtons, button);
        end

        if i == 1 or (questInfo.isAvailableQuest ~= lastQuestAvailable) or (questInfo.isComplete ~= lastQuestComplete) then
            button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -PARAGRAPH_BUTTON_SPACING);
            lastQuestAvailable = questInfo.isAvailableQuest;
            lastQuestComplete = questInfo.isComplete;
        else
            button:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -1);
        end

        lastObject = button;

        self:IndexGamePadObject(button);
    end


    self.AcceptButton:Hide();
    local GoodbyeButton = self:AcquireExitButton();
    GoodbyeButton:SetButtonExitGossip();

    local contentHeight = firstObject:GetTop() - lastObject:GetBottom();
    self:SetScrollRange(contentHeight);

    self.numAvailableQuests = numAvailableQuests;

    return true
end

function DUIDialogBaseMixin:GetQuestFinishedDelay()
    if (self.numAvailableQuests and self.numAvailableQuests > 1) or QuestIsFromAreaTrigger() then
        return 0.5
    else
        return 0.03
    end
end

function DUIDialogBaseMixin:UpdateGossipQuests()
    if self.activeQuestButtons then
        local activeQuests = GetActiveQuests();

        for i, questInfo in ipairs(activeQuests) do
            questInfo.isOnQuest = true;
            questInfo.originalOrder = i;
        end

        tsort(activeQuests, SortFunc_PrioritizeCompleteQuest);

        local rebuildQuestInfo = true;

        for i, activeQuestButton in ipairs(self.activeQuestButtons) do
            if activeQuests[i] and (activeQuestButton.questID == activeQuests[i].questID) then
                activeQuestButton:SetQuestVisual(activeQuests[i], rebuildQuestInfo);
            end
        end
    end
end

function DUIDialogBaseMixin:HandleGossipConfirm(gossipID, warningText, cost)
    self.hasActiveGossipQuests = false;
    self.numAvailableQuests = 0;
    self.keepGossipHistory = false;
    self.requireGossipConfirm = true;

    self:ReleaseAllObjects();
    self:UseQuestLayout(false);

    local offsetY = 0;

    warningText = ThemeUtil:AdjustTextColor(warningText);
    offsetY = self:FormatParagraph(offsetY, warningText, addon.TTSFlags.Gossip);

    local lockDuration = CalulateLockDuration(cost);

    if cost and cost > 0 then
        offsetY = offsetY + PARAGRAPH_SPACING;
        local subheader = self:AcquireAndSetSubHeader(L["Costs"]);
        subheader:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", PADDING_H * FRAME_SIZE_MULTIPLIER, -offsetY);
        offsetY = Round(offsetY + subheader.size);

        local itemList = {
            {"SetRequiredMoney", cost, small = true}
        };

        offsetY = self:FormatRewards(offsetY, itemList);
    end

    local AcceptButton = self:AcquireAcceptButton(true);
    AcceptButton:SetButtonConfirmGossip(gossipID, lockDuration);

    local CancelButton = self:AcquireExitButton();
    CancelButton:SetButtonCancelConfirmGossip();

    self:SetScrollRange(offsetY);

    FadeFrame(self.ContentFrame, 0.35, 1, 0);
end

function DUIDialogBaseMixin:HideGossipConfirm()
    if self:IsShown() and self.requireGossipConfirm and self.handler == "HandleGossip" then
        self.requireGossipConfirm = false;
        self.keepGossipHistory = false;
        if API.IsInteractingWithGossip() then
            self:HandleGossip();
            FadeFrame(self.ContentFrame, 0.35, 1, 0);
        end
    end
end

function DUIDialogBaseMixin:HandleGossipEnterCode(gossipID)
    self.inputboxShown = true;
    self.InputBox:Show();
    self.InputBox:SetGossipID(gossipID);
    self.InputBox:SetFocus();
    FadeFrame(self.ContentFrame, 0.15, 0.25);
    FadeFrame(self.FrontFrame, 0.15, 0.25);
end

function DUIDialogBaseMixin:HideInputBox()
    if self.inputboxShown then
        self.InputBox:Hide();
        FadeFrame(self.ContentFrame, 0.15, 1);
        FadeFrame(self.FrontFrame, 0.15, 1);
    end
end

local function Predicate_ActiveChoiceButton(itemButton)
    return itemButton.type == "choice" and itemButton:IsShown()
end

function DUIDialogBaseMixin:IsChoosingReward()
    return self.chooseItems == true
end

function DUIDialogBaseMixin:SelectRewardChoice(choiceID, showTooltip)
    if not self.chooseItems then return end;    --Handled in Formatter when building reward choices

    local claimQuestReward;
    if INPUT_DEVICE_GAME_PAD then
        self.GamePadFocusIndicator:Hide();
        --Briefly paused in case the button becomes too sensitive and claim the reward by accident
        if not API.CheckActionThrottled("GamePadChooseQuestReward") then
            if choiceID == self.rewardChoiceID then
                claimQuestReward = true;
            end
        end
    end

    self.rewardChoiceID = choiceID;
    local CompleteButton = self:AcquireAcceptButton(true);
    CompleteButton:SetButtonCompleteQuest();

    if claimQuestReward and CompleteButton:IsEnabled() then
        CompleteButton:Click("LeftButton");
        TooltipFrame:HideTooltip();
    end

    local buttons = self.itemButtonPool:GetObjectsByPredicate(Predicate_ActiveChoiceButton);
    local selectedButton;
    for i, button in ipairs(buttons) do
        if button.index == choiceID then
            button:SetBackgroundTexture(1);
            FadeFrame(button, 0.15, 1);
            selectedButton = button;
        else
            button:SetBackgroundTexture(1);
            FadeFrame(button, 0.15, 0.25);
        end
        button:UpdateNameColor();
    end
    self.RewardSelection.BackTexture:Hide();

    if selectedButton and showTooltip then
        addon.RewardTooltipCode:OnEnter(selectedButton);
    end

    return true
end

function DUIDialogBaseMixin:HighlightRewardChoice(rewardChoiceButton)
    self.RewardSelection:Hide();
    self.RewardSelection:ClearAllPoints();
    self.GamePadFocusIndicator:Hide();

    if rewardChoiceButton and self.chooseItems then
        self.RewardSelection:SetPoint("TOPLEFT", rewardChoiceButton, "TOPLEFT", 0, 0);
        self.RewardSelection:SetPoint("BOTTOMRIGHT", rewardChoiceButton, "BOTTOMRIGHT", 0, 0);
        self.RewardSelection:SetParent(rewardChoiceButton);
        self.RewardSelection:SetFrameLevel(rewardChoiceButton:GetFrameLevel());
        self.RewardSelection.BackTexture:SetShown(self.rewardChoiceID == nil);
        self.RewardSelection:Show();

        self.GamePadFocusIndicator:ClearAllPoints();
        self.GamePadFocusIndicator:SetPoint("CENTER", self.RewardSelection, "LEFT", 0, 0);

        if INPUT_DEVICE_GAME_PAD then
            self:UpdateCompleteButton(rewardChoiceButton.index == self.rewardChoiceID);
        end
    end
end

function DUIDialogBaseMixin:FlashRewardChoices()
    local buttons = self.itemButtonPool:GetObjectsByPredicate(Predicate_ActiveChoiceButton);
    if buttons then
        for i, button in ipairs(buttons) do
            button:PlaySheen();
        end
    end
end

function DUIDialogBaseMixin:CycleRewardChoice(delta)
    if not self.chooseItems then return end;

    local buttons = self.itemButtonPool:GetObjectsByPredicate(Predicate_ActiveChoiceButton);
    if buttons then
        local numChoices = #buttons;    --GetNumQuestChoices
        local choiceID = self.rewardChoiceID or 0;
        choiceID = choiceID + delta;
        if choiceID > numChoices then
            choiceID = 1;
        elseif choiceID < 1 then
            choiceID = numChoices;
        end
        return self:SelectRewardChoice(choiceID, true);
    end
end

function DUIDialogBaseMixin:RequestItemUpgrade()
    if self.isRequestingItemLevel then return end;
    self.isRequestingItemLevel = true;

    After(0.33, function()
        self.isRequestingItemLevel = nil;
        local playAnimation = self:IsChoosingReward();
        self.itemButtonPool:ProcessActiveObjects(function(button)
            if button.isEquippable and button.objectType == "item" and button.type and button.index and API.IsRewardItemUpgrade(button.type, button.index) then
                button:ShowUpgradeIcon(playAnimation);
            end
        end);
    end);
end

function DUIDialogBaseMixin:RequestSellPrice(isRequery)
    if not GetDBBool("MarkHighestSellPrice") then return end;

    local numRewardChoices = GetNumQuestChoices() or 0;
    if numRewardChoices <= 1 then return end;

    local maxPrice = 0;
    local price, index;
    local anyZero;

    for i = 1, numRewardChoices do
        price = API.GetQuestChoiceSellPrice(i);

        if price == 0 then
            anyZero = true;
        end

        if price > maxPrice then
            maxPrice = price;
            index = i;
        end
    end

    if (index and anyZero) or (not index) then
        if not isRequery then
            After(0.8, function()
                self:RequestSellPrice(true);
            end);
        end
    else
        local buttons = self.itemButtonPool:GetObjectsByPredicate(Predicate_ActiveChoiceButton);
        if buttons then
            for i, button in ipairs(buttons) do
                if button.index == index then
                    local iconFrame = self.iconFramePool:Acquire();
                    iconFrame:SetHighestSellPrice();
                    iconFrame:SetParent(button);
                    iconFrame:SetPoint("CENTER", button.Icon, "TOPLEFT", 3, -3);
                    break
                end
            end
        end
    end
end


local ANIM_DURATION_SCROLL_EXPAND = 0.75;

local function AnimIntro_SimpleFadeIn_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local height = self.frameHeight;
    local alpha = 5*self.t;

    if alpha >= 1 then
        alpha = 1;
        self:SetScript("OnUpdate", nil);
        self.ContentFrame:SetClipsChildren(false);
    end

    self:SetHeight(height);
    self:SetAlpha(alpha);
end

local function AnimIntro_Unfold_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local height = Easing_Func(self.t, self.fromHeight, self.frameHeight, ANIM_DURATION_SCROLL_EXPAND);
    local alpha = 4*self.t;

    if alpha > 1 then
        alpha = 1;
    end

    if self.t >= ANIM_DURATION_SCROLL_EXPAND then
        height = self.frameHeight;
        self:SetScript("OnUpdate", nil);
        self.ContentFrame:SetClipsChildren(false);
    end

    self:SetHeight(height);
    self:SetAlpha(alpha);
end

local function AnimIntro_FlyIn_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local offsetX = Easing_Func(self.t, self.fromOffsetX, self.frameOffsetX, ANIM_DURATION_SCROLL_EXPAND);
    local alpha = 4*self.t;
    local height = self.frameHeight;

    if alpha > 1 then
        alpha = 1;
    end

    if self.t >= ANIM_DURATION_SCROLL_EXPAND then
        offsetX = self.frameOffsetX;
        self:SetScript("OnUpdate", nil);
        self.ContentFrame:SetClipsChildren(false);
    end

    self:SetPoint("CENTER", nil, "CENTER", offsetX, 0);
    self:SetHeight(height);
    self:SetAlpha(alpha);
end

local ActiveAnimIntro = AnimIntro_SimpleFadeIn_OnUpdate;


function DUIDialogBaseMixin:PlayIntroAnimation()
    self.fromHeight = 0.5 * self.frameHeight;
    self.fromOffsetX = self.frameOffsetX + ((self.frameOffsetX < 0 and -72) or 72);
    self.t = 0;
    self.ContentFrame:SetClipsChildren(true);
    self:SetScript("OnUpdate", ActiveAnimIntro);
end

local DialogHandlers = {
    ["GOSSIP_SHOW"] = "HandleGossip",
    ["QUEST_DETAIL"] = "HandleQuestDetail",         --See the details of an available quest
    ["QUEST_PROGRESS"] = "HandleQuestProgress",     --Show status of a taken quest. "Continue" button
    ["QUEST_COMPLETE"] = "HandleQuestComplete",     --Show "Complete Quest" button
    ["QUEST_GREETING"] = "HandleQuestGreeting",     --Similar to GOSSIP_SHOW
};

function DUIDialogBaseMixin:ShowUI(event, ...)
    if self.isGameLoading then
        self.deferredEvent = event;
        return
    end

    if IsPlayingCutscene() then
        --For case: triggering cutscene when accepting quest and the quest is immediately flagged as complete
        self:Hide();
        self:CloseDialogInteraction();
        return
    end

    local shouldShowUI;
    local handler = DialogHandlers[event];
    if handler then
        local playFadeIn = self.handler and self.handler ~= handler;    --Since 11.0.5? QUEST_DETAIL can fire repeatedly even though there is no real update
        self.handler = handler;
        self.handlerArgs = { ... };
        shouldShowUI = self[handler](self, playFadeIn);
    end

    if not shouldShowUI then
        self.handler = nil;
        self.handlerArgs = nil;
        return
    end

    if not self:IsShown() then
        CameraUtil:InitiateInteraction();
        self:PlayIntroAnimation();
        self:OnEvent(event);
    end

    self:Show();
    self.hasInteraction = true;

    TooltipFrame:Hide();

    CallbackRegistry:Trigger("DialogueUI.HandleEvent", event, self.questID);
end

function DUIDialogBaseMixin:HideUI(cancelPopupFirst, fromPressingKey)
    if not self:IsShown() then return end;

    if cancelPopupFirst and self.requireGossipConfirm then
        self:OnEvent("GOSSIP_CONFIRM_CANCEL");
        return
    end

    if fromPressingKey and self.questIsFromGossip and GetDBBool("EscapeToDeclineQuest") and (not InCombatLockdown()) then
        DeclineQuest();
        return
    end

    self:Hide();
end

function DUIDialogBaseMixin:OnShow()
    KeyboardControl:SetParentFrame(self);

    self:RegisterEvent("GOSSIP_SHOW");
    self:RegisterEvent("GOSSIP_CLOSED");
    self:RegisterEvent("GOSSIP_CONFIRM");
    self:RegisterEvent("GOSSIP_ENTER_CODE");
    self:RegisterEvent("QUEST_LOG_UPDATE");
    self:RegisterEvent("QUEST_FINISHED");
    self:RegisterEvent("QUEST_ACCEPTED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("LOADING_SCREEN_ENABLED");
    self:RegisterEvent("ADVENTURE_MAP_OPEN");

    if IS_MODERN_WOW then
        self:RegisterEvent("PLAYER_CHOICE_UPDATE");   --Watch TRAIT_SYSTEM_INTERACTION_STARTED
    end

    SharedVignette:TryShow();

    CallbackRegistry:Trigger("DialogueUI.Show");
end

function DUIDialogBaseMixin:CloseDialogInteraction()
    if self.interactionIsContinuing then
        self.interactionIsContinuing = nil;
        return
    end

    CloseQuest();
    CloseGossipInteraction();

    --Classic:
    --HideUI will cause ClassTrainerFrame to not processing events (Blizzard_TrainerUI/Blizzard_TrainerUI.lua#72)
end

function DUIDialogBaseMixin:OnHide()
    CameraUtil:Restore();

    self:CloseDialogInteraction();
    self.keepGossipHistory = false;
    self.selectedGossipIndex = nil;
    self.consumeGossipClose = nil;
    self.questIsFromGossip = nil;
    self.chooseItems = nil;
    self.handler = nil;
    self.handlerArgs = nil;
    self.questID = nil;
    self.hintText = nil;
    self.translatorEnabled = nil;
    self.contentHeight = 0;

    self:UnregisterEvent("GOSSIP_SHOW");
    self:UnregisterEvent("GOSSIP_CLOSED");
    self:UnregisterEvent("GOSSIP_CONFIRM");
    self:UnregisterEvent("GOSSIP_CONFIRM_CANCEL");
    self:UnregisterEvent("GOSSIP_ENTER_CODE");
    self:UnregisterEvent("QUEST_ITEM_UPDATE");
    self:UnregisterEvent("QUEST_LOG_UPDATE");
    self:UnregisterEvent("QUEST_FINISHED");
    self:UnregisterEvent("QUEST_ACCEPTED");
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:UnregisterEvent("LOADING_SCREEN_ENABLED");
    self:UnregisterEvent("ADVENTURE_MAP_OPEN");

    if IS_MODERN_WOW then
        self:UnregisterEvent("PLAYER_CHOICE_UPDATE");
    end

    self:ReleaseAllObjects();
    self:HideInputBox();

    SharedVignette:TryHide();
    TooltipFrame:Hide();

    CallbackRegistry:Trigger("DialogueUI.Hide");

    if self.acknowledgeAutoAcceptQuest then
        self.acknowledgeAutoAcceptQuest = nil;
        AcknowledgeAutoAcceptQuest();
    end

    if self.requireGossipConfirm ~= nil then
        self.requireGossipConfirm = nil;
        API.CloseGossipStaticPopups();
    end
end

function DUIDialogBaseMixin:OnMouseUp(button)
    if button == "RightButton" and GetDBBool("RightClickToCloseUI") and self:IsMouseMotionFocus() then
        self:Hide();
        --self:CloseDialogInteraction();
    end
end

function DUIDialogBaseMixin:OnMouseWheel(delta)
    self.ScrollFrame:OnMouseWheel(delta);
end

function DUIDialogBaseMixin:HighlightButton(optionButton)
    if optionButton and optionButton == self.highlightedButton then
        return true
    end

    self.ButtonHighlight:ClearAllPoints();

    if optionButton and optionButton:IsEnabled() and (optionButton.artID ~= 3) then -- artID = 3 (Hollow, auto accepted quest)
        optionButton:SetParentHighlightTexture(self.ButtonHighlight);
    else
        self.ButtonHighlight:Hide();
    end

    self.highlightedButton = optionButton;

    if optionButton and optionButton.gamepadIndex then
        self:SetGamePadFocusIndex(optionButton.gamepadIndex);
        self.GamePadFocusIndicator:ClearAllPoints();
        self.GamePadFocusIndicator:SetPoint("CENTER", optionButton, "LEFT", 0, 0);
        self.GamePadFocusIndicator:Show();
    else
        self.GamePadFocusIndicator:Hide();
    end
end

function DUIDialogBaseMixin:ClearButtonHighlight(optionButton)
    if self.highlightedButton == optionButton then
        self:HighlightButton(nil);
    end
end

function DUIDialogBaseMixin:UpdateRewards()
    if self.questLayout and self.handler then
        --New items might appear after "QUEST_ITEM_UPDATE"
        --self.itemButtonPool:CallActive("Refresh");

        if not self.rewardUpdator then
            self.rewardUpdator = CreateFrame("Frame", self);
            self.rewardUpdator:SetScript("OnHide", function(f)
                f:Hide();
            end);
        end

        local function UpdateRewards_OnUpdate(f, elapsed)
            f.t = f.t + elapsed;
            if f.t > 0.5 then
                f.t = nil;
                f:SetScript("OnUpdate", nil);
                if self.questLayout and self.handler then
                    self[self.handler](self);
                end
            end
        end

        self.rewardUpdator.t = 0;
        self.rewardUpdator:SetScript("OnUpdate", UpdateRewards_OnUpdate);
        self.rewardUpdator:Show();
    end
end

function DUIDialogBaseMixin:OnEvent(event, ...)
    if event == "QUEST_ITEM_UPDATE" then
        self:UpdateRewards();
    elseif event == "GOSSIP_SHOW" then
        self.keepGossipHistory = true;
    elseif event == "GOSSIP_CLOSED" then
        self.keepGossipHistory = false;
        self.selectedGossipIndex = nil;
    elseif event == "QUEST_ACCEPTED" then
        self:HandleQuestAccepted(...);
    elseif event == "QUEST_LOG_UPDATE" then
        if self.hasActiveGossipQuests then
            self.keepGossipHistory = false;
            self:UpdateGossipQuests();
        elseif self.handler == "HandleQuestGreeting" then
            self:HandleQuestGreeting();
        end
    elseif event == "QUEST_FINISHED" then
        self.keepGossipHistory = false;
    elseif event == "PLAYER_REGEN_DISABLED" then
        if self:IsShown() then
            CameraUtil:OnEnterCombatDuringInteraction();
        end
    elseif event == "GOSSIP_CONFIRM" then
        --CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
        local gossipID, text, cost = ...
        self:RegisterEvent("GOSSIP_CONFIRM_CANCEL");
        self:HandleGossipConfirm(gossipID, text, cost);
    elseif event == "GOSSIP_CONFIRM_CANCEL" then
        --CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
        self:UnregisterEvent(event);
        self:HideGossipConfirm();
    elseif event == "GOSSIP_ENTER_CODE" then
        --CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
        local gossipID = ...
        self:HandleGossipEnterCode(gossipID);
    elseif event == "LOADING_SCREEN_ENABLED" then
        self:HideUI();
    elseif event == "ADVENTURE_MAP_OPEN" then
        CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
    elseif event == "LOADING_SCREEN_DISABLED" then  --not reliable on the intial login
        self:UnregisterEvent(event);
        C_Timer.After(4, function()
            self.isGameLoading = nil;
            self:HandleInitialLoadingComplete();
        end);
    elseif event == "PLAYER_CHOICE_UPDATE" then
        --TWW: Show Weekly Quest Selection
        self:UnregisterEvent(event);
        self:CloseDialogInteraction();
        self:HideUI();
    end
end

function DUIDialogBaseMixin:SetConsumeGossipClose(state)
    --Event Sequence when selecting a quest from GossipFrame
    --1.GOSSIP_CLOSE
    --2.QUEST_DETAIL

    if state then
        if not self.consumeGossipClose then
            self.consumeGossipClose = true;
            After(0.8, function()
                self.consumeGossipClose = nil;
            end);
        end
    else
        self.consumeGossipClose = nil;
    end
end

function DUIDialogBaseMixin:MarkQuestIsFromGossip()
    --if the quest is from gossip, clicking Decline button will return user to previous dialog
    self.questIsFromGossip = true;
end

function DUIDialogBaseMixin:IsGossipCloseConsumed()
    if self.consumeGossipClose then
        self.consumeGossipClose = nil;
        return true
    else
        return false
    end
end

function DUIDialogBaseMixin:ScrollDownOrAcceptQuest(fromMouseClick)
    if SCROLLDOWN_THEN_ACCEPT_QUEST and not fromMouseClick then
        if not self:IsScrollAtBottom() then
            self:ScrollToBottom();
            local noFeedback = true;
            return noFeedback
        end
    end

    self:SetAcceptCurrentQuest();    --For showing "Quest Accepted" banner

    if self.acknowledgeAutoAcceptQuest then
        self.acknowledgeAutoAcceptQuest = nil;
        AcknowledgeAutoAcceptQuest();
    else
        AcceptQuest();
    end
end

function DUIDialogBaseMixin:SetHintText(hintText)
    --After clicking "Show Answer" button
    --We add the answer to the next GOSSIP_SHOW
    self.hintText = hintText;
end

do  --Clipboard
    local strjoin = strjoin;
    local function JoinText(...)
        return strjoin("\n", ...);
    end

    local function ConcatenateQuestTable(quests)
        local title, questID, text;
        local str = "\n";
        local idFormat = "[Quest: %d] %s";

        for i, questInfo in ipairs(quests) do
            text = idFormat:format(questInfo.questID, questInfo.title);
            str = JoinText(str, text);
        end

        return str
    end

    local function ConcatenateOptionTable(options)
        local title, questID, text, name;
        local str = "\n";
        local idFormat = "[OptionID: %d] %s";

        for i, data in ipairs(options) do
            name = data.name;
            if data.flags == 1 then
                name = "(Quest) "..name;
            end
            text = idFormat:format(data.gossipOptionID, name);
            str = JoinText(str, text);
        end

        return str
    end

    local function ConcatenateQuestIDTitle(previousText)
        local questID = GetQuestID();
        local title = GetQuestTitle();
        local idFormat = "[Quest: %d] %s";
        if questID and questID ~= 0 then
            local text = idFormat:format(questID, title);
            if previousText then
                previousText = JoinText(previousText, text);
            else
                previousText = text;
            end
        end

        return previousText
    end

    local function ConcatenateQuestItems(sourceType, numItems)
        local GetQuestItemInfo = GetQuestItemInfo;
        local str = "";
        local idFormat = "[ItemID: %d] %s";

        for index = 1, numItems do
            local hidden = IsQuestItemHidden(index);
            if hidden == 0 then
                local name, texture, count, quality, isUsable, itemID = GetQuestItemInfo(sourceType, index);
                local text = idFormat:format(itemID, name);
                if count and count > 1 then
                    text = text.." x"..count;
                end
                str = JoinText(str, text);
            end
        end

        return str
    end

    local function ConcatenateCurrencies(sourceType, numCurrencies)
        local GetQuestCurrency = API.GetQuestCurrency;
        local str = "";
        local idFormat = "[CurrencyID: %d] %s";

        for index = 1, numCurrencies do
            local currencyInfo = GetQuestCurrency(sourceType, index);
            local name, amount, currencyID = currencyInfo.name, currencyInfo.duiDisplayedAmount, currencyInfo.currencyID;
            local text = idFormat:format(currencyID, name);
            if amount and amount > 1 then
                text = text.." x"..amount;
            end
            str = JoinText(str, text);
        end

        return str
    end

    local function ConcatenateRewards(previousText)
        local anyRewards;

        local function AddItemText(itemButton)
            local text = itemButton:GetClipboardOutput();
            if text then
                if not anyRewards then
                    anyRewards = true;
                    previousText = JoinText(previousText, " ", L["Rewards"], " ");
                end
                previousText = JoinText(previousText, text);
            end
        end
        MainFrame.itemButtonPool:ProcessActiveObjects(AddItemText);
        MainFrame.smallItemButtonPool:ProcessActiveObjects(AddItemText);
        return previousText
    end

    function DUIDialogBaseMixin:GetContentForTTS()
        local content;

        if API.GetQuestTTSContentExternal then
            content = API.GetQuestTTSContentExternal();
        end

        if not content then
            content = {};

            if self:IsTranslationAvailable() and GetDBBool("TTSReadTranslation") and addon.IsTranslatorEnabled() then
                local body, objective;
                local text;
                local flags = addon.TTSFlags;
                for _, fs in self.fontStringPool:EnumerateActive() do
                    if fs.isTranslation then
                        text = fs:GetText();
                        if text and text ~= "" then
                            if fs.ttsFlag == flags.QuestObjective then
                                if objective then
                                    objective = objective.."\n"..text;
                                else
                                    objective = text;
                                end
                            else
                                if body then
                                    body = body.."\n"..text;
                                else
                                    body = text;
                                end
                            end
                        end
                    end
                end
                content.body = body;
                content.objective = objective;
            else
                local GetGossipText = API.GetGossipText;
                local GetQuestText = API.GetQuestText;

                local questID = GetQuestID();
                if questID and questID ~= 0 then
                    content.title = GetQuestTitle();
                end

                if self.handler == "HandleGossip" then
                    content.body = GetGossipText();

                elseif self.handler == "HandleQuestDetail" then
                    content.body = GetQuestText("Detail");

                    local objective = GetObjectiveText();
                    if objective and objective ~= "" then
                        content.objective = JoinText(L["Quest Objectives"], "", objective);
                    end

                elseif self.handler == "HandleQuestProgress" then
                    content.body = GetQuestText("Progress");

                elseif self.handler == "HandleQuestComplete" then
                    content.body = GetQuestText("Complete");

                elseif self.handler == "HandleQuestGreeting" then
                    content.body = GetQuestText("Greeting");

                end
            end
        end

        if content then
            local npcName, npcID = API.GetCurrentNPCInfo();
            if npcName and npcID then
                content.speaker = npcName;
            end
        end

        return content
    end

    function DUIDialogBaseMixin:GetContentForClipboard()
        local str;

        local GetGossipText = API.GetGossipText;
        local GetQuestText = API.GetQuestText;

        local npcName, npcID = API.GetCurrentNPCInfo();
        if npcName and npcID then
            local idFormat = "[NPC: %d] %s";
            str = idFormat:format(npcID, npcName);
        end

        if self.handler == "HandleGossip" then
            local gossipText = GetGossipText();

            if str then
                str = JoinText(str, gossipText);
            else
                str = gossipText;
            end

            local availableQuests = GetAvailableQuests();
            local activeQuests = GetActiveQuests();
            local options = GetOptions();
            tsort(options, SortFunc_GossipOrder);

            if #availableQuests > 0 then
                str = str..ConcatenateQuestTable(availableQuests);
            end

            if #activeQuests > 0 then
                str = str..ConcatenateQuestTable(activeQuests);
            end

            if #options > 0 then
                str = str..ConcatenateOptionTable(options);
            end

        elseif self.handler == "HandleQuestDetail" then
            str = ConcatenateQuestIDTitle(str);
            str = JoinText(str, "", GetQuestText("Detail"));

            local objective = GetObjectiveText();
            if objective and objective ~= "" then
                str = JoinText(str, "", L["Quest Objectives"], "", objective);
            end

            str = ConcatenateRewards(str);

        elseif self.handler == "HandleQuestProgress" then
            str = ConcatenateQuestIDTitle(str);
            str = JoinText(str, "", GetQuestText("Progress"));

            local numRequiredItems = GetNumQuestItems();
            local numRequiredCurrencies = GetNumQuestCurrencies();
            local numRequiredMoney = GetQuestMoneyToGet();

            if numRequiredItems > 0 or numRequiredMoney > 0 or numRequiredCurrencies > 0 then
                str = JoinText(str, "", L["Requirements"]);

                if numRequiredMoney > 0 then
                    local colorized = false;
                    local noAbbreviation = true;
                    local moneyText = API.GenerateMoneyText(numRequiredMoney, colorized, noAbbreviation);
                    str = JoinText(str, moneyText);
                end

                if numRequiredItems > 0 then
                    str = JoinText(str, ConcatenateQuestItems("required", numRequiredItems));
                end

                if numRequiredCurrencies > 0 then
                    str = JoinText(str, ConcatenateCurrencies("required", numRequiredCurrencies));
                end
            end

        elseif self.handler == "HandleQuestComplete" then
            str = ConcatenateQuestIDTitle(str);
            str = JoinText(str, "", GetQuestText("Complete"));
            str = ConcatenateRewards(str);

        elseif self.handler == "HandleQuestGreeting" then
            str = ConcatenateQuestIDTitle(str);
            str = JoinText(str, "", GetQuestText("Greeting"));

            local numAvailableQuests = GetNumAvailableQuests();
            local availableQuests = {};
            for i = 1, numAvailableQuests do
                local title = GetAvailableTitle(i);
                local isTrivial, frequency, isRepeatable, isLegendary, questID = GetAvailableQuestInfo(i);
                local questInfo = {
                    title = title,
                    questID = questID,
                };
                tinsert(availableQuests, questInfo);
            end

            if numAvailableQuests > 0 then
                str = str..ConcatenateQuestTable(availableQuests);
            end

            local numActiveQuests = GetNumActiveQuests();
            local activeQuests = {};
            for i = 1, numActiveQuests do
                local title, isComplete = GetActiveTitle(i);
                local questID = GetActiveQuestID(i);
                local questInfo = {
                    title = title,
                    questID = questID,
                };
                tinsert(activeQuests, questInfo);
            end

            if numActiveQuests > 0 then
                str = str..ConcatenateQuestTable(activeQuests);
            end
        end

        return str
    end

    function DUIDialogBaseMixin:SendContentToClipboard()
        local str = self:GetContentForClipboard();

        if str then
            if StripHyperlinks then
                --We remove the atlas/texture since it messes up spacing
                local maintainColor = true;
                local maintainBrackets = true;
                str = StripHyperlinks(str, true, true);
            end
            addon.Clipboard:ShowContent(str, self.CopyTextButton);
        end
    end
end

do  --Quest Rewards

    local ITEM_BUTTON_SPACING = 8;
    local GridLayout = API.CreateGridLayout();
    GridLayout:SetGrid(4, 2);
    GridLayout:SetSpacing(8);

    local GetQuestItemInfoLootType = API.GetQuestItemInfoLootType;

    function DUIDialogBaseMixin:FormatRewards(offsetY, rewardList)
        -- 4 x 2 Grid Layout:
        -- ItemButton: 2x2
        -- SmallItemButton: 1x1
        local baseOffsetX = PADDING_H * FRAME_SIZE_MULTIPLIER;
        local chooseItems = self.chooseItems;

        local itemButtonWidth = self.halfFrameWidth;
        local itemButtonHeight = 36;
        local gridWidth = self.quarterFrameWidth;
        local smallItemButtonHeight = 15;
        local sizeX, sizeY;

        GridLayout:ResetGrid();
        GridLayout:SetGridSize(self.quarterFrameWidth, smallItemButtonHeight);

        for i, data in ipairs(rewardList) do
            local object;
            local actualSizeX;

            if i == 1 and data.isRewardChoices then
                --One choice reward has been processed
                local sourceType = "choice";
                local onlyChoice = false;
                local numChoices = data.numChoices;
                local offsetX = 0;
                local backgroundID;

                sizeX = (INPUT_DEVICE_GAME_PAD and 4) or 2;

                local isChoosingReward = data.chooseItems;

                if isChoosingReward then
                    backgroundID = 2;
                    offsetY = self:InsertText(offsetY, REWARD_CHOOSE);		--Choose
                else
                    backgroundID = 1;
                    offsetY = self:InsertText(offsetY, REWARD_CHOICES);		--Will be able to choose
                end

                offsetY = offsetY + ITEM_BUTTON_SPACING;
                local fromOffsetY = offsetY;

                for orderIndex = 1, numChoices do
                    object = self.itemButtonPool:Acquire();
                    object:SetBaseGridSize(sizeX, gridWidth, ITEM_BUTTON_SPACING);
                    object:SetBackgroundTexture(backgroundID);

                    local lootType = GetQuestItemInfoLootType(sourceType, orderIndex);
                    if (lootType == 0) then -- LOOT_LIST_ITEM
                        object:SetRewardChoiceItem(orderIndex, onlyChoice);
                    elseif (lootType == 1) then -- LOOT_LIST_CURRENCY
                        object:SetRewardChoiceCurrency(orderIndex, onlyChoice);
                    end

                    object:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", baseOffsetX + offsetX, -offsetY);
                    offsetX = offsetX + 2*gridWidth + 2*ITEM_BUTTON_SPACING;

                    if INPUT_DEVICE_GAME_PAD or orderIndex % 2 == 0 then
                        offsetY = offsetY + itemButtonHeight + ITEM_BUTTON_SPACING;
                        offsetX = 0;
                    end

                    if chooseItems then
                        self:IndexGamePadObject(object);
                    end
                end

                local numRows = (INPUT_DEVICE_GAME_PAD and numChoices) or math.ceil(numChoices / 2);
                offsetY = fromOffsetY + (itemButtonHeight + ITEM_BUTTON_SPACING) * numRows - ITEM_BUTTON_SPACING;
                offsetY = offsetY + PARAGRAPH_SPACING;

                if #rewardList > 1 then
                    offsetY = self:InsertText(offsetY, REWARD_ITEMS);	--You will also receive
                    offsetY = offsetY + ITEM_BUTTON_SPACING;
                end

                if isChoosingReward then
                    self:RequestSellPrice();
                end
            else
                if data.header then
                    GridLayout:FlagPreviousRowFull();
                    object = self:AcquireLeftFontString();
                    object:SetText(data.header);
                    actualSizeX = 4;
                    sizeY = 1;
                    GridLayout:PlaceObject(object, actualSizeX, sizeY, self.ContentFrame, baseOffsetX, -offsetY);
                end

                local method = data[1];
                if method then
                    if data.small then
                        sizeX = 1;
                        sizeY = 1;
                        object = self.smallItemButtonPool:Acquire();
                    else
                        sizeX = 2;
                        sizeY = 2;
                        object = self.itemButtonPool:Acquire();
                    end

                    object:SetBaseGridSize(sizeX, gridWidth, ITEM_BUTTON_SPACING);
                    object[method](object, data[2], data[3], data[4], data[5]);
                    actualSizeX = object:GetActualGridTaken() or sizeX;

                    GridLayout:PlaceObject(object, actualSizeX, sizeY, self.ContentFrame, baseOffsetX, -offsetY);
                end
            end
        end

        local width, height = GridLayout:GetWrappedSize();

        return offsetY + height
    end
end

do
    --Clipboard
    local CopyTextButton;

    local function CopyTextButton_OnClick(self)
        if addon.Clipboard:CloseIfFromSameSender(self) then
            return
        end
        MainFrame:SendContentToClipboard();
    end

    local function Settings_ShowCopyTextButton(dbValue)
        if dbValue == true then
            if not CopyTextButton then
                local themeID = 1;  --Brown
                CopyTextButton = addon.CreateCopyTextButton(MainFrame, CopyTextButton_OnClick, themeID);
                CopyTextButton:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -8, -8);
                MainFrame.CopyTextButton = CopyTextButton;
                --CopyTextButton.Icon:SetSize(18, 18);
            end
            CopyTextButton:Show();
            CopyTextButton:SetTheme(ThemeUtil:GetThemeID());
        else
            if CopyTextButton then
                CopyTextButton:Hide();
            end
        end
        MainFrame:LayoutTopWidgets();
    end
    CallbackRegistry:Register("SettingChanged.ShowCopyTextButton", Settings_ShowCopyTextButton);


    local function Settings_ScrollDownThenAcceptQuest(dbValue)
        SCROLLDOWN_THEN_ACCEPT_QUEST = dbValue == true;
    end
    CallbackRegistry:Register("SettingChanged.ScrollDownThenAcceptQuest", Settings_ScrollDownThenAcceptQuest);

    local function Settings_CameraMovement(dbValue)
        if dbValue == 0 then
            ActiveAnimIntro = AnimIntro_SimpleFadeIn_OnUpdate;
        elseif dbValue == 1 then
            ActiveAnimIntro = AnimIntro_Unfold_OnUpdate;
        elseif dbValue == 2 then
            ActiveAnimIntro = AnimIntro_FlyIn_OnUpdate;
        end
    end
    CallbackRegistry:Register("SettingChanged.CameraMovement", Settings_CameraMovement);
end

do  --GamePad/Controller
    function DUIDialogBaseMixin:UpdateScrollFrameBound()
        self.scrollFrameTop = self.ScrollFrame:GetTop();
        self.scrollFrameBottom = self.ScrollFrame:GetBottom();
    end

    function DUIDialogBaseMixin:ResetGamePadObjects()
        self.gamepadMaxIndex = 0;
        self.gamepadFocusIndex = nil;
        self.gamepadFocus = nil;
        self.gamepadObjects = {};
    end

    function DUIDialogBaseMixin:IndexGamePadObject(object)
        self.gamepadMaxIndex = self.gamepadMaxIndex + 1;
        self.gamepadObjects[self.gamepadMaxIndex] = object;
        object.gamepadIndex = self.gamepadMaxIndex;
    end

    function DUIDialogBaseMixin:ClearGamePadFocus()
        if self.gamepadFocus then
            self.gamepadFocus:OnLeave();
            self.gamepadFocus = nil;
        end
    end

    function DUIDialogBaseMixin:SetGamePadFocusIndex(index)
        self.gamepadFocusIndex = index;
    end

    function DUIDialogBaseMixin:FocusObjectByDelta(delta)
        local maxIndex = self.gamepadMaxIndex or 0;
        local index = self.gamepadFocusIndex;

        if not index then
            index = 0;
        end

        if delta < 0 and index < maxIndex then
            index = index + 1;
        elseif delta > 0 and index > 1 then
            index = index - 1;
        elseif index == 0 then
            index = maxIndex;
        else
            return
        end

        self:ClearGamePadFocus();

        self.gamepadFocusIndex = index;
        self.gamepadFocus = self.gamepadObjects[index];

        if self.gamepadFocus then
            self:UpdateScrollFrameBound();

            self.gamepadFocus:OnEnter();
            local buttonHeight = self.gamepadFocus:GetHeight();
            local threshold = 2 * buttonHeight - 4;
            if delta > 0 then
                local top = self.gamepadFocus:GetTop();
                if top + threshold >= self.scrollFrameTop then
                    self:ScrollBy(-3*buttonHeight);
                end
            else
                local bottom = self.gamepadFocus:GetBottom();
                if bottom - threshold <= self.scrollFrameBottom then
                    self:ScrollBy(3*buttonHeight);
                end
            end
            return true
        end
    end

    function DUIDialogBaseMixin:FocusNextObject()
        if self:FocusObjectByDelta(-1) then
            return
        end

        if self:IsScrollable() then
            self:ScrollBy(192);
        end
    end

    function DUIDialogBaseMixin:FocusPreviousObject()
        if self:FocusObjectByDelta(1) then
            return
        end

        if self:IsScrollable() then
            self:ScrollBy(-192);
        end
    end

    function DUIDialogBaseMixin:ClickFocusedObject()
        if self.gamepadFocus then
            self.gamepadFocus:OnClick("GamePad");
            return true
        else
            --Select the next object widthout clicking it if we don't have a focus (usually when starting a fresh interaction)
            self:FocusNextObject();
            if self.gamepadFocus then
                if GetDBBool("GamePadClickFirstObject") then
                    self.gamepadFocus:OnClick("GamePad");
                end
                return true
            end
        end
        return false
    end

    function DUIDialogBaseMixin:UpdateCompleteButton(highlightedButtonSelected)
        local button = self.AcceptButton;
        local hotkey = button.HotkeyFrame;
        if not hotkey then return end;

        if highlightedButtonSelected then
            hotkey:Show();
            button.hasHotkey = true;
            button:Layout(true);
        else
            hotkey:Hide();
            button.hasHotkey = false;
            button:Layout(true);
        end

        self.GamePadFocusIndicator:SetShown(not highlightedButtonSelected);
    end
end

do  --TTS
    local TTSButton;

    local function Settings_TTSEnabled(dbValue)
        if dbValue == true then
            if not TTSButton then
                local themeID = 1;
                TTSButton = addon.CreateTTSButton(MainFrame, themeID);
                TTSButton:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 8, -8);
                TTSButton.system = "dialogue";
                MainFrame.TTSButton = TTSButton;
            end
            TTSButton:Show();
            TTSButton:SetTheme(ThemeUtil:GetThemeID());
        else
            if TTSButton then
                TTSButton:Hide();
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.TTSEnabled", Settings_TTSEnabled);


    function DUIDialogBaseMixin:GetTTSTextFromFontStrings()
        local text, str, title;

        for _, fs in self.fontStringPool:EnumerateActive() do
            if fs.ttsFlag then
                text = fs:GetText();
                if text and text ~= "" then
                    if str then
                        str = str.."\n"..text;
                    else
                        str = text;
                    end
                end
            end
        end

        if self.questLayout then
            title = self.FrontFrame.Header.Title:GetText();
        end

        return str, title
    end
end

do  --Vignette
    SharedVignette:SetFrameStrata("BACKGROUND");
    SharedVignette:SetFixedFrameStrata(true);
    SharedVignette:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -1, 1);
    SharedVignette:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 1, -1);
    SharedVignette:Hide();
    SharedVignette:SetAlpha(0);

    SharedVignette.Texture = SharedVignette:CreateTexture(nil, "BACKGROUND");
    SharedVignette.Texture:SetAllPoints(true);
    SharedVignette.Texture:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/ScreenVignette.png");

    SharedVignette.owners = {};

    function SharedVignette:AddOwner(owner)
        tinsert(self.owners, owner);
    end

    function SharedVignette:IsInUse()
        for _, owner in ipairs(self.owners) do
            if owner:IsShown() then
               return true
            end
        end
        return false
    end

    function SharedVignette:OnUpdate_FadeIn(elapsed)
        self.alpha = self.alpha + 1.35 * elapsed;
        if self.alpha >= 1 then
            self.alpha = 1;
            self:SetScript("OnUpdate", nil);
        end
        self:SetAlpha(self.alpha);
    end

    function SharedVignette:OnUpdate_FadeOut(elapsed)
        self.alpha = self.alpha - 2 * elapsed;
        if self.alpha <= 0 then
            self.alpha = 0;
            self:SetScript("OnUpdate", nil);
            self:Hide();
        end
        self:SetAlpha(self.alpha);
    end

    function SharedVignette:TryShow()
        self:Show();
        self.alpha = self:GetAlpha();
        if self.alpha < 1 then
            self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
        else
            self:SetScript("OnUpdate", nil);
        end
    end

    function SharedVignette:TryHide()
        if self:IsShown() and not self:IsInUse() then
            self.alpha = self:GetAlpha();
            if self.alpha > 0 then
                self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
            else
                self:SetScript("OnUpdate", nil);
            end
        end
    end
end

do  --Generic Settings Registry
    function DUIDialogBaseMixin:OnSettingsChanged()
        if self:IsVisible() and self.handler then
            if not self.settingsDirty then
                self.settingsDirty = true;
                After(0, function()
                    self.settingsDirty = nil;
                    if self.handler then
                        self.keepGossipHistory = false;
                        self[self.handler](self);
                    end
                end);
            end
        end
    end

    local function OnFontSizeChanged(baseFontSize, fontSizeID)
        local f = MainFrame;

        if f.hotkeyFramePool then
            local method = "UpdateBaseHeight";
            f.hotkeyFramePool:CallAllObjects(method);
            f.GamePadFocusIndicator:UpdateBaseHeight();
        end

        if f.optionButtonPool then
            local method = "OnFontSizeChanged";
            f.optionButtonPool:CallAllObjects(method);
        end

        if f.AcceptButton.HotkeyFrame then
            f.AcceptButton.HotkeyFrame:UpdateBaseHeight();
        end

        if f.ExitButton.HotkeyFrame then
            f.ExitButton.HotkeyFrame:UpdateBaseHeight();
        end

        FONT_SIZE = baseFontSize;
        TEXT_SPACING = 0.35 * FONT_SIZE;                  --Recommended Line Height: 1.2 - 1.5
        PARAGRAPH_SPACING = 4 * TEXT_SPACING;             --4 * TEXT_SPACING
        PARAGRAPH_BUTTON_SPACING = 2 * FONT_SIZE;         --Font Size * 2

        f:OnSettingsChanged();

        CallbackRegistry:Trigger("TextSpacingChanged", TEXT_SPACING, PARAGRAPH_SPACING, FONT_SIZE);
    end
    CallbackRegistry:Register("FontSizeChanged", OnFontSizeChanged);

    local function PostFontSizeChanged()
        --There is delay before footer button height changed
        After(0, function()
            MainFrame:UpdateFrameSize();
            MainFrame:OnSettingsChanged();
        end);
    end
    CallbackRegistry:Register("PostFontSizeChanged", PostFontSizeChanged);

    local FrameSizeIndexScale = {
        --Ceil: 1/0.618
        [0] = 0.9,
        [1] = 1.0,
        [2] = 1.1,
        [3] = 1.25,
        [4] = 1.4,
    };

    local function Settings_FrameOrientation()
        MainFrame:UpdateFrameBaseOffset();
        if addon.SettingsUI:IsShown() then
            addon.SettingsUI:MoveToBestPosition();
        end
    end
    CallbackRegistry:Register("SettingChanged.FrameOrientation", Settings_FrameOrientation);

    local function Settings_FrameSize(dbValue)
        --1: 1.0, 2: 1.1, 3:1.25

        if GetDBBool("MobileDeviceMode") then
            dbValue = 4;
        end

        local newScale = dbValue and FrameSizeIndexScale[dbValue];

        if newScale then
            FRAME_SIZE_MULTIPLIER = newScale;

            if dbValue == 0 then
                FRAME_OFFSET_RATIO = 4/5;
            else
                FRAME_OFFSET_RATIO = 3/4;
            end

            MainFrame:UpdateFrameSize();
            MainFrame:OnSettingsChanged();
        end
    end
    CallbackRegistry:Register("SettingChanged.FrameSize", Settings_FrameSize);

    local function Settings_HideUI(dbValue, useInput)
        ExperienceBar:SetShown(dbValue == true);
    end
    CallbackRegistry:Register("SettingChanged.HideUI", Settings_HideUI);

    local function Settings_UseRoleplayName(dbValue)
        if dbValue == true then
            GetQuestText = API.GetModifiedQuestText;
            GetGossipText = API.GetModifiedGossipText;
        else
            GetQuestText = API.GetQuestText;
            GetGossipText = API.GetGossipText;
        end
        MainFrame:OnSettingsChanged();
    end
    CallbackRegistry:Register("SettingChanged.UseRoleplayName", Settings_UseRoleplayName);

    local function GenericOnSettingsChanged(dbValue)
        MainFrame:OnSettingsChanged();
    end
    CallbackRegistry:Register("SettingChanged.MarkHighestSellPrice", GenericOnSettingsChanged);
    CallbackRegistry:Register("SettingChanged.ShowNPCNameOnPage", GenericOnSettingsChanged);
    CallbackRegistry:Register("SettingChanged.ForceGossip", GenericOnSettingsChanged);
    CallbackRegistry:Register("SettingChanged.AutoSelectGossip", GenericOnSettingsChanged);
    CallbackRegistry:Register("SettingChanged.ShowDialogHint", GenericOnSettingsChanged);
    CallbackRegistry:Register("SettingChanged.DisableHotkeyForTeleport", GenericOnSettingsChanged);
    CallbackRegistry:Register("CustomBindingChanged", GenericOnSettingsChanged);


    local function SettingsUI_Show()
        SETTINGS_UI_VISIBLE = true;
    end
    CallbackRegistry:Register("SettingsUI.Show", SettingsUI_Show);

    local function SettingsUI_Hide()
        SETTINGS_UI_VISIBLE = false;
    end
    CallbackRegistry:Register("SettingsUI.Hide", SettingsUI_Hide);


    local function UpdateMainOptionButtonHotkey(b, key)
        if b and b.HotkeyFrame then
            b.HotkeyFrame.key = nil;
            local keyShown = b.HotkeyFrame:IsShown();
            b.HotkeyFrame:SetKey(key);
            if keyShown then
                b:Layout(true);
            else
                b.HotkeyFrame:Hide();
            end
        end
    end

    local function PostInputDeviceChanged(dbValue)
        INPUT_DEVICE_GAME_PAD = dbValue ~= 1;
        MainFrame:OnSettingsChanged();

        UpdateMainOptionButtonHotkey(MainFrame.AcceptButton, "PRIMARY");
        UpdateMainOptionButtonHotkey(MainFrame.ExitButton, "Esc");

        if INPUT_DEVICE_GAME_PAD then
            MainFrame.GamePadFocusIndicator:SetKey("PRIMARY");
        else
            MainFrame.GamePadFocusIndicator:ClearKey();
        end
    end
    CallbackRegistry:Register("PostInputDeviceChanged", PostInputDeviceChanged);


    CallbackRegistry:Register("SettingChanged.DisableUIMotion", function(dbValue)
        if dbValue then
            Easing_Func = addon.EasingFunctions.none;
        else
            Easing_Func = addon.EasingFunctions.outSine;
        end
    end);
end

do  --Translator Button
    function DUIDialogBaseMixin:ShowTranslatorButton(state)
        if state then
            if not self.TranslatorButton then
                self.TranslatorButton = addon.CreateTranslatorButton(MainFrame);
            end
            self.TranslatorButton:Show();
            self.translatorEnabled = true;
        else
            if self.TranslatorButton then
                self.TranslatorButton:Hide();
            end
            self.translatorEnabled = false;
        end
        self:LayoutTopWidgets();
    end

    function DUIDialogBaseMixin:IsTranslationAvailable()
        return self.translatorEnabled
    end

    function DUIDialogBaseMixin:LayoutTopWidgets()
        local widget1, widget2;

        if self.CopyTextButton and self.CopyTextButton:IsShown() then
            widget1 = self.CopyTextButton;
        end

        if self.TranslatorButton and self.TranslatorButton:IsShown() then
            if widget1 then
                widget2 = self.TranslatorButton;
            else
                widget1 = self.TranslatorButton;
            end
        end

        if widget1 then
            widget1:ClearAllPoints();
            widget1:SetPoint("TOPRIGHT", self, "TOPRIGHT", -8, -8);
            if widget2 then
                widget2:ClearAllPoints();
                widget2:SetPoint("RIGHT", widget1, "LEFT", -4, 0);
            end
        end
    end
end