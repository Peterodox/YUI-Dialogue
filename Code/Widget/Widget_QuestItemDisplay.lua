local _, addon = ...

local L = addon.L;
local API = addon.API;
local CallbackRegistry = addon.CallbackRegistry;
local C_TooltipInfo = addon.TooltipAPI;
local ThemeUtil = addon.ThemeUtil;
local WidgetManager = addon.WidgetManager;
local match = string.match;
local GetNumLetters = strlenutf8 or string.len;
local Round = API.Round;
local IsQuestLoreItem = API.IsQuestLoreItem;
local GetBagQuestItemInfo = API.GetBagQuestItemInfo;
local After = C_Timer.After;

local MerchantFrame = MerchantFrame;

-- User Settings
local IGNORE_SEEN_ITEM = false;
local DBKEY_POSITION = "QuestItemDisplayPosition";
local WIDGET_NAME = L["Quest Item Display"];
------------------

local MAX_TEXT_WIDTH = 224; --256 when font size >12
local TEXT_SPACING = 2;
local ICON_SIZE = 32;
local PADDING_OUTER = 12;    --To boundary
local PADDING_TEXT_BUTTON_V = 4;
local PADDING_TEXT_BUTTON_H = 8;
local GAP_TEXT_ICON = 8;
local GAP_TITLE_DESC = 4;
local CLOSE_BUTTON_SIZE = 34;
local QUEUE_MARKER_SIZE = 17;
local READING_SPEED_LETTER = 180 * 5;   --WPM * avg. word length
local AUTOHIDE_DELAY_MIN = 5;
local REQUERY_DELAY = 0.5;              --Increased to 1.0 on Classic

if not addon.IsToCVersionEqualOrNewerThan(110000) then
    REQUERY_DELAY = 1.0;
end

local SEEN_ITEMS_SESSION = {};  --Items seen in this game session
local SEEN_ITEMS_ALL = {};      --Items discovered by any of the characters
local ONE_TIME_ITEM = {};       --Some quest items drop repeatedly. We only show it once regardless of IGNORE_SEEN_ITEM choice

local READABLE_ITEM = ITEM_CAN_BE_READ or "<This item can be read>";
local START_QUEST_ITEM = ITEM_STARTS_QUEST or "This Item Begins a Quest";

local QuestItemDisplay = WidgetManager:CreateWidget(DBKEY_POSITION, WIDGET_NAME);
WidgetManager:AddLootMessageProcessor(QuestItemDisplay, "ItemID");
QuestItemDisplay:Hide();
QuestItemDisplay.isChainable = true;
addon.QuestItemDisplay = QuestItemDisplay;

function QuestItemDisplay:Init()
    self.Init = nil;

    self:SetSize(8, 8);
    self.queue = {};

    local bg = self:CreateTexture(nil, "BACKGROUND");
    self.Background = bg;
    local margin = 24;
    bg:SetTextureSliceMargins(margin, margin, margin, margin);
    bg:SetTextureSliceMode(1);
    bg:SetAllPoints(true);
    bg:SetTexCoord(0.25, 0.5, 0.25, 0.5);

    --Workaround for TextureSlice change in 10.2.7
    local bgShadowContainer = CreateFrame("Frame", nil, self);
    if bgShadowContainer.SetUsingParentLevel then
        bgShadowContainer:SetUsingParentLevel(true);
    else  --For Cata 4.4.0
        local function UpdateFrameLevel()
            bgShadowContainer:SetFrameLevel(self:GetFrameLevel());
        end
        bgShadowContainer:SetScript("OnShow", UpdateFrameLevel);
        UpdateFrameLevel();
    end
    bgShadowContainer:SetAllPoints(true);
    local bgShadow = bgShadowContainer:CreateTexture(nil, "BACKGROUND", nil, -1);
    self.BackgroundShadow = bgShadowContainer;
    self.BackgroundShadow.Texture = bgShadow;
    local margin = 24;
    bgShadow:SetTextureSliceMargins(margin, margin, margin, margin);
    bgShadow:SetTextureSliceMode(0);
    bgShadow:SetAllPoints(true);
    bgShadow:SetTexCoord(0.515625, 0.765625, 0.25, 0.5);

    local icon = self:CreateTexture(nil, "ARTWORK");
    self.ItemIcon = icon;
    icon:SetSize(ICON_SIZE, ICON_SIZE);
    icon:SetPoint("TOPLEFT", self, "TOPLEFT", PADDING_OUTER, -PADDING_OUTER);
    API.RemoveIconBorder(icon);

    local title = self:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_SubHeader", 1);
    self.ItemName = title;
    title:SetJustifyH("LEFT");
    title:SetJustifyV("TOP");
    title:SetSpacing(TEXT_SPACING);
    title:SetWidth(MAX_TEXT_WIDTH);

    local desc = self:CreateFontString(nil, "OVERLAY", "DUIFont_Item", 1);
    self.Description = desc;
    desc:SetJustifyH("LEFT");
    desc:SetJustifyV("TOP");
    desc:SetSpacing(TEXT_SPACING);
    desc:SetWidth(MAX_TEXT_WIDTH);
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -GAP_TITLE_DESC);

    local ttBG = self:CreateTexture(nil, "BORDER");
    self.TitleBackground = ttBG;
    ttBG:SetHeight(CLOSE_BUTTON_SIZE);
    ttBG:SetPoint("LEFT", icon, "RIGHT", -24, 8);
    ttBG:SetPoint("RIGHT", self, "RIGHT", 0, 0);
    ttBG:SetTexCoord(0.1875, 1, 0, 0.125);
    ttBG:SetBlendMode("ADD");
    ttBG:SetAlpha(0.15);

    local ib = self:CreateTexture(nil, "OVERLAY");
    self.IconBorder = ib;
    local margin = 18;
    ib:SetTextureSliceMargins(margin, margin, margin, margin);
    ib:SetTextureSliceMode(0);
    ib:SetTexCoord(0, 0.15625, 0, 0.15625);


    --Pseudo Text Button <Click to Read>
    local tbBG = self:CreateTexture(nil, "ARTWORK");
    self.TextButtonBackground = tbBG;
    local margin = 8;
    tbBG:SetTextureSliceMargins(margin, margin, margin, margin);
    tbBG:SetTextureSliceMode(0);
    tbBG:Hide();
    tbBG:ClearAllPoints();
    tbBG:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -GAP_TITLE_DESC);
    tbBG:SetTexCoord(0, 0.5, 0.515625, 0.578125);

    local ButtonText = self:CreateFontString(nil, "OVERLAY", "DUIFont_Item", 1);
    self.ButtonText = ButtonText;
    ButtonText:SetJustifyH("LEFT");
    ButtonText:SetJustifyV("TOP");
    ButtonText:Hide();
    ButtonText:SetPoint("TOPLEFT", tbBG, "TOPLEFT", PADDING_TEXT_BUTTON_H, -PADDING_TEXT_BUTTON_V);

    local ButtonIcon = self:CreateTexture(nil, "OVERLAY");
    self.ButtonIcon = ButtonIcon;
    ButtonIcon:SetSize(12, 12);
    ButtonIcon:SetPoint("LEFT", tbBG, "LEFT", PADDING_TEXT_BUTTON_V, 0);
    ButtonIcon:Hide();

    self.CloseButton = addon.WidgetManager:CreateAutoCloseButton(self);
    self.CloseButton:SetPoint("CENTER", self, "TOPRIGHT", -8, -8);

    local function CreateQueueMarker()
        --Sit below the frame, marker indicates the number of items in the queue
        local texture = self:CreateTexture(nil, "OVERLAY");
        texture:SetTexture(ThemeUtil:GetTextureFile("QuestItemDisplay-UI.png"));
        texture:SetTexCoord(0, 0.0625, 0.1875, 0.25);
        texture:SetSize(QUEUE_MARKER_SIZE, QUEUE_MARKER_SIZE);
        return texture
    end

    local function RemoveQueueMarker(texture)
        texture:Hide();
        texture:ClearAllPoints();
    end

    self.queueMarkerPool = API.CreateObjectPool(CreateQueueMarker, RemoveQueueMarker);


    self.AnimIn = self:CreateAnimationGroup(nil, "DUIGenericPopupAnimationTemplate");
    self.AnimIn:SetScript("OnFinished", function()
        self:UpdateQueueMarkers();
    end);

    self:SetScript("OnShow", self.OnShow);
    self:SetScript("OnHide", self.OnHide);

    self:LoadPosition();
    self:LoadTheme();
    self:UpdatePixel();

    addon.PixelUtil:AddPixelPerfectObject(self);

    self:SetFrameStrata("FULLSCREEN_DIALOG");
    self:SetFixedFrameStrata(true);

    self:SetScript("OnEnter", self.OnEnter);
    self:SetScript("OnLeave", self.OnLeave);
end

function QuestItemDisplay:UpdatePixel(scale)
    if not self.IconBorder then return end;

    if not scale then
        scale = self:GetEffectiveScale();
    end

    local borderOffsetPixel = 10.0;
    local offset = API.GetPixelForScale(scale, borderOffsetPixel);
    self.IconBorder:ClearAllPoints();
    self.IconBorder:SetPoint("TOPLEFT", self.ItemIcon, "TOPLEFT", -offset, offset);
    self.IconBorder:SetPoint("BOTTOMRIGHT", self.ItemIcon, "BOTTOMRIGHT", offset, -offset);

    local shadowOffsetPixel = 16.0;
    offset = API.GetPixelForScale(scale, shadowOffsetPixel);
    self.BackgroundShadow:ClearAllPoints();
    self.BackgroundShadow:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset);
    self.BackgroundShadow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset);

    API.UpdateTextureSliceScale(self.Background);
    API.UpdateTextureSliceScale(self.BackgroundShadow.Texture);
end


local function FadeOut_OnUpdate(self, elapsed)
    self.alpha = self.alpha - 2 * elapsed;
    if self.alpha <= 0 then
        self:SetAlpha(0);
        if self.alpha <= -1 then    --extend fade out duration (delay)
            self:SetScript("OnUpdate", nil);
            self.isFadingOut = nil;
            self:Hide();
            self:ProcessQueue();
        end
    else
        self:SetAlpha(self.alpha);
    end
end

function QuestItemDisplay:SetCountdown(second)
    self.isCountingDown = true;
    self.isFadingOut = nil;
    self.CloseButton:SetCountdown(second);
end

function QuestItemDisplay:OnCountdownFinished()
    self.isCountingDown = nil;
    self.alpha = self:GetAlpha();
    self.isFadingOut = true;
    self:SetScript("OnUpdate", FadeOut_OnUpdate);
    self:ReleaseActionButton();
end

function QuestItemDisplay:LoadTheme()
    if self.Init then
        return
    end

    local file = ThemeUtil:GetTextureFile("QuestItemDisplay-UI.png");
    local isDarkMode = ThemeUtil:IsDarkMode();

    self.Background:SetTexture(file);
    self.BackgroundShadow.Texture:SetTexture(file);
    self.IconBorder:SetTexture(file);
    self.TitleBackground:SetTexture(file);
    self.TextButtonBackground:SetTexture(file);

    if isDarkMode then
        self.themeID = 2;
        ThemeUtil:SetFontColor(self.ButtonText, "DarkModeGold");
    else
        self.themeID = 1;
        ThemeUtil:SetFontColor(self.ButtonText, "Ivory");
    end

    self.CloseButton:SetTheme(self.themeID);

    local function SetBackGround(texture)
        texture:SetTexture(file);
    end
    self.queueMarkerPool:ProcessAllObjects(SetBackGround);
end

function QuestItemDisplay:Layout(hasDescription)
    self.ItemName:ClearAllPoints();
    self.ItemName:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);

    local titleWidth = self.ItemName:GetWrappedWidth() + CLOSE_BUTTON_SIZE;
    local descWidth;

    local textButtonAnchor;

    if hasDescription then
        descWidth = self.Description:GetWrappedWidth();
        textButtonAnchor = self.Description;
    else
        descWidth = 0;
        textButtonAnchor = self.ItemName;
    end

    self.TextButtonBackground:ClearAllPoints();
    self.TextButtonBackground:SetPoint("TOPLEFT", textButtonAnchor, "BOTTOMLEFT", 0, -GAP_TITLE_DESC);

    local textButtonWidth, bottomObject;

    if self.ButtonText:IsShown() then
        self.ButtonText:ClearAllPoints();
        local iconWidth;
        if self.ButtonIcon:IsShown() then
            iconWidth = 16;
            self.ButtonText:SetPoint("LEFT", self.ButtonIcon, "RIGHT", 0, 0);
        else
            iconWidth = 0;
            self.ButtonText:SetPoint("TOPLEFT", self.TextButtonBackground, "TOPLEFT", PADDING_TEXT_BUTTON_H, -PADDING_TEXT_BUTTON_V);
        end
        textButtonWidth = iconWidth + self.ButtonText:GetWrappedWidth() + 2*PADDING_TEXT_BUTTON_H;
        bottomObject = self.TextButtonBackground;
        self.TextButtonBackground:SetHeight(Round(self.ButtonText:GetHeight() + 2 * PADDING_TEXT_BUTTON_V));
    else
        textButtonWidth = 0;
        bottomObject = self.Description;
    end

    local textWidth = Round(math.max(titleWidth, descWidth, textButtonWidth));
    self.TextButtonBackground:SetWidth(textWidth);

    local textHeight = Round(self.ItemName:GetTop() - bottomObject:GetBottom());

    self.ItemName:ClearAllPoints();

    if textHeight < ICON_SIZE then
        self.ItemName:SetPoint("TOPLEFT", self.ItemIcon, "TOPRIGHT", GAP_TEXT_ICON, 0.5*(textHeight - ICON_SIZE));
        textHeight = ICON_SIZE;
    else
        self.ItemName:SetPoint("TOPLEFT", self.ItemIcon, "TOPRIGHT", GAP_TEXT_ICON, 0);
    end

    self:SetSize(textWidth + ICON_SIZE + 2*PADDING_OUTER + GAP_TEXT_ICON, textHeight + 2*PADDING_OUTER);
end

function QuestItemDisplay:ShouldDeferDisplay()
    if addon.DialogueUI:IsShown() then
        return true
    end
end

function QuestItemDisplay:TryDisplayItem(itemID, isRequery)
    if self.Init then
        self:Init();
    end

    if self:IsShown() then
        self:QueueItem(itemID);
        return
    else
        if MerchantFrame and MerchantFrame:IsShown() then
            self:RegisterEvent("MERCHANT_SHOW");
            self:RegisterEvent("MERCHANT_CLOSED");
            self.atMerchant = true;
            self:QueueItem(itemID);
            self.anyDeferred = true;
            return
        else
            self.atMerchant = nil;
        end
    end
    self.isEditMode = false;

    local tooltipData = C_TooltipInfo.GetItemByID(itemID);
    if not (tooltipData and tooltipData.lines) then
        self:ProcessQueue();
        return
    end

    local name, description, extraText;
    local isReadable, isStartQuestItem, startQuestID, isOnQuest;

    for i, line in ipairs(tooltipData.lines) do
        --Classic: READABLE_ITEM isn't shown on the tooltip

        if line.leftText and line.type ~= 20 then
            if i == 1 then
                name = line.leftText;
            else
                if match(line.leftText, "^[\"“]") then
                    description = line.leftText;
                elseif line.leftText == READABLE_ITEM or line.leftText == START_QUEST_ITEM then
                    if line.leftText == READABLE_ITEM then
                        isReadable = true;
                    else
                        isStartQuestItem = true;
                    end

                    --We not longer put "extraText" like <This item can be read> into the descriptions since there is a click-to-read button in below
                    --[[
                    local color;
                    if self.themeID == 1 then
                        color = "700b0b";
                    else
                        color = "b04a4a";
                    end
                    extraText = "|cff"..color..line.leftText.."|r";
                    --]]
                end
            end
        end
    end

    self:ShowTextButton(false);

    local itemInfo = GetBagQuestItemInfo(itemID);
    if itemInfo then
        startQuestID = itemInfo.questID;
        if startQuestID then
            local questName = API.GetQuestName(startQuestID);
            if questName then
                extraText = nil;
            end
        elseif itemInfo.isReadable then
            isReadable = true;
            extraText = nil;
        end
    elseif isReadable or isStartQuestItem then
        if not isRequery then
            --In the case where the item hasn't been pushed into the bag
            --Clear the name so we can requery it
            name = nil;
        end
    end

    if isReadable and self:ShouldDeferDisplay() then
        --We defer readable items to the end of NPC interaction, because using the item exits interaction
        self:QueueItem(itemID);
        self.anyDeferred = true;
        return
    end

    if not (name and (description or extraText or isReadable)) then
        if not isRequery then
            if not self.pauseUpdate then
                self.pauseUpdate = true;
                After(REQUERY_DELAY, function()
                    self.pauseUpdate = nil;
                    self:TryDisplayItem(itemID, true);
                end);
            end
        else
            self:ProcessQueue();
        end
        return
    end

    if extraText then
        if description then
            description = description.."\n"..extraText;
        else
            description = extraText;
        end
    end

    local icon = C_Item.GetItemIconByID(itemID);

    self.ItemIcon:SetTexture(icon);
    self.ItemName:SetText(name);
    self.Description:SetText(description);
    self.itemID = itemID;
    self.usable = false;

    local buttonText;
    if isReadable then
        self:SetReadableItem(itemID);
    elseif startQuestID then
        self:SetStartQuestItem(itemID, startQuestID, isOnQuest);
    end

    self:Layout(description ~= nil);

    self.AnimIn:Stop();
    self.AnimIn:Play();

    local readTime = math.max(AUTOHIDE_DELAY_MIN, 1 + (GetNumLetters(name) + (description and GetNumLetters(description) or 0) + (buttonText and GetNumLetters(buttonText) or 0)) / READING_SPEED_LETTER * 60);
    self:SetCountdown(readTime);

    if self:IsShown() then
        if WidgetManager:ChainContain(self) then
            WidgetManager:ChainLayout();
        end
    else
        self:Show();
    end

    self:RegisterEvent("MERCHANT_SHOW");
    self:RegisterEvent("MERCHANT_CLOSED");
end

function QuestItemDisplay:ShowTextButton(state)
    if self.TextButtonBackground then
        self.TextButtonBackground:SetShown(state);
        self.ButtonText:SetShown(state);

        if not state then
            self.ButtonIcon:Hide();
        end
    end
end

function QuestItemDisplay:SetTextButtonEnabled(isEnabled)
    local colorKey;

    if isEnabled then
        if self.themeID == 2 then
            colorKey = "DarkModeGold";
        else
            colorKey = "Ivory";
        end

        if self.ActionButton and self.ActionButton:IsFocused() then
            self:SetTextBackgroundID(2);
        else
            self:SetTextBackgroundID(1);
        end
    else
        if self.themeID == 2 then
            colorKey = "DarkModeGrey70";
        else
            colorKey = "DarkBrown"; --LightBrown
        end
        self:SetTextBackgroundID(3);
    end

    ThemeUtil:SetFontColor(self.ButtonText, colorKey);
end

function QuestItemDisplay:SetTextBackgroundID(id)
    if id == 1 then --Normal
        self.TextButtonBackground:SetTexCoord(0, 0.5, 0.515625, 0.578125);
    elseif id == 2 then --Highlighted
        self.TextButtonBackground:SetTexCoord(0, 0.5, 0.59375, 0.65625);
    elseif id == 3 then --Disabled
        self.TextButtonBackground:SetTexCoord(0, 0.5, 0.671875, 0.734375);
    end
end

local function onEnterCombatCallback()
    QuestItemDisplay:SetTextButtonEnabled(false);
end

function QuestItemDisplay:GetActionButton()
    local ActionButton = addon.AcquireSecureActionButton("QuestItemDisplay");
    if ActionButton then
        self.ActionButton = ActionButton;
        ActionButton:SetScript("OnEnter", function()
            self:OnEnter();
            self:SetTextBackgroundID(2);
        end);
        ActionButton:SetScript("OnLeave", function()
            self:OnLeave();
            self:SetTextBackgroundID(1);
        end);
        ActionButton:SetPostClickCallback(function(f, button)
            self:OnMouseUp(button);
            self:Clear();
        end);
        ActionButton:SetParent(self);
        ActionButton:SetFrameStrata(self:GetFrameStrata());
        ActionButton:SetFrameLevel(self:GetFrameLevel() + 5);
        ActionButton.onEnterCombatCallback = onEnterCombatCallback;
        --ActionButton:ShowDebugHitRect(true);
        self:SetTextButtonEnabled(true);
        return ActionButton
    else
        self:SetTextButtonEnabled(false);
    end
end

function QuestItemDisplay:ReleaseActionButton()
    if self.ActionButton then
        self.ActionButton:Release();
    end
end

function QuestItemDisplay:SetUsableItem(itemID, buttonText)
    local ActionButton = self:GetActionButton();
    if ActionButton then
        ActionButton:SetUseItemByID(itemID, "LeftButton");
        ActionButton:CoverObject(self.TextButtonBackground, 4);
    end

    self:ShowTextButton(true);
    self.ButtonText:SetText(buttonText);

    self:RegisterEvent("PLAYER_REGEN_ENABLED");
end

function QuestItemDisplay:SetReadableItem(itemID)
    self.itemType = "book";
    local buttonText= L["Click To Read"];
    self:SetUsableItem(itemID, buttonText);
end

function QuestItemDisplay:SetStartQuestItem(itemID, startQuestID, isOnQuest)
    self.itemType = "questOffer";
    self.startQuestID = startQuestID;

    local icon = "Interface/AddOns/DialogueUI/Art/Icons/QuestItem-NotOnQuest.png";
    self.ButtonIcon:SetTexture(icon);
    self.ButtonIcon:Show();
    local questName = API.GetQuestName(startQuestID);
    if not (questName and questName ~= "") then
        questName = "Quest: "..startQuestID;

        local function OnQuestLoaded(id)
            if self:IsVisible() and self.itemID == itemID then
                questName = API.GetQuestName(startQuestID);
                self.ButtonText:SetText(questName);
                self.ButtonText:Show();
            end
        end
        addon.CallbackRegistry:LoadQuest(startQuestID, OnQuestLoaded)
    end
    self:SetUsableItem(itemID, questName);
end

function QuestItemDisplay:UpdateQueueMarkers()
    self.queueMarkerPool:Release();

    local numQueued = #self.queue;
    if numQueued > 0 then
        local fromOffsetX = -numQueued * QUEUE_MARKER_SIZE * 0.5;
        local offsetY = 0;
        for i = 0, numQueued - 1 do
            local marker = self.queueMarkerPool:Acquire();
            marker:SetPoint("TOPLEFT", self, "BOTTOM", fromOffsetX + i * QUEUE_MARKER_SIZE, offsetY);
        end
    end
end

function QuestItemDisplay:QueueItem(itemID)
    if itemID == self.itemID then return end;

    for i, id in ipairs(self.queue) do
        if id == itemID then
            return
        end
    end

    table.insert(self.queue, itemID);

    if not self.AnimIn:IsPlaying() then
        self:UpdateQueueMarkers();
    end
end

function QuestItemDisplay:ProcessQueue()
    if #self.queue > 0 then
        local itemID = table.remove(self.queue, 1);
        self:UpdateQueueMarkers();
        self:TryDisplayItem(itemID);
    else
        self:Clear();
    end
end

function QuestItemDisplay:Clear()
    self:SetScript("OnUpdate", nil);
    self.t = nil;
    self.progress = nil;
    self.isCountingDown = nil;
    self.itemID = nil;
    self.itemType = nil;
    self.startQuestID = nil;
    self.anyDeferred = nil;
    self.atMerchant = nil;
    self.queue = {};
    self:Hide();
    self:UnregisterEvent("MERCHANT_SHOW");
    self:UnregisterEvent("MERCHANT_CLOSED");
end

function QuestItemDisplay:OnDragStart()
    WidgetManager:ChainRemove(self);
end

function QuestItemDisplay:OnShow()
    if not self:IsUsingCustomPosition() then
        WidgetManager:ChainAdd(self);
    end
end

function QuestItemDisplay:OnHide()
    self.isCountingDown = nil;
    self.isFadingOut = nil;
    self:StopAnimating();
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");

    if self.isMoving then
        self.isMoving = nil;
        self:StopMovingOrSizing();
    end

    if not self:IsUsingCustomPosition() then
        WidgetManager:ChainRemove(self);
    end
end

function QuestItemDisplay:OnEnter()
    self.CloseButton:PauseAutoCloseTimer(true);
end

function QuestItemDisplay:OnLeave()
    self.CloseButton:PauseAutoCloseTimer(false);
end

function QuestItemDisplay:Close()
    self:Clear();
end

function QuestItemDisplay:OnMouseUp(button)
    if button == "RightButton" then
        QuestItemDisplay:Clear();
    elseif button == "LeftButton" then

    elseif button == "MiddleButton" then
        QuestItemDisplay:ResetPosition();
    end
end

function QuestItemDisplay:OnEvent(event, ...)
    if event == "CHAT_MSG_LOOT" then
        self:CHAT_MSG_LOOT(...);
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.itemID and not self.isFadingOut then
            if self.itemType == "book" then
                self:SetReadableItem(self.itemID);
            elseif self.itemType == "questOffer" then
                local questName = self.ButtonText:GetText();
                self:SetUsableItem(self.itemID, questName);
            end
        end
    elseif event == "MERCHANT_SHOW" then
        self.atMerchant = true;
    elseif event == "MERCHANT_CLOSED" then
        self.atMerchant = nil;
        if self.anyDeferred then
            self.anyDeferred = nil;
            self:ProcessQueue();
        end
    end
end

function QuestItemDisplay:OnItemLooted(itemID)
    --Some readable items are not Quest Type (e.g. Secrets of Azeroth). We don't support these items

    if SEEN_ITEMS_SESSION[itemID] then return end;

    SEEN_ITEMS_SESSION[itemID] = true;
    if IsQuestLoreItem(itemID) then
        if ONE_TIME_ITEM[itemID] and SEEN_ITEMS_ALL[itemID] then
            return
        end
        if (not IGNORE_SEEN_ITEM) or (not SEEN_ITEMS_ALL[itemID]) then
            SEEN_ITEMS_ALL[itemID] = true;
            self:TryDisplayItem(itemID);
        end
    end
end

function QuestItemDisplay:LoadSaves()
    if not DialogueUI_Saves then return end;

    if (not DialogueUI_Saves.QuestItems) or type(DialogueUI_Saves.QuestItems) ~= "table" then
        DialogueUI_Saves.QuestItems = {};
    end

    SEEN_ITEMS_ALL = DialogueUI_Saves.QuestItems;
end

function QuestItemDisplay:ToggleEditMode()
    if self.isEditMode and self:IsShown() then
        self.isEditMode = false;
        self:Clear();
        return
    end

    if self.Init then
        self:Init();
    end

    self:Clear();
    self.ItemName:SetText(L["Quest Item Display"]);
    self.Description:SetText(L["Drag To Move"]);
    self.ItemIcon:SetTexture(134400);   --QuestionMark
    self.CloseButton:StopCountdown();
    self:ShowTextButton(false);
    self:Layout(true);
    self.AnimIn:Stop();
    self.AnimIn:Play();
    self:Show();
    self.isEditMode = true;

    --if WidgetManager:ChainContain(self) then
    --    WidgetManager:TogglePopupAnchor(true);
    --end
end

function QuestItemDisplay:LowerFrameStrata()
    if self.dynamicFrameStrata then
        if not self.lowStrata then
            self.lowStrata = true;
            self:SetFixedFrameStrata(false);
            self:SetFrameStrata("LOW");
            self:SetFixedFrameStrata(true);
        end
        if self:IsShown() then
            if self.AnimIn and self.AnimIn:IsPlaying() then
                self.AnimIn:Stop();
                self:UpdateQueueMarkers();
            end
            self:SetAlpha(0);
        end
    end
    if self.CloseButton then
        self.CloseButton:PauseAutoCloseTimer(true);
    end
end

function QuestItemDisplay:RaiseFrameStrata()
    if self.lowStrata then
        self.lowStrata = false;
        self:SetFixedFrameStrata(false);
        self:SetFrameStrata("FULLSCREEN_DIALOG");
        self:SetFixedFrameStrata(true);
        if self:IsShown() then
            self:SetAlpha(1);
        end
    end
    if self.CloseButton then
        self.CloseButton:PauseAutoCloseTimer(false);
    end
end

function QuestItemDisplay:SetDynamicFrameStrata(state, userInput)
    if state then
        self.dynamicFrameStrata = true;
        if not self.worldmapHooked then
            self.worldmapHooked = true;
            if WorldMapFrame and WorldMapFrame.RegisterCallback then
                EventRegistry:RegisterCallback("WorldMapOnShow", self.LowerFrameStrata, self);
                WorldMapFrame:RegisterCallback("WorldMapOnHide", self.RaiseFrameStrata, self);
            end
        end
        if userInput then
            if WorldMapFrame:IsVisible() then
                self:LowerFrameStrata();
            else
                self:RaiseFrameStrata();
            end
        end
    else
        self.dynamicFrameStrata = false;
        self:RaiseFrameStrata();
    end
end

function QuestItemDisplay:EnableModule(state)
    if state then
        self:RegisterEvent("CHAT_MSG_LOOT");
        self:SetScript("OnEvent", self.OnEvent);
        self:LoadSaves();
    else
        self:UnregisterEvent("CHAT_MSG_LOOT");
        self:Clear();
        self:SetScript("OnEvent", nil);
    end
end


do
    local function Settings_QuestItemDisplay(dbValue)
        QuestItemDisplay:EnableModule(dbValue == true);
    end
    CallbackRegistry:Register("SettingChanged.QuestItemDisplay", Settings_QuestItemDisplay);

    local function Settings_QuestItemDisplayHideSeen(dbValue)
        IGNORE_SEEN_ITEM = dbValue == true;
    end
    CallbackRegistry:Register("SettingChanged.QuestItemDisplayHideSeen", Settings_QuestItemDisplayHideSeen);

    local function Settings_QuestItemDisplayDynamicFrameStrata(dbValue, userInput)
        QuestItemDisplay:SetDynamicFrameStrata(dbValue == true, userInput);
    end
    CallbackRegistry:Register("SettingChanged.QuestItemDisplayDynamicFrameStrata", Settings_QuestItemDisplayDynamicFrameStrata);

    local function OnFontSizeChanged(baseFontSize)
        if baseFontSize > 16 then
            MAX_TEXT_WIDTH = Round(224 * baseFontSize / 16);
        else
            MAX_TEXT_WIDTH = 224;
        end
    end
    CallbackRegistry:Register("FontSizeChanged", OnFontSizeChanged);
end

do
    local function DialogueUI_OnHide()
        if QuestItemDisplay.anyDeferred then
            After(0.25, function()
                QuestItemDisplay:ProcessQueue();
            end);
        end
    end
    addon.CallbackRegistry:Register("DialogueUI.Hide", DialogueUI_OnHide);

    API.SetPlayCutsceneCallback(function()
        QuestItemDisplay:Clear();
    end);
end

do
    local OneTimeItem = {
        29433,      --Grisly Trophy
        163036,     --Polished Pet Charm
        191140,     --Bronze Timepiece
        206350,     --Radiant Remnant
        219934,     --Spark of War
        212493,     --Odd Glob of Wax
        224784,     --Pinnacle Cache
        224835,     --Deepgrove Roots
        224838,     --Null Silver
        225741,     --Titan Disc Fragment
        225950,     --Nerubian Chitin
        226135,     --Nerubian Venom
        226136,     --Nerubian Blood
        227406,     --Interesting Notes
        227450,     --Sky Racer's Purse
        228361,     --Adventurer's Cache
        229899,     --Coffer Key Shard
        235610,     --Undermine Adventurer's Cache
        235897,     --Radiant Echo S2
        238208,     --Nanny's Surge Dividends
        239118,     --Pinnacle Cache
        239120,     --Seasoned Adventurer's Cache
        245589,     --Hellcaller Chest
        244842,     --Fabled Veteran's Cache
        244865,     --Pinnacle Cache
        245611,     --Wriggling Pinnacle Cache
    };

    for _, itemID in ipairs(OneTimeItem) do
        ONE_TIME_ITEM[itemID] = true;
    end

    OneTimeItem = nil;
end


--[[
do
    function Debug_QuestItemDisplay(itemID)
        QuestItemDisplay:TryDisplayItem(itemID or 132120);
    end
end
--]]