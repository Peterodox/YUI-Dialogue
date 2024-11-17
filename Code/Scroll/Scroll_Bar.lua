local _, addon = ...
local API = addon.API;


local BUTTON_SIZE = 12;
local RAIL_WIDTH = 4;
local THUMB_SHRINK_MULTIPILER = (BUTTON_SIZE - RAIL_WIDTH)*10;
local FILE_PATH = "Interface/AddOns/DialogueUI/Art/Theme_Shared/";

local SharedUpdater = CreateFrame("Frame");

do
    local GetCursorPosition = GetCursorPosition;

    SharedUpdater.x, SharedUpdater.y = 0, 0;

    function SharedUpdater:GetCursorDelta()
        local x, y = GetCursorPosition();
        x = x / self.scale;
        y = y / self.scale;
        local deltaX = x - self.x;
        local deltaY = y - self.y;
        self.x, self.y = x, y;
        return deltaX, deltaY
    end

    function SharedUpdater:Stop()
        self:SetScript("OnUpdate", nil);
    end

    function SharedUpdater:OnUpdate_RepeatClick(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.25 then
            self.t = 0;
            if self.widget:IsEnabled() then     --widget: Arrow Button
                self.widget:Click();
            else
                self:Stop();
            end
        end
    end

    function SharedUpdater:OnUpdate_DragThumb(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.016 then     --Drag Update Frequency
            self.t = 0;
            local deltaX, deltaY = self:GetCursorDelta();
            if deltaY ~= 0 then
                self.widget:SetScrollOffsetByCursorDelta(deltaY);   --widget:Slider
            end
        end
    end

    function SharedUpdater:SetParentWidget(widget)
        self.scale = 1;
        self:Stop();
        self.widget = widget;
        self.t = 0;
        self:SetParent(widget);
    end

    function SharedUpdater:StartDraggingThumb(slider)
        self:SetParentWidget(slider);
        self:GetCursorDelta();
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_DragThumb);
    end

    function SharedUpdater:StartClickAndHold(arrowButton)
        self:SetParentWidget(arrowButton);
        self.t = -0.25;
        self:SetScript("OnUpdate", self.OnUpdate_RepeatClick);
    end

    SharedUpdater:SetScript("OnHide", function()
        SharedUpdater:Stop();
    end);
end


local ThemeBrown = {};
function ThemeBrown:SetDisabledColor(texture)
    texture:SetVertexColor(0.45, 0.29, 0.16, 0.2);
end

function ThemeBrown:SetNormalColor(texture)
    texture:SetVertexColor(0.44, 0.20, 0.125, 1);
end

function ThemeBrown:SetHighlightColor(texture)
    texture:SetVertexColor(0.55, 0.30, 0.22, 1);
end

function ThemeBrown:SetPushedColor(texture)
    texture:SetVertexColor(0.72, 0.52, 0.33, 1);
end


local ThemeDark = {};

function ThemeDark:SetDisabledColor(texture)
    texture:SetVertexColor(0.16, 0.16, 0.16, 1);
end

function ThemeDark:SetNormalColor(texture)
    texture:SetVertexColor(0.33, 0.33, 0.33, 1);
end

function ThemeDark:SetHighlightColor(texture)
    texture:SetVertexColor(0.6, 0.6, 0.6, 1);
end

function ThemeDark:SetPushedColor(texture)
    texture:SetVertexColor(0.72, 0.72, 0.72, 1);
end


local ScrollBarMixin = {};

function ScrollBarMixin:SetRailColor(r, g, b, a)
    self.Rail.Texture:SetVertexColor(r, g, b, a);
end

function ScrollBarMixin:SetThumbColor(r, g, b)
    self.Thumb.Texture:SetVertexColor(r, g, b);
end

function ScrollBarMixin:ShowArrows(state)

end

function ScrollBarMixin:OnHide()
    self:SetScript("OnUpdate", nil);
end

function ScrollBarMixin:SetAlwaysVisible(alwaysVisible)
    self.alwaysVisible = alwaysVisible == true;
end

function ScrollBarMixin:UpdateThumbSize()
    local height;
    local thumbRange;

    if self.owner then  --scrollView
        local viewSize = self.owner:GetViewSize();
        local scrollRange = self.owner:GetScrollRange();
        if viewSize <= 0 or scrollRange <= 0 then
            scrollRange = 0;
            if not self.alwaysVisible then
                self:Hide();
            end
            self.Thumb:Hide();
        else
            self.Thumb:Show();
            self:Show();
        end

        if (scrollRange + viewSize) == 0 then
            height = BUTTON_SIZE;
        else
            height = self.railSize * viewSize / (scrollRange + viewSize);
        end

        if height < BUTTON_SIZE then
            height = BUTTON_SIZE
        end
        height = API.Round(height);
        thumbRange = self.railSize - height;
        if thumbRange <= 0 then
            self.cursorScrollSize = 0;
        else
            self.cursorScrollSize = scrollRange / thumbRange;
        end
    else
        height = BUTTON_SIZE;
        thumbRange = 0;
        self.cursorScrollSize = 0;
    end

    self.Thumb:SetHeight(height);
    self.thumbHeight = height;
    self.thumbRange = thumbRange;
end

function ScrollBarMixin:UpdateThumbPosition(scrollProgress)
    local buttonHandled;

    if not scrollProgress then
        local scrollOffset = self.owner:GetScrollOffset();
        local scrollRange = self.owner:GetScrollRange();

        if scrollRange <= 0 then
            scrollProgress = 0;
            buttonHandled = true;
            self.UpArrow:Disable();
            self.DownArrow:Disable();
            self.BottomArrow:Disable();
        elseif scrollOffset <= 0 then
            scrollProgress = 0;
        else
            scrollProgress = scrollOffset/scrollRange;
        end
    end

    if not self.thumbHeight then
        self:UpdateThumbSize();
    end

    self.Thumb:SetPoint("TOP", self.Rail, "TOP", 0, -self.thumbRange * scrollProgress);

    if not buttonHandled then
        if scrollProgress < 0.995 then
            self.DownArrow:Enable();
            self.BottomArrow:Enable();
        else
            self.DownArrow:Disable();
            self.BottomArrow:Disable();
            self.NewMessageAlert:Hide();
        end

        if scrollProgress >= 0.005 then
            self.UpArrow:Enable();
        else
            self.UpArrow:Disable();
            self.Theme:SetDisabledColor(self.UpArrow.Texture);
        end
    end
end

function ScrollBarMixin:SetScrollOffsetByCursorDelta(cursorDelta)
    if not self.cursorScrollSize then
        self:UpdateThumbSize();
    end
    self.owner:ScrollBy(self.cursorScrollSize * -cursorDelta);
end

function ScrollBarMixin:OnSizeChanged()
    self.railSize = self.Rail:GetHeight();
    self:UpdateThumbSize();
    self:UpdateThumbPosition();
end

function ScrollBarMixin:SetHasNewMessage()
    self.NewMessageAlert:Show();
end

function ScrollBarMixin:SetOwner(scrollView)
    self.owner = scrollView;
    self:OnSizeChanged();
end

function ScrollBarMixin:Detach()
    self:Hide();
    self:ClearAllPoints();
end

function ScrollBarMixin:IsDraggingThumb()
    return self.Thumb.mouseDown
end

function ScrollBarMixin:ShowScrollToBottomButton(state)
    self.BottomArrow:SetShown(state);

    if state then
        self.DownArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, 1.5*BUTTON_SIZE);
    else
        self.DownArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, 0);
    end

    self:OnSizeChanged();
end

function ScrollBarMixin:SetTheme(themeID)
    if themeID == 1 then
        self.Theme = ThemeBrown;
    elseif themeID == 2 then    --Default
        self.Theme = ThemeDark;
    end

    self.Theme:SetNormalColor(self.UpArrow.Texture);
    self.Theme:SetNormalColor(self.DownArrow.Texture);
    self.Theme:SetNormalColor(self.BottomArrow.Texture);
    self.Theme:SetNormalColor(self.Thumb.Texture);
    self.Theme:SetDisabledColor(self.Rail.Texture);
end


local function ArrowButton_OnEnter(self)
    if self.mouseDown then
        self.parent.Theme:SetPushedColor(self.Texture);
    else
        self.parent.Theme:SetHighlightColor(self.Texture);
    end
end

local function ArrowButton_OnLeave(self)
    if not self.mouseDown then
        self.parent.Theme:SetNormalColor(self.Texture);
    end
end

local function ArrowButton_OnMouseDown(self)
    if not self:IsEnabled() then return end;
    self.mouseDown = true;
    self.parent.Theme:SetPushedColor(self.Texture);
    SharedUpdater:StartClickAndHold(self);
end

local function ArrowButton_OnMouseUp(self)
    self.mouseDown = nil;
    SharedUpdater:Stop();

    if not self:IsEnabled() then return end;
    if self:IsMouseOver() then
        self.parent.Theme:SetHighlightColor(self.Texture);
    else
        self.parent.Theme:SetNormalColor(self.Texture);
    end
end

local function ArrowButton_OnEnable(self)
    if not self:IsMouseOver() then
        self.parent.Theme:SetNormalColor(self.Texture);
    end
end

local function ArrowButton_OnDisable(self)
    self.parent.Theme:SetDisabledColor(self.Texture);
end


local function ArrowButton_OnClick_Up(self)
    self.parent.owner:OnMouseWheel(1);
end

local function ArrowButton_OnClick_Down(self)
    self.parent.owner:OnMouseWheel(-1);
end

local function ArrowButton_OnClick_ScrollToBottom(self)
    self.parent.owner:ScrollToBottom();
end

local function CreateArrowButton(bar, onClickFunc)
    local b = CreateFrame("Button", nil, bar);
    b.parent = bar;

    b:SetSize(BUTTON_SIZE, BUTTON_SIZE);

    b:SetScript("OnEnter", ArrowButton_OnEnter);
    b:SetScript("OnLeave", ArrowButton_OnLeave);
    b:SetScript("OnMouseDown", ArrowButton_OnMouseDown);
    b:SetScript("OnMouseUp", ArrowButton_OnMouseUp);
    b:SetScript("OnEnable", ArrowButton_OnEnable);
    b:SetScript("OnDisable", ArrowButton_OnDisable);
    b:SetScript("OnClick", onClickFunc);

    b.Texture = b:CreateTexture(nil, "ARTWORK");
    b.Texture:SetAllPoints(true);
    b.Texture:SetTexture(FILE_PATH.."ScrollBar-Vertical-Buttons.png");

    return b
end



local function Thumb_OnUpdate_Expand(self, elapsed)
    self.width = self.width + THUMB_SHRINK_MULTIPILER*elapsed;
    if self.width >= BUTTON_SIZE then
        self.width = BUTTON_SIZE;
        self:SetScript("OnUpdate", nil);
    end
    self.Texture:SetWidth(self.width);
end

local function Thumb_OnUpdate_Shrink(self, elapsed)
    self.width = self.width - THUMB_SHRINK_MULTIPILER*elapsed;
    if self.width <= RAIL_WIDTH then
        self.width = RAIL_WIDTH;
        self:SetScript("OnUpdate", nil);
    end
    self.Texture:SetWidth(self.width);
end

local function Thumb_OnEnter(self)
    ArrowButton_OnEnter(self)
    self:SetScript("OnUpdate", Thumb_OnUpdate_Expand);
end

local function Thumb_OnLeave(self)
    if not self.mouseDown then
        ArrowButton_OnLeave(self);
        self:SetScript("OnUpdate", Thumb_OnUpdate_Shrink);
    end
end

local function Thumb_OnMouseDown(self)
    self.mouseDown = true;
    self.parent.Theme:SetPushedColor(self.Texture);
    SharedUpdater:StartDraggingThumb(self.parent);
end

local function Thumb_OnMouseUp(self)
    self.mouseDown = nil;
    if self:IsMouseOver() then
        self.parent.Theme:SetHighlightColor(self.Texture);
    else
        Thumb_OnLeave(self);
    end
    SharedUpdater:Stop();
end

local function Thumb_OnHide(self)
    if self.mouseDown then
        self.mouseDown = nil;
        Thumb_OnLeave(self);
    end
end

local function CreateScrollBar(parent)
    local f = CreateFrame("Frame", nil, parent);
    f:SetSize(BUTTON_SIZE, 224);

    f:SetFlattensRenderLayers(true);

    local UpArrow = CreateArrowButton(f, ArrowButton_OnClick_Up);
    f.UpArrow = UpArrow;
    UpArrow.Texture:SetTexCoord(0, 0.5, 0, 0.5);
    UpArrow:SetPoint("TOP", f, "TOP", 0, 0);

    local DownArrow = CreateArrowButton(f, ArrowButton_OnClick_Down);
    f.DownArrow = DownArrow;
    DownArrow.Texture:SetTexCoord(0.5, 1, 0, 0.5);
    DownArrow:SetPoint("BOTTOM", f, "BOTTOM", 0, 1.5*BUTTON_SIZE);

    local BottomArrow = CreateArrowButton(f, ArrowButton_OnClick_ScrollToBottom);
    f.BottomArrow = BottomArrow;
    BottomArrow.Texture:SetTexCoord(0, 0.5, 0.5, 1);
    BottomArrow:SetPoint("BOTTOM", f, "BOTTOM", 0, 0);
    BottomArrow.RedDot = BottomArrow:CreateTexture(nil, "OVERLAY");
    BottomArrow.RedDot:SetSize(BUTTON_SIZE, BUTTON_SIZE);
    BottomArrow.RedDot:SetTexture(FILE_PATH.."ScrollBar-Vertical-Buttons.png");
    BottomArrow.RedDot:SetTexCoord(0.5, 1, 0.5, 1);
    BottomArrow.RedDot:SetPoint("CENTER", BottomArrow, "TOPRIGHT", -1, -1);
    BottomArrow.RedDot:Hide();
    f.NewMessageAlert = BottomArrow.RedDot;

    local Rail = CreateFrame("Frame", nil, f);
    f.Rail = Rail;
    Rail:SetPoint("TOP", UpArrow, "BOTTOM", 0, -2);
    Rail:SetPoint("BOTTOM", DownArrow, "TOP", 0, 2);
    Rail:SetWidth(RAIL_WIDTH);
    Rail.Texture = Rail:CreateTexture(nil, "BORDER");
    Rail.Texture:SetAllPoints(true);
    local corner = 2;
    Rail.Texture:SetTextureSliceMargins(corner, corner, corner, corner);
    Rail.Texture:SetTextureSliceMode(1);
    Rail.Texture:SetTexture(FILE_PATH.."ScrollBar-Vertical-Rail.png");

    local Thumb  = CreateFrame("Frame", nil, f);
    f.Thumb = Thumb;
    Thumb.parent = f;
    Thumb:SetFrameLevel(Rail:GetFrameLevel() + 5);
    Thumb:SetPoint("TOP", Rail, "TOP", 0, 0);
    Thumb:SetSize(BUTTON_SIZE, BUTTON_SIZE);
    Thumb.Texture = Thumb:CreateTexture(nil, "OVERLAY");
    Thumb.Texture:SetPoint("TOP", Thumb, "TOP", 0, 0);
    Thumb.Texture:SetPoint("BOTTOM", Thumb, "BOTTOM", 0, 0);
    Thumb.Texture:SetWidth(RAIL_WIDTH);
    Thumb.width = RAIL_WIDTH;
    local corner = 4;
    Thumb.Texture:SetTextureSliceMargins(corner, corner, corner, corner);
    Thumb.Texture:SetTextureSliceMode(1);
    Thumb.Texture:SetTexture(FILE_PATH.."ScrollBar-Vertical-Thumb.png");

    Thumb:SetScript("OnEnter", Thumb_OnEnter);
    Thumb:SetScript("OnLeave", Thumb_OnLeave);
    Thumb:SetScript("OnMouseDown", Thumb_OnMouseDown);
    Thumb:SetScript("OnMouseUp", Thumb_OnMouseUp);
    Thumb:SetScript("OnHide", Thumb_OnHide);

    API.Mixin(f, ScrollBarMixin);

    f:EnableMouse(true);

    f:SetScript("OnHide", f.OnHide);
    f:SetScript("OnSizeChanged", f.OnSizeChanged);

    f:SetTheme(1);

    UpArrow:Disable();

    return f
end
addon.CreateScrollBar = CreateScrollBar;