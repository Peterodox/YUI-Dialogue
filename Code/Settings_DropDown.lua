local _, addon = ...
local API = addon.API;

local MENU_PADDING_V = 8;
local MAX_BUTTON_PER_PAGE = 8;
local MENU_BUTTON_WIDTH = 120;
local MENU_BUTTON_HEIGHT = 24;
local MENU_BUTTON_MAX_WIDTH = 192;
local BUTTON_TEXT_OFFSET_X = 12;
local SCROLLBAR_PADDING = 8;
local SCROLLBAR_WIDTH = 12;
local SCROLLBAR_SIZE = SCROLLBAR_WIDTH + MENU_PADDING_V + SCROLLBAR_PADDING;
local BUTTON_TEXT_FONT = "DUIFont_Quest_Paragraph";

local UNBOUND_MENU_BUTTON_WIDTH = MENU_BUTTON_WIDTH;
local DEFAULT_MENU_WIDTH = MENU_BUTTON_WIDTH + SCROLLBAR_SIZE;
local DEFAULT_MENU_HEIGHT = MENU_BUTTON_HEIGHT * MAX_BUTTON_PER_PAGE;

local DropDownMenu;
local DropDownMenuMixin = {};
local UtilityFontString;


local MenuButtonMixin = {};

function MenuButtonMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    self.ButtonText = self:CreateFontString(nil, "OVERLAY", BUTTON_TEXT_FONT);
    self.ButtonText:SetPoint("LEFT", self, "LEFT", BUTTON_TEXT_OFFSET_X, 0);
    self.ButtonText:SetPoint("RIGHT", self, "RIGHT", -BUTTON_TEXT_OFFSET_X + 1, 0);
    self.ButtonText:SetJustifyV("MIDDLE");
    self.ButtonText:SetMaxLines(1);
    self:SetTextAlignment("LEFT");
end

function MenuButtonMixin:SetButtonText(text)
    self.ButtonText:SetText(text);
end

function MenuButtonMixin:SetData(data)
    self:SetButtonText(data[1]);
    self.ButtonText:SetFont(data[2], 12, "");
    self.fontFile = data[2];
end

function MenuButtonMixin:OnClick(button)
    if button == "LeftButton" then
        addon.FontUtil:SetFontByFile(self.fontFile);
    elseif button == "RightButton" then
        DropDownMenu:Close();
    end
end

function MenuButtonMixin:OnEnter()
    DropDownMenu:HighlightButton(self);
end

function MenuButtonMixin:OnLeave()
    DropDownMenu:HighlightButton(nil);
end

function MenuButtonMixin:SetTextAlignment(justifyH)
    self.ButtonText:SetJustifyH(justifyH);
end

local function CreateMenuButton(parent)
    local b = CreateFrame("Button", nil, parent);
    API.Mixin(b, MenuButtonMixin);

    b:SetScript("OnEnter", b.OnEnter);
    b:SetScript("OnLeave", b.OnLeave);
    b:SetScript("OnClick", b.OnClick);

    b:OnLoad();

    b:SetWidth(MENU_BUTTON_WIDTH);
    b:SetHeight(MENU_BUTTON_HEIGHT);

    return b
end


local ScrollViewDataProvider = {};
do
    local OFFSET_PER_SCROLL = MENU_BUTTON_HEIGHT;
    ScrollViewDataProvider.content = {};
    ScrollViewDataProvider.numEntry = 0;
    ScrollViewDataProvider.objects = {};

    local function GetTextWidth(text)
        if not UtilityFontString then
            UtilityFontString = DropDownMenu:CreateFontString(nil, "BACKGROUND", BUTTON_TEXT_FONT);
            UtilityFontString:SetJustifyH("LEFT");
            UtilityFontString:SetPoint("TOP", DropDownMenu, "TOP", 0, 0);
            UtilityFontString:Hide();
        end
        UtilityFontString:SetText(text);
        return UtilityFontString:GetUnboundedStringWidth();
    end

    function ScrollViewDataProvider:GetSpacing()
        return 0
    end

    function ScrollViewDataProvider:SetContent(content)
        self.content = content;
        self:CalculateAllExtent();
        if self.isVisible then
            self:UpdateView();
        else
            self.isDisplayDirty = true;
        end
    end

    function ScrollViewDataProvider:CalculateAllExtent()
        local fromOffset = MENU_PADDING_V;

        self.extent = {};
        self.extent[0] = 0 + fromOffset;
        self.extent[1] = 0 + fromOffset;

        local textWidth;
        local maxTextWidth = 0;

        for i = 1, #self.content do
            self.extent[i + 1] = MENU_BUTTON_HEIGHT * i + fromOffset;
            textWidth = GetTextWidth(self.content[i][1]);
            if textWidth > maxTextWidth then
                maxTextWidth = textWidth;
            end
        end

        self.maxTextWidth = API.Round(2*BUTTON_TEXT_OFFSET_X + maxTextWidth);
    end
    ScrollViewDataProvider:CalculateAllExtent();

    function ScrollViewDataProvider:GetExtent()
        return self.extent
    end

    function ScrollViewDataProvider:UpdateView()
        self.isDisplayDirty = nil;
        self.owner:OnContentChanged();
    end

    function ScrollViewDataProvider:GetMaxDataIndex()
        return #self.content
    end

    function ScrollViewDataProvider:GetStep()
        return OFFSET_PER_SCROLL;
    end

    function ScrollViewDataProvider:GetMaxExtent()
        return self.extent[#self.extent] + MENU_PADDING_V
    end

    function ScrollViewDataProvider:CreateObject()
        local object = CreateMenuButton(DropDownMenu.ScrollView);
        table.insert(self.objects, object);
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

            object:SetData(data);
        end

        return true
    end

    function ScrollViewDataProvider:OnShow(scrollView)
        self.isVisible = true;
        if self.isDisplayDirty then
            self:UpdateView();
        end
    end

    function ScrollViewDataProvider:OnHide(scrollView)
        self.isVisible = false;
    end

    function ScrollViewDataProvider:OnViewUpdated()

    end
end


local function DropDown_OnLoad(self)
    self:SetSize(8, 8);

    self.textures = {};

    local bg = self:CreateTexture(nil, "BACKGROUND");
    table.insert(self.textures, bg);
    self.Background = bg;
    local margin = 12;
    bg:SetTextureSliceMargins(margin, margin, margin, margin);
    bg:SetTextureSliceMode(1);
    bg:SetAllPoints(true);
    bg:SetTexCoord(0, 0.25, 0, 0.25);

    self.ButtonHighlight = CreateFrame("Frame", nil, self);
    self.ButtonHighlight:Hide();
    local hl = self.ButtonHighlight:CreateTexture(nil, "BACKGROUND", nil, 1);
    table.insert(self.textures, hl);
    local margin = 8;
    hl:SetTextureSliceMargins(margin, margin, margin, margin);
    hl:SetTextureSliceMode(1);
    hl:SetTexCoord(0.265625, 0.515625, 0, 0.125);
    hl:SetAllPoints(true);

    local ScrollView = addon.CreateScrollView(self);
    self.ScrollView = ScrollView;
    ScrollView:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -2);
    ScrollView:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 2);

    local ScrollBar = addon.CreateScrollBar(self);
    self.ScrollBar = ScrollBar;
    local inset = SCROLLBAR_PADDING;
    ScrollBar:SetPoint("TOPRIGHT", ScrollView, "TOPRIGHT", -inset, -inset);
    ScrollBar:SetPoint("BOTTOMRIGHT", ScrollView, "BOTTOMRIGHT", -inset, inset);
    ScrollBar:SetOwner(ScrollView);
    ScrollBar:SetAlwaysVisible(false);
    ScrollBar:ShowScrollToBottomButton(false);
    ScrollBar:SetTheme(1);
    ScrollBar:Show();

    ScrollView:SetScrollBar(ScrollBar);

    self:LoadTheme();
end

function DropDownMenuMixin:OnHide()
    self:Hide();
end

function DropDownMenuMixin:LoadTheme()
    if self.textures then
        local file = addon.ThemeUtil:GetTextureFile("DropDown-UI.png");
        for _, texture in pairs(self.textures) do
            texture:SetTexture(file);
        end

        if addon.ThemeUtil:IsDarkMode() then
            self.ScrollBar:SetTheme(2);
        else
            self.ScrollBar:SetTheme(1);
        end
    end
end

function DropDownMenuMixin:HighlightButton(button)
    self.ButtonHighlight:Hide();
    self.ButtonHighlight:ClearAllPoints();

    if button and button:IsEnabled() then
        self.ButtonHighlight:SetParent(button);
        self.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 2, 0);
        self.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
        self.ButtonHighlight:SetFrameLevel(button:GetFrameLevel());
        self.ButtonHighlight:Show();
    end
end

function DropDownMenuMixin:SetContent(content)
    ScrollViewDataProvider:SetContent(content);
    self.ScrollView:OnContentChanged();
    self.ScrollView:ScrollToTop();
    self:Layout();
end

function DropDownMenuMixin:Layout()
    local height;
    local contentHeight = self.ScrollView:GetMaxExtent();

    if contentHeight > DEFAULT_MENU_HEIGHT then
        height = DEFAULT_MENU_HEIGHT;
    else
        height = contentHeight;
    end

    self:SetHeight(height);

    self.ScrollView:OnSizeChanged();
    self.ScrollBar:OnSizeChanged();
    self.ScrollView:UpdateScrollRange();
    self.ScrollBar:UpdateThumbSize();

    local maxTextWidth = ScrollViewDataProvider.maxTextWidth;
    local menuButtonWidth;

    if maxTextWidth > MENU_BUTTON_MAX_WIDTH then
        menuButtonWidth = MENU_BUTTON_MAX_WIDTH;
    else
        menuButtonWidth = maxTextWidth;
    end

    local width;

    if self.ScrollView:IsScrollable() then
        width = menuButtonWidth + SCROLLBAR_SIZE;
    else
        width = menuButtonWidth;
    end

    self:SetWidth(width);

    MENU_BUTTON_WIDTH = menuButtonWidth;

    for _, object in pairs(ScrollViewDataProvider.objects) do
        object:SetWidth(menuButtonWidth)
    end
end

function DropDownMenuMixin:Close()
    self:Hide();
end

local function GetDropDownMenu(parent)
    if not DropDownMenu then
        local f = CreateFrame("Frame", nil, parent);
        f:EnableMouse(true);
        API.Mixin(f, DropDownMenuMixin);

        DropDown_OnLoad(f);

        f:SetPoint("CENTER", nil, "CENTER", 0, 0);
        f:SetSize(DEFAULT_MENU_WIDTH, DEFAULT_MENU_HEIGHT);
        f.ScrollView:OnSizeChanged();
        f.ScrollBar:OnSizeChanged();

        f:SetScript("OnHide", f.OnHide);
        f.ScrollView:SetDataProvider(ScrollViewDataProvider);

        DropDownMenu = f;
    end

    return DropDownMenu
end
addon.GetDropDownMenu = GetDropDownMenu;


do
    --Debug
    local content1 = {
        {"Test 1", 1},
        {"Test 2", 1},
        {"Test 3", 1},
        {"Test 4", 1},
        {"Test 5", 1},
        {"Test 6", 1},
        {"Test 7", 1},
        {"Test 8", 1},
        --{"Test 9", 1},
        --{"Test 10", 1},
        --{"Test 11", 1},
    };

    local content2 = {
        {"Test 1", 1},
        {"Test 2", 1},
        {"Test 3", 1},
        {"Test 4", 1},
        {"Test 5", 1},
        {"Test 6", 1},
        {"Test 7", 1},
        {"Test 8", 1},
        {"Test 9", 1},
        {"Test 10", 1},
        {"Test 11", 1},
        {"Test 12", 1},
    };
end