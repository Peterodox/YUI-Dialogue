local _, addon = ...

local L = addon.L;
local API = addon.API;
local C_TooltipInfo = addon.TooltipAPI;
local ThemeUtil = addon.ThemeUtil;
local match = string.match;
local GetNumLetters = strlenutf8 or string.len;
local Round = API.Round;
local IsQuestLoreItem = API.IsQuestLoreItem;
local GetBagQuestItemInfo = API.GetBagQuestItemInfo;
local PI = math.pi;
local After = C_Timer.After;

-- User Settings
local IGNORE_SEEN_ITEM = false;
local DBKEY_POSITION = "QuestItemDisplayPosition";
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
local DURATION_MIN = 5;

local PLAYER_GUID;
local PLAYER_NAME;

local SEEN_ITEMS_SESSION = {};  --Items seen in this game session
local SEEN_ITEMS_ALL = {};      --Items discovered by any of the characters
local ALWAYS_IGNORED = {};      --Some World Quest Items

local READABLE_ITEM = ITEM_CAN_BE_READ or "<This item can be read>";
local START_QUEST_ITEM = ITEM_STARTS_QUEST or "This Item Begins a Quest";

local QuestItemDisplay = CreateFrame("Frame");
QuestItemDisplay:Hide();
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

    local bgShadow = self:CreateTexture(nil, "BACKGROUND", nil, -1);
    self.BackgroundShadow = bgShadow;
    local margin = 24;
    bgShadow:SetTextureSliceMargins(margin, margin, margin, margin);
    bgShadow:SetTextureSliceMode(0);
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


    --Pseudo Close Button
    local bt = self:CreateTexture(nil, "OVERLAY");
    self.CloseButtonTexture = bt;
    bt:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);
    bt:SetPoint("CENTER", self, "TOPRIGHT", -8, -8);
    bt:SetTexCoord(0, 0.125, 0.25, 0.375);

    local function CreateSwipe(isRight)
        local sw = self:CreateTexture(nil, "OVERLAY", nil, 1);
        sw:SetSize(CLOSE_BUTTON_SIZE/2, CLOSE_BUTTON_SIZE);
        if isRight then
            sw:SetPoint("LEFT", bt, "CENTER", 0, 0);
            sw:SetTexCoord(0.0625, 0.125, 0.375, 0.5);
        else
            sw:SetPoint("RIGHT", bt, "CENTER", 0, 0);
            sw:SetTexCoord(0, 0.0625, 0.375, 0.5);
        end

        local mask = self:CreateMaskTexture(nil, "OVERLAY", nil, 1);
        sw:AddMaskTexture(mask);
        mask:SetTexture("Interface/AddOns/DialogueUI/Art/BasicShapes/Mask-RightWhite", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
        mask:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);
        mask:SetPoint("CENTER", bt, "CENTER", 0, 0);

        return sw, mask
    end

    self.Swipe1, self.SwipeMask1 = CreateSwipe(true);
    self.Swipe2, self.SwipeMask2 = CreateSwipe();
    self.SwipeMask2:SetRotation(-PI);

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

    self:SetScript("OnHide", self.OnHide);

    self:LoadPosition();
    self:LoadTheme();
    self:UpdatePixel();

    addon.PixelUtil:AddPixelPerfectObject(self);


    --Drag to reposition
    self:SetClampedToScreen(true);
    self:SetMovable(true);
    local DragFrame = CreateFrame("Frame", nil, self);
    DragFrame:SetAllPoints(true);
    DragFrame:SetFrameLevel(self:GetFrameLevel() + 1);
    DragFrame:SetScript("OnEnter", self.OnEnter);
    DragFrame:SetScript("OnLeave", self.OnLeave);
    DragFrame:SetScript("OnMouseUp", self.OnMouseUp);
    DragFrame:RegisterForDrag("LeftButton");
    DragFrame:SetScript("OnDragStart", function()
        self:StartMoving();
        self.isMoving = true;
    end);
    DragFrame:SetScript("OnDragStop", function()
        self:StopMovingOrSizing();
        self:SavePosition();
        self.isMoving = nil;
    end);

    self:SetFrameStrata("FULLSCREEN_DIALOG");
    self:SetFixedFrameStrata(true);
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

    --API.UpdateTextureSliceScale(self.Background);
    --API.UpdateTextureSliceScale(self.BackgroundShadow);
end

function QuestItemDisplay:ResetPosition()
    if self:IsUsingCustomPosition() then
        addon.SetDBValue(DBKEY_POSITION, nil);
    end

    self:LoadPosition();

    addon.SettingsUI:RequestUpdate();
end

function QuestItemDisplay:IsUsingCustomPosition()
    return addon.GetDBValue(DBKEY_POSITION) ~= nil
end

function QuestItemDisplay:LoadPosition()
    local position = addon.GetDBValue(DBKEY_POSITION);

    self:ClearAllPoints();

    if position then
        self:SetPoint("LEFT", UIParent, "BOTTOMLEFT", position[1], position[2]);
    else
        self:SetPoint("LEFT", nil, "LEFT", 32, 32);
    end
end

function QuestItemDisplay:SavePosition()
    local x = self:GetLeft();
    local _, y = self:GetCenter();

    if not x and y then return end;

    local position = {
        Round(x),
        Round(y);
    };

    addon.SetDBValue(DBKEY_POSITION, position);

    addon.SettingsUI:RequestUpdate();
end

local function Countdown_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    self.progress = self.t / self.duration;

    if self.progress >= 1 then
        self.progress = nil;
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self:OnCountdownFinished();
        self.Swipe1:Hide();
    elseif self.progress >= 0.5 then
        self.SwipeMask1:SetRotation((self.progress/0.5 - 1) * PI);
        self.Swipe2:Hide();
    else
        self.SwipeMask2:SetRotation((self.progress/0.5 - 1) * PI);
    end
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
    self.duration = second;
    self.t = 0;
    self.Swipe1:Show();
    self.Swipe2:Show();
    self.SwipeMask1:SetRotation(0);
    self.SwipeMask2:SetRotation(-PI);
    self.isCountingDown = true;
    self.isFadingOut = nil;
    self:SetScript("OnUpdate", Countdown_OnUpdate);
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
    self.BackgroundShadow:SetTexture(file);
    self.IconBorder:SetTexture(file);
    self.TitleBackground:SetTexture(file);
    self.TextButtonBackground:SetTexture(file);
    self.CloseButtonTexture:SetTexture(file);
    self.Swipe1:SetTexture(file);
    self.Swipe2:SetTexture(file);

    if isDarkMode then
        self.themeID = 2;
        ThemeUtil:SetFontColor(self.ButtonText, "DarkModeGold");
    else
        self.themeID = 1;
        ThemeUtil:SetFontColor(self.ButtonText, "Ivory");
    end

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
    end

    local tooltipData = C_TooltipInfo.GetItemByID(itemID);
    if not (tooltipData and tooltipData.lines) then
        self:ProcessQueue();
        return
    end

    local name, description, extraText;
    local isReadable, isStartQuestItem, startQuestID, isOnQuest;

    for i, line in ipairs(tooltipData.lines) do
        if line.leftText and line.type ~= 20 then
            if i == 1 then
                name = line.leftText;
            else
                if match(line.leftText, "^[\"“]") then
                    description = line.leftText;
                elseif line.leftText == READABLE_ITEM or line.leftText == START_QUEST_ITEM then
                    local color;
                    if self.themeID == 1 then
                        color = "700b0b";   --700b0b 9B2020
                    else
                        color = "b04a4a";
                    end
                    extraText = "|cff"..color..line.leftText.."|r";

                    if line.leftText == READABLE_ITEM then
                        isReadable = true;
                    else
                        isStartQuestItem = true;
                    end
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
    else
        if isReadable or isStartQuestItem then
            --Event Order: item has not been pushed into bags
            --clear name to force a requery
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
                After(0.5, function()
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

    self:Show();

    local readTime = math.max(DURATION_MIN, 1 + (GetNumLetters(name) + (description and GetNumLetters(description) or 0) + (buttonText and GetNumLetters(buttonText) or 0)) / READING_SPEED_LETTER * 60);
    self:SetCountdown(readTime);
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
        ActionButton:SetScript("PostClick", function(f, button)
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
        After(0.25, function()
            if self:IsVisible() and self.itemID == itemID then
                questName = API.GetQuestName(startQuestID);
                self.ButtonText:SetText(questName);
                self.ButtonText:Show();
            end
        end);
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
    self.queue = {};
    self:Hide();
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
end

function QuestItemDisplay:PauseAutoCloseTimer(state)
    if self.isCountingDown then
        if state then
            self:SetScript("OnUpdate", nil);
        else
            self:SetScript("OnUpdate", Countdown_OnUpdate);
        end
    end
end

function QuestItemDisplay:OnEnter()
    QuestItemDisplay:PauseAutoCloseTimer(true);
end

function QuestItemDisplay:OnLeave()
    QuestItemDisplay:PauseAutoCloseTimer(false);
end

function QuestItemDisplay:OnMouseUp(button)
    if button == "RightButton" then
        QuestItemDisplay:Clear();
    elseif button == "LeftButton" then
        if QuestItemDisplay.CloseButtonTexture:IsMouseOver() then
            QuestItemDisplay:Clear();
        end
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
    end
end

function QuestItemDisplay:CHAT_MSG_LOOT_RETAIL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid)
    --Payloads are different on Classic!
    if guid ~= PLAYER_GUID then return end;
    self:ProcessLootMessage(text);
end
QuestItemDisplay.CHAT_MSG_LOOT = QuestItemDisplay.CHAT_MSG_LOOT_RETAIL;

function QuestItemDisplay:CHAT_MSG_LOOT_CLASSIC(text, _, _, _, playerName)
    if playerName ~= PLAYER_NAME then return end;
    self:ProcessLootMessage(text);
end

function QuestItemDisplay:ProcessLootMessage(text)
    --Some readable items are not Quest Type (e.g. Secrets of Azeroth). We don't support these items.
    local itemID = match(text, "item:(%d+)", 1);
    if itemID then
        itemID = tonumber(itemID);
        if itemID and not SEEN_ITEMS_SESSION[itemID] then
            SEEN_ITEMS_SESSION[itemID] = true;
            if (not ALWAYS_IGNORED[itemID]) and IsQuestLoreItem(itemID) then
                if (not IGNORE_SEEN_ITEM) or (not SEEN_ITEMS_ALL[itemID]) then
                    SEEN_ITEMS_ALL[itemID] = true;
                    self:TryDisplayItem(itemID);
                end
            end
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

function QuestItemDisplay:EnterEditMode()
    if self.Init then
        self:Init();
    end

    self:Clear();
    self.ItemName:SetText(L["Quest Item Display"]);
    self.Description:SetText(L["Drag To Move"]);
    self.ItemIcon:SetTexture(134400);   --QuestionMark
    self.Swipe1:Hide();
    self.Swipe2:Hide();
    self:ShowTextButton(false);
    self:Layout(true);
    self.AnimIn:Stop();
    self.AnimIn:Play();
    self:Show();
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
    self:PauseAutoCloseTimer(true);
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
    self:PauseAutoCloseTimer(false);
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
    if addon.IsToCVersionEqualOrNewerThan(100000) then
        QuestItemDisplay.CHAT_MSG_LOOT = QuestItemDisplay.CHAT_MSG_LOOT_RETAIL;
    else
        QuestItemDisplay.CHAT_MSG_LOOT = QuestItemDisplay.CHAT_MSG_LOOT_CLASSIC;
    end
end


do
    local function GetPlayerGUID()
        PLAYER_GUID = UnitGUID("player");
        PLAYER_NAME = UnitName("player");
    end
    addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", GetPlayerGUID);

    local function Settings_QuestItemDisplay(dbValue)
        QuestItemDisplay:EnableModule(dbValue == true);
    end
    addon.CallbackRegistry:Register("SettingChanged.QuestItemDisplay", Settings_QuestItemDisplay);

    local function Settings_QuestItemDisplayHideSeen(dbValue)
        IGNORE_SEEN_ITEM = dbValue == true;
    end
    addon.CallbackRegistry:Register("SettingChanged.QuestItemDisplayHideSeen", Settings_QuestItemDisplayHideSeen);


    local function Settings_QuestItemDisplayDynamicFrameStrata(dbValue, userInput)
        QuestItemDisplay:SetDynamicFrameStrata(dbValue == true, userInput);
    end
    addon.CallbackRegistry:Register("SettingChanged.QuestItemDisplayDynamicFrameStrata", Settings_QuestItemDisplayDynamicFrameStrata);
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
    local Items = {
        191140,     --Bronze Timepiece
        227450,     --Sky Racer's Purse
        212493,     --Odd Glob of Wax
        228361,     --Adventurer's Cache
    };

    for _, itemID in ipairs(Items) do
        ALWAYS_IGNORED[itemID] = true;
    end

    Items = nil;
end

do
    --function Debug_QuestItemDisplay(itemID)
    --    QuestItemDisplay:TryDisplayItem(itemID or 132120);
    --end
end