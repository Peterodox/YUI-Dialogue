local _, addon = ...
local API = addon.API;
local TooltipFrame = addon.SharedTooltip;
local Clamp = API.Clamp;
local GetCursorPosition = GetCursorPosition;

--widgets are created on-use

local FRAME_WIDTH = 480;
local FRAME_HEIGHT = 480
local FRAME_INSET = 12;
local EDITBOX_TEXT_INSET = 4;
local SCROLLBAR_WIDTH = 12;


local Clipboard = CreateFrame("Frame");
addon.Clipboard = Clipboard;
Clipboard:Hide();
Clipboard:EnableMouse(true);
Clipboard:SetToplevel(true);

local CopyTextButtons = {};

local EditBoxMixin = {};
do
    function EditBoxMixin:OnTextChanged(userInput)
        if userInput then
            Clipboard:Hide();
            return
        end

        C_Timer.After(0, function()
            self:GetParent():UpdateScrollChildRect();   --?
            self:GetParent():UpdateScrollRange();
        end);
    end

    function EditBoxMixin:OnEscapePressed()
        Clipboard:Hide();
    end

    function EditBoxMixin:OnEditFocusGained()

    end

    function EditBoxMixin:OnEditFocusLost()

    end
end


local ScrollFrameMixin = {};
do
    local OFFSET_PER_SCROLL = 24;   --two lines

    function ScrollFrameMixin:SetScrollOffset(scrollOffset)
        scrollOffset = Clamp(scrollOffset, 0, self.range);
        self.scrollOffset = scrollOffset;
        self:SetVerticalScroll(scrollOffset);
        self.scrollBar:UpdateThumbPosition();
    end

    function ScrollFrameMixin:ScrollBy(offset)
        self:SetScrollOffset(self:GetVerticalScroll() + offset)
    end

    function ScrollFrameMixin:OnMouseWheel(delta)
        if delta > 0 then
            self:ScrollBy(-OFFSET_PER_SCROLL);
        else
            self:ScrollBy(OFFSET_PER_SCROLL);
        end
    end

    function ScrollFrameMixin:ScrollToTop()
        self:SetScrollOffset(0);
    end

    function ScrollFrameMixin:ScrollToBottom()
        self:SetScrollOffset(self:GetVerticalScrollRange());
    end

    function ScrollFrameMixin:UpdateScrollRange()
        local range = self:GetVerticalScrollRange();
        if range <= 0 then
            range = 0;
            self.scrollBar:Hide();
        else
            self.scrollBar:Show();
        end

        local diff = self.range and (self.range - range) or 0;
        local resetScrollOffset = diff < -1 or diff > 1;

        self.range = range;
        self.scrollBar:UpdateThumbSize();

        if resetScrollOffset then
            self:ScrollToTop();
        end
    end

    function ScrollFrameMixin:SetScrollBar(scrollBar)
        self.scrollBar = scrollBar;
        scrollBar:SetOwner(self);
    end

    function ScrollFrameMixin:GetScrollOffset()
        return self.scrollOffset or self:GetVerticalScroll();
    end

    function ScrollFrameMixin:GetScrollRange()
        return self.range or self:GetVerticalScrollRange()
    end

    function ScrollFrameMixin:GetViewSize()
        return self:GetHeight()
    end
end

function Clipboard:StartCursorScrolling()
    self.cursorTop = self:GetTop() - FRAME_INSET;
    self.cursorBottom = self:GetBottom() + FRAME_INSET;
    self.t = 0;
    self.interval = 0.25;
    self:SetScript("OnUpdate", self.OnUpdate);
end

function Clipboard:StopCursorScrolling()
    self:SetScript("OnUpdate", nil);
    self.t = nil;
end

function Clipboard:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t >= self.interval then
        local delta;
        local _, cursorY = GetCursorPosition();
        if cursorY > self.cursorTop then
            if self.t > 0.25 then
                self.t = elapsed;
            end
            delta = (self.cursorTop - cursorY) * self.t * 10;
            self.interval = 0.016;
        elseif cursorY < self.cursorBottom then
            if self.t > 0.25 then
                self.t = elapsed;
            end
            delta = (self.cursorBottom - cursorY) * self.t * 10;
            self.interval = 0.016;
        else
            self.interval = 0.5;
        end
        self.t = 0;

        if delta then
            self.ScrollFrame:ScrollBy(delta);
        end
    end
end

function Clipboard:Init()
    self:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    self:SetFrameStrata("DIALOG");

    local bg = self:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(true);
    local corner = 16;
    bg:SetTextureSliceMargins(corner, corner, corner, corner);
    bg:SetTextureSliceMode(1);
    bg:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/ClipboardBackground.png");
    API.UpdateTextureSliceScale(bg);

    local ScrollBar = addon.CreateScrollBar(self);
    self.ScrollBar = ScrollBar;
    ScrollBar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -FRAME_INSET, -FRAME_INSET);
    ScrollBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -FRAME_INSET, FRAME_INSET);
    ScrollBar:SetAlwaysVisible(true);
    ScrollBar:SetTheme(2);
    ScrollBar:Show();

    local ScrollFrame = CreateFrame("ScrollFrame", nil, self);
    self.ScrollFrame = ScrollFrame;
    ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", FRAME_INSET, -FRAME_INSET);
    ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -(FRAME_INSET + SCROLLBAR_WIDTH + FRAME_INSET), FRAME_INSET);

    local EditBox = CreateFrame("EditBox", nil, ScrollFrame);
    self.EditBox = EditBox;
    local eidtBoxWidth = FRAME_WIDTH - 3*FRAME_INSET - SCROLLBAR_WIDTH;
    EditBox:SetFontObject("DUIFont_Quest_Quest");
    --EditBox:SetTextColor(1, 1, 1);
    EditBox:SetAutoFocus(false);
    EditBox:SetMultiLine(true);
    --EditBox:SetVisibleTextByteLimit(32);    --Not just being invisible, but truncated
    EditBox:SetHighlightColor(0, 0.471, 0.843);
    EditBox:SetPoint("TOPLEFT");
    EditBox:SetWidth(eidtBoxWidth)
    EditBox:SetHeight(1);
    EditBox:SetTextInsets(EDITBOX_TEXT_INSET, EDITBOX_TEXT_INSET, EDITBOX_TEXT_INSET, EDITBOX_TEXT_INSET);
    ScrollFrame:SetScrollChild(EditBox);

    API.Mixin(EditBox, EditBoxMixin);
    EditBox:SetScript("OnTextChanged", EditBox.OnTextChanged);
    EditBox:SetScript("OnEscapePressed", EditBox.OnEscapePressed);

    API.Mixin(ScrollFrame, ScrollFrameMixin);
    ScrollFrame:SetScript("OnMouseWheel", ScrollFrame.OnMouseWheel);
    ScrollFrame:SetScrollBar(ScrollBar);

    self.Init = nil;
end

function Clipboard:ShowContent(text, senderCopyButton)
    if self.Init then
        self:Init();
    end

    self.EditBox:SetText(text);
    self:Show();

    self.sender = senderCopyButton;
end

function Clipboard:IsFromSameSender(sender)
    return self.sender and self.sender == sender
end

function Clipboard:CloseIfFromSameSender(sender)
    if self:IsFromSameSender(sender) then
        self:Hide();
        return true
    end
end

function Clipboard:CloseIfShown()
    if self:IsShown() then
        self:Hide();
        return true
    else
        return false
    end
end

function Clipboard:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    self:RegisterEvent("GLOBAL_MOUSE_UP");
end
Clipboard:SetScript("OnShow", Clipboard.OnShow);

function Clipboard:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if self:IsMouseOver() then
            if self.EditBox:IsMouseOver() then
                self:StartCursorScrolling();
            end
        else
            for i, button in ipairs(CopyTextButtons) do
                if button:IsMouseOver() then
                    return
                end
            end
            self:Hide();
        end
    elseif event == "GLOBAL_MOUSE_UP" then
        self:StopCursorScrolling();
    end
end
Clipboard:SetScript("OnEvent", Clipboard.OnEvent);

function Clipboard:OnHide()
    self.sender = nil;
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:UnregisterEvent("GLOBAL_MOUSE_UP");
    self.EditBox:SetText("");
    self.EditBox:ClearHighlightText();
    self:StopCursorScrolling();
end
Clipboard:SetScript("OnHide", Clipboard.OnHide);


do  --Copy Text Button
    local BUTTON_SIZE = 24;
    local ICON_SIZE = 16;
    local ALPHA_UNFOCUSED = 0.6;

    local CopyTextButtonMixin = {};

    function CopyTextButtonMixin:OnEnter()
        self.Icon:SetAlpha(1);
        TooltipFrame.ShowWidgetTooltip(self);
    end

    function CopyTextButtonMixin:OnLeave()
        self.Icon:SetAlpha(ALPHA_UNFOCUSED);
        TooltipFrame.HideTooltip();
    end

    function CopyTextButtonMixin:SetTheme(themeID)
        themeID = themeID or 1;
        local x = 0.125 * (themeID - 1);
        self.Icon:SetTexCoord(x, x + 0.125, 0, 1);
    end

    local function CreateCopyTextButton(parent, onClickFunc, themeID)
        local b = CreateFrame("Button", nil, parent);
        b:SetSize(BUTTON_SIZE, BUTTON_SIZE);

        b.Icon = b:CreateTexture(nil, "OVERLAY");
        b.Icon:SetSize(ICON_SIZE, ICON_SIZE);
        b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0);
        b.Icon:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/CopyTextButton.png");
        b.Icon:SetAlpha(ALPHA_UNFOCUSED);

        API.Mixin(b, CopyTextButtonMixin);

        b:SetScript("OnClick", onClickFunc);
        b:SetScript("OnEnter", b.OnEnter);
        b:SetScript("OnLeave", b.OnLeave);

        b:SetTheme(themeID);

        table.insert(CopyTextButtons, b);

        b.tooltipText = addon.L["Copy Text"];

        return b
    end
    addon.CreateCopyTextButton = CreateCopyTextButton;
end