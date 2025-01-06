local _, addon = ...
local GetDBBool = addon.GetDBBool;
local UpdateTextureSliceScale = addon.API.UpdateTextureSliceScale;

local tinsert = table.insert;
local format = string.format;
local gsub = string.gsub;
local find = string.find;
local ipairs = ipairs;
local time = time;


local BASE_TIME;

local function GetRelativeTime()
    if not BASE_TIME then
        BASE_TIME = time();
    end

    return time() - BASE_TIME
end

local ChatFrame = CreateFrame("Frame");
ChatFrame:Hide();
addon.ChatFrame = ChatFrame;

local ScrollView = addon.CreateScrollView(ChatFrame);
ScrollView:SetAllowNegativeScrollRange(true);

local MessageFader = CreateFrame("Frame", nil, ChatFrame);

local NUM_MAX_ENTRY = 500;
local NUM_KEPT_ENTRY = 250;

local FRAME_WIDTH = 336;
local FRAME_HEIGHT = 14 * 16;
local FRAME_INSET_LEFT = 8;
local FRAME_INSET_RIGHT = 8;
local FRAME_INSET_VERTICAL = 8;
local SPACING_NEW_LINE = 4;
local SPACING_INTERNAL = 2;
local OFFSET_PER_SCROLL = 24;
local FRAME_HITRECT_SHIRNK_RIGHT = -FRAME_WIDTH * 0.25;

local ALPHA_UNFOCUSED = 0.6;

local FADE_MULTIPLIER_UI_IN = 8;   -- *elapsed (duration = 1/multipier sec)
local FADE_MULTIPLIER_UI_OUT = 4;
local FADE_MULTIPLIER_MSG_IN = 8;
local FADE_MULTIPLIER_MSG_OUT_AUTO = 1;
local FADE_MULTIPLIER_MSG_OUT_MANUAL = FADE_MULTIPLIER_UI_OUT;
local FADE_MULTIPLIER_MSG_OUT = FADE_MULTIPLIER_MSG_OUT_AUTO;

local FONTSTRING_WDITH = FRAME_WIDTH - FRAME_INSET_LEFT - 32;

local FORMAT_SAY = CHAT_MONSTER_SAY_GET or "%s says: ";
local FORMAT_YELL = CHAT_MONSTER_YELL_GET or "%s yells: ";
local FORMAT_WHISPER = CHAT_MONSTER_WHISPER_GET or "%s whispers: ";

local FORMAT_COLOR_NAME = "|cffffffff%s: |r";

local ChatEventData = {
    ["CHAT_MSG_MONSTER_SAY"] = {
        color = {1, 1, 0.624},
        --color = {0.87, 0.86, 0.75},
        prefix = FORMAT_COLOR_NAME,
    },

    ["CHAT_MSG_MONSTER_EMOTE"] = {
        color = {1, 0.502, 0.251},
    },

    ["CHAT_MSG_MONSTER_YELL"] = {
        color = {1, 0.251, 0.251},
        prefix = FORMAT_COLOR_NAME,
    },

    ["CHAT_MSG_MONSTER_WHISPER"] = {
        color = {1, 0.71, 0.922},
        prefix = FORMAT_COLOR_NAME,
    },

    ["CHAT_MSG_RAID_BOSS_WHISPER"] = {
        color = {1, 0.867, 0},
        --prefix = FORMAT_COLOR_NAME,
    },

    --[[    --Used by the game as help tip
    ["CHAT_MSG_RAID_BOSS_EMOTE"] = {
        color = {1, 0.867, 0},
    },
    --]]

    --[[
    ["CHAT_MSG_CHANNEL"] = {
        color = {1, 1, 0.624},
        prefix = "|cffffffff%s|r: ",
    },
    --]]

};


local EventIndex = {};
local IndexEvent = {};
do
    local index = 0;
    for event in pairs(ChatEventData) do
        index = index + 1;
        EventIndex[event] = index;
        IndexEvent[index] = event;
    end
end


ChatFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
ChatFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
ChatFrame:SetFrameStrata("LOW");
ChatFrame:SetFixedFrameStrata(true);
ChatFrame:SetFrameLevel(1);
ChatFrame:SetFixedFrameLevel(true);

local HiddenFrame = CreateFrame("Frame", nil, ChatFrame);
ChatFrame.HiddenFrame = HiddenFrame;
HiddenFrame:SetFrameStrata("LOW");
HiddenFrame:SetFixedFrameStrata(true);
HiddenFrame:SetFrameLevel(1);
HiddenFrame:SetFixedFrameLevel(true);
HiddenFrame:SetIgnoreParentAlpha(true);
HiddenFrame:Hide();
HiddenFrame:SetAlpha(0);

do  --Frame Background
    local bg = HiddenFrame:CreateTexture(nil, "BACKGROUND");
    bg:ClearAllPoints();
    bg:SetPoint("TOPLEFT", ChatFrame, "TOPLEFT", 0, 0);
    bg:SetPoint("BOTTOMRIGHT", ChatFrame, "BOTTOMRIGHT", 0, 0);
    local corner = 16;
    bg:SetTextureSliceMargins(corner, corner, corner, corner);
    bg:SetTextureSliceMode(1);
    bg:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/ChatFrameBackground.png");
    ChatFrame.Background = bg;
end

do  --ScrollBar
    local ScrollBar = addon.CreateScrollBar(HiddenFrame);
    local padding = 8;
    local copytextButtonHeight = 24
    ScrollBar:SetHeight(FRAME_HEIGHT);
    ScrollBar:SetPoint("TOPRIGHT", ChatFrame, "TOPRIGHT", -padding, -padding -copytextButtonHeight);
    ScrollBar:SetPoint("BOTTOMRIGHT", ChatFrame, "BOTTOMRIGHT", -padding, padding);
    ScrollBar:SetTheme(2);
    ScrollView:SetScrollBar(ScrollBar);
end

ScrollView:SetPoint("TOPLEFT", ChatFrame, "TOPLEFT", FRAME_INSET_LEFT, -FRAME_INSET_VERTICAL);
ScrollView:SetPoint("BOTTOMRIGHT", ChatFrame, "BOTTOMRIGHT", -FRAME_INSET_RIGHT, FRAME_INSET_VERTICAL);
ScrollView:OnSizeChanged();


local FONT_OBJECT = "DUIFont_ChatFont";
local UtilityFontString = ChatFrame:CreateFontString(nil, "BACKGROUND", FONT_OBJECT);
UtilityFontString:SetSpacing(SPACING_INTERNAL);
UtilityFontString:SetWidth(FONTSTRING_WDITH - 0.1);
UtilityFontString:SetNonSpaceWrap(true);
UtilityFontString:SetIndentedWordWrap(true);
UtilityFontString:Hide();


local ScrollViewDataProvider = {};

do
    ScrollViewDataProvider.content = {};
    ScrollViewDataProvider.numEntry = 0;
    ScrollViewDataProvider.objects = {};

    function ScrollViewDataProvider:GetSpacing()
        return SPACING_NEW_LINE
    end

    function ScrollViewDataProvider:CalculateTextHeight(text)
        if text then
            UtilityFontString:SetText(text);
            local height = UtilityFontString:GetHeight();
            return height and height > 0 and height
        end
    end

    function ScrollViewDataProvider:CreateExtent()
        local extent = {};
        extent[0] = -1;
        extent[1] = 0;
        return extent
    end

    function ScrollViewDataProvider:CalculateAllExtent()
        local sum = 0;
        local height = 0;
        local extent = self:CreateExtent();

        for i, v in ipairs(self.content) do
            height = self:CalculateTextHeight(v[1]);
            sum = sum + height + SPACING_NEW_LINE;
            extent[i + 1] = sum;
            --print(i, UtilityFontString:GetNumLines())
        end

        self.extent = extent;
    end

    function ScrollViewDataProvider:GetExtent()
        return self.extent
    end

    function ScrollViewDataProvider:AddContent(v)
        if self.numEntry > NUM_MAX_ENTRY then
            self:CullContent();
            self.owner:OnCullingComplete(NUM_MAX_ENTRY - NUM_KEPT_ENTRY);
        end
        self.numEntry = self.numEntry + 1;

        local textHeight = self:CalculateTextHeight(v[1]);

        if textHeight then
            tinsert(self.content, v);
            local maxDataIndex = self:GetMaxDataIndex();
            tinsert(self.extent, self.extent[maxDataIndex] + textHeight + SPACING_NEW_LINE);

            if self.isVisible then
                self:UpdateView();
            else
                self.isDisplayDirty = true;
            end
        end
    end

    function ScrollViewDataProvider:CullContent()
        local newContent = {};
        local fromIndex = self:GetMaxDataIndex() - NUM_KEPT_ENTRY + 1;
        local dataIndex;

        for i = 1, NUM_KEPT_ENTRY do
            dataIndex = i + fromIndex - 1;
            if self.content[dataIndex] then
                tinsert(newContent, self.content[dataIndex]);
            else
                break
            end
        end

        self.numEntry = #newContent;
        self.content = newContent;

        self:CalculateAllExtent();
    end

    function ScrollViewDataProvider:UpdateView()
        self.isDisplayDirty = nil;
        self.owner:OnContentChanged(true);
    end

    function ScrollViewDataProvider:GetMaxDataIndex()
        return #self.content
    end

    function ScrollViewDataProvider:GetStep()
        return OFFSET_PER_SCROLL;
    end

    function ScrollViewDataProvider:GetMaxExtent()
        return self.extent[ #self.extent ]
    end

    function ScrollViewDataProvider:CreateObject()
        local object = ScrollView:CreateFontString(nil, "OVERLAY", FONT_OBJECT);
        object:SetWidth(FONTSTRING_WDITH);
        object:SetSpacing(SPACING_INTERNAL);
        object:SetNonSpaceWrap(true);
        object:SetIndentedWordWrap(true);
        tinsert(self.objects, object);
        return object
    end

    function ScrollViewDataProvider:SetObjectData(object, dataIndex)
        if dataIndex ~= object.dataIndex then
            object.dataIndex = dataIndex;

            local data = self.content[dataIndex];
            if data then

            else
                return false
            end

            object:SetText(data[1]);

            local event = IndexEvent[data[2]];
            local color = ChatEventData[event].color;
            object:SetTextColor(color[1], color[2], color[3]);

            if ChatFrame.isFocused then
                object:SetAlpha(1);
            else
                if MessageFader:IsFadingIn() then
                    object:SetAlpha(1);
                else
                    object:SetAlpha(ALPHA_UNFOCUSED);
                end
            end
        end

        return true
    end

    function ScrollViewDataProvider:OnShow(scrollView)
        self.isVisible = true;
        if self.isDisplayDirty then
            self:UpdateView();
            ChatFrame:OnMouseFocusLost();
        end
    end

    function ScrollViewDataProvider:OnHide(scrollView)
        self.isVisible = false;
    end

    function ScrollViewDataProvider:GetAddedTime(dataIndex)
        return self.content[dataIndex] and self.content[dataIndex][3]
    end

    function ScrollViewDataProvider:OnViewUpdated()
        if not ChatFrame.isFocused then
            MessageFader:FadeOutMessages();
        end
    end
end

ScrollViewDataProvider:CalculateAllExtent();
ScrollView:SetDataProvider(ScrollViewDataProvider);

do
    local FADE_MESSAGE_AFTER = 10;

    local function FadeInMessages_OnUpdate(self, elapsed)
        self.fadingComplete = true;

        for i, object in ipairs(self.activeObjects) do
            object.alpha = object.alpha + FADE_MULTIPLIER_MSG_IN*elapsed;
            if object.alpha >= 1 then
                self.fadingComplete = self.fadingComplete and true;
                object.alpha = 1;
                object.fadingComplete = true;
                object:SetAlpha(1);
            else
                self.fadingComplete = false;
            end

            if not object.fadingComplete then
                object:SetAlpha(object.alpha);
            end
        end

        if self.fadingComplete then
            self:SetScript("OnUpdate", nil);
            self.fadingDirection = nil;
        end
    end

    local function FadeOutMessages_OnUpdate(self, elapsed)
        self.fadingComplete = true;

        for i, object in ipairs(self.activeObjects) do
            if object.delay < 0 then
                object.delay = object.delay + elapsed;
                self.fadingComplete = false;
            else
                object.alpha = object.alpha - FADE_MULTIPLIER_MSG_OUT*elapsed;
                if object.alpha <= 0 then
                    self.fadingComplete = self.fadingComplete and true;
                    object.alpha = 0;
                    object.fadingComplete = true;
                    object:SetAlpha(0);
                else
                    self.fadingComplete = false;
                end

                if not object.fadingComplete then
                    object:SetAlpha(object.alpha);
                end
            end
        end

        if self.fadingComplete then
            self:SetScript("OnUpdate", nil);
            self.fadingDirection = nil;
        end
    end

    function MessageFader:GetActiveObjects(isFadingIn, fromMouseMotion)
        local tbl = {};
        local n = 0;
        local now = GetRelativeTime();
        for _, object in ipairs(ScrollViewDataProvider.objects) do
            if object:IsShown() then
                n = n + 1;
                tbl[n] = object;
                object.alpha = object:GetAlpha();
                object.fadingComplete = (isFadingIn and object.alpha >= 1) or ((not isFadingIn) and object.alpha <= 0);
                if fromMouseMotion then
                    object.delay = 0;
                else
                    object.delay = now - ((ScrollViewDataProvider:GetAddedTime(object.dataIndex) or now) + FADE_MESSAGE_AFTER);
                end
            elseif isFadingIn then
                object:SetAlpha(1);
            end
        end
        self.activeObjects = tbl;
    end

    function MessageFader:FadeInAllActiveMessages(fromMouseMotion)
        self:GetActiveObjects(true, fromMouseMotion);
        self.fadingDirection = 1;
        self:SetScript("OnUpdate", FadeInMessages_OnUpdate);
    end

    function MessageFader:FadeOutMessages(fromMouseMotion)
        if fromMouseMotion then
            FADE_MULTIPLIER_MSG_OUT = FADE_MULTIPLIER_MSG_OUT_MANUAL;
        else
            FADE_MULTIPLIER_MSG_OUT = FADE_MULTIPLIER_MSG_OUT_AUTO;
        end
        self:GetActiveObjects(false, fromMouseMotion);
        self.fadingDirection = -1;
        self:SetScript("OnUpdate", FadeOutMessages_OnUpdate);
    end

    function MessageFader:FadeOutMessagesInstantly()
        for _, object in ipairs(ScrollViewDataProvider.objects) do
            object:SetAlpha(0);
            object.alpha = 0;
        end
        self.fadingDirection = -1;
        self:SetScript("OnUpdate", nil);
    end

    function MessageFader:IsFading()
        return self.fadingDirection ~= nil
    end

    function MessageFader:IsFadingIn()
        return self.fadingDirection == 1
    end

    function MessageFader:IsFadingOut()
        return self.fadingDirection == -1
    end
end

function ChatFrame:AddMessage(text, name, event)
    local type = EventIndex[event];
    local prefix = ChatEventData[event].prefix;

    if event == "CHAT_MSG_MONSTER_EMOTE" then
        if find(text, "%%s") then
            text = text:format(name);
        else
            text = gsub(text, "%%", "");
        end
    end

    if prefix then
        text = format(prefix, name) .. text;
    end
    --print(text);
    ScrollViewDataProvider:AddContent(
        {text, type, GetRelativeTime()}
    );
end


local function HiddenFrame_OnUpdate_FadeIn(self, elapsed)
    self.alpha = self.alpha + FADE_MULTIPLIER_UI_IN*elapsed;
    if self.alpha >= 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    end
    self:SetAlpha(self.alpha);
end

local function HiddenFrame_OnUpdate_FadeOut(self, elapsed)
    self.alpha = self.alpha - FADE_MULTIPLIER_UI_OUT*elapsed;
    if self.alpha <= 0 then
        self.alpha = 0;
        self:SetScript("OnUpdate", nil);
        self:Hide();
    end
    self:SetAlpha(self.alpha);
end

function ChatFrame:OnMouseFocusGained()
    self.isFocused = true;
    self:FadeInHiddenFrame();
    MessageFader:FadeInAllActiveMessages();
end

function ChatFrame:OnMouseFocusLost()
    --self:SetScript("OnEnter", self.OnEnter);
    self.isFocused = false;
    self:FadeOutHiddenFrame();
    MessageFader:FadeOutMessages(true);
end

function ChatFrame:OnMouseWheelCallback(delta)
    if not self.isFocused then
        self:OnMouseFocusGained();
    end
end

function ChatFrame:FadeInHiddenFrame()
    HiddenFrame.alpha = HiddenFrame:GetAlpha();
    HiddenFrame:SetScript("OnUpdate", HiddenFrame_OnUpdate_FadeIn);
    HiddenFrame:Show();
end

function ChatFrame:FadeOutHiddenFrame()
    HiddenFrame.alpha = HiddenFrame:GetAlpha();
    HiddenFrame:SetScript("OnUpdate", HiddenFrame_OnUpdate_FadeOut);
    HiddenFrame:Show();
end

function ChatFrame:HideHiddenFrame()
    HiddenFrame:Hide();
    HiddenFrame:SetAlpha(0);
    HiddenFrame.alpha = 0;
end

function ChatFrame:UpdateFocused()
    if (self.isFocused and self:IsMouseOver()) or ((not self.isFocused) and self:IsMouseOver(0, 0, 0, FRAME_HITRECT_SHIRNK_RIGHT)) or (ScrollView:IsDraggingThumb()) then
        if not self.isFocused then
            self:OnMouseFocusGained();
        end
    else
        if self.isFocused then
            self:OnMouseFocusLost();
        end
    end
end

function ChatFrame:SetFrameBaseOffset(baseOffset)
    self.baseOffset = baseOffset;
end

function ChatFrame:SetFrameOffsetY(offsetY)
    ChatFrame:SetPoint("BOTTOMLEFT", nil, "BOTTOM", self.baseOffset, offsetY);
end

function ChatFrame:OnShow()
    self:UpdateFocused();
    self.t = 0;
    self:SetScript("OnUpdate", self.OnUpdate);

    local now = GetRelativeTime();
    if self.lastHiddenTime and (now - self.lastHiddenTime > 10) then
        if not ScrollView:IsAtBottom() then
            ScrollView:ScrollToBottom();
        end
    end

    UpdateTextureSliceScale(self.Background);
end

function ChatFrame:OnHide()
    self.t = 0;
    self:SetScript("OnUpdate", nil);
    self.lastHiddenTime = GetRelativeTime();
    self:HideHiddenFrame();
    if self.isFocused then
        self.isFocused = false;
        MessageFader:FadeOutMessagesInstantly();
    end
end

function ChatFrame:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.5 then
        self.t = 0;
        self:UpdateFocused();
    end
end

ChatFrame:SetScript("OnShow", ChatFrame.OnShow);
ChatFrame:SetScript("OnHide", ChatFrame.OnHide);
--ChatFrame:SetScript("OnEnter", ChatFrame.OnEnter);

function ChatFrame:OnEvent(event, ...)
    if ChatEventData[event] ~= nil then
        local text, name = ...
        self:AddMessage(text, name, event);
    end
end

function ChatFrame:ListenEvents(state)
    if state then
        for event in pairs(EventIndex) do
            self:RegisterEvent(event);
        end
        self:SetScript("OnEvent", self.OnEvent);
    else
        for event in pairs(EventIndex) do
            self:UnregisterEvent(event);
        end
        self:SetScript("OnEvent", nil);
    end
end

function ChatFrame:SetEnabled(enabled)
    self.isEnabled = enabled;
    self:ListenEvents(enabled);
    self:SetShown(enabled);
end


do  --Hide ChatFrame when UIParent is visible
    function ChatFrame:UpdateVisibility(uiParentShown)
        if self.isEnabled then
            if uiParentShown == nil then
                --uiParentShown = UIParent:IsShown();
                uiParentShown = false;
            end
            if uiParentShown then
                self:Hide();
            else
                self:Show();
                MessageFader:FadeOutMessagesInstantly();
            end
        end
    end

    addon.CallbackRegistry:Register("UIParent.Show", ChatFrame.UpdateVisibility, ChatFrame);
    --addon.CallbackRegistry:Register("UIParent.Hide", ChatFrame.UpdateVisibility, ChatFrame);
    addon.CallbackRegistry:Register("DialogueUI.Show", ChatFrame.UpdateVisibility, ChatFrame);
end


do  --Clipboard
    local function CopyTextButton_OnClick(self)
        if addon.Clipboard:CloseIfFromSameSender(self) then
            return
        end
        ChatFrame:SendContentToClipboard();
    end

    local themeID = 2;  --Dark
    local CopyTextButton = addon.CreateCopyTextButton(ChatFrame.HiddenFrame, CopyTextButton_OnClick, themeID);
    CopyTextButton:SetPoint("TOPRIGHT", ChatFrame, "TOPRIGHT", -2, -2);

    function ChatFrame:SendContentToClipboard()
        local str;

        for i, data in ipairs(ScrollViewDataProvider.content) do
            if i == 1 then
                str = data[1];
            else
                str = str.."\n"..data[1];
            end
        end

        if str then
            addon.Clipboard:ShowContent(str, CopyTextButton);
        end
    end
end


do
    local function Settings_HideUI(dbValue)
        local state = GetDBBool("HideUI") and GetDBBool("ShowChatWindow");
        ChatFrame:SetEnabled(state);
    end
    addon.CallbackRegistry:Register("SettingChanged.HideUI", Settings_HideUI);
    addon.CallbackRegistry:Register("SettingChanged.ShowChatWindow", Settings_HideUI);
end


--[[
function Debug_AddMessage()
    local msg = "Shipping lanes... supplies... You bore me to death! We need nothing more than the warrior spirit of the Horde, Saurfang! Now that we are firmly entrenched in this frozen wasteland, nothing shall stop us!"
    ChatFrame:AddMessage(msg, "Garrosh Hellscream", "CHAT_MSG_MONSTER_SAY");
end
--]]

--[[
do  --Debug
    local MESSAGE_TYPES = {
        "MONSTER_SAY",
        "MONSTER_EMOTE",
        "MONSTER_YELL",
        "MONSTER_WHISPER",
        "MONSTER_BOSS_EMOTE",
        "MONSTER_BOSS_WHISPER",
    };

    local function round(n)
        return math.floor(n * 1000 + 0.5)/1000
    end

    local Colors = {};


    C_Timer.After(0.5, function()
        for _, v in ipairs(MESSAGE_TYPES) do
            local r, g, b, events = GetMessageTypeColor(v);
            local event = events[1];
            r = round(r);
            g = round(g);
            b = round(b);
            print(v, r, g, b);
            Colors[event] = {r, g, b};
        end
        DialogueUI_DB.Colors = Colors;
    end)
end
--]]