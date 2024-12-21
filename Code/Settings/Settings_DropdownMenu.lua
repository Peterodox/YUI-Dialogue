local _, addon = ...
local API = addon.API;
local ThemeUtil = addon.ThemeUtil;
local FontUtil = addon.FontUtil;


local BG_MAX_SIZE = 340;
local MAX_BUTTON_PER_PAGE = 8;
local BUTTON_TEXT_OFFSET_X = 12;
local BUTTON_PUSH_OFFSET = 1;
local BUTTON_HEIGHT = 24;
local BUTTON_MIN_WIDTH = 192;
local MENU_BUTTON_PADDING = 8;  --Padding (Top/Bottom)

local MainDropdownMenu;


local function CloseDropdownMenu()
    if MainDropdownMenu then
        MainDropdownMenu:Hide();
    end
end
addon.CloseDropdownMenu = CloseDropdownMenu;


local MenuButtonMixin = {};

function MenuButtonMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    self.ButtonText = self:CreateFontString(nil, "OVERLAY", "DUIFont_MenuButton_Normal");
    self.ButtonText:SetPoint("LEFT", self, "LEFT", BUTTON_TEXT_OFFSET_X, 0);
    self.ButtonText:SetPoint("RIGHT", self, "RIGHT", -BUTTON_TEXT_OFFSET_X, 0);
    self.ButtonText:SetJustifyV("MIDDLE");
    self.ButtonText:SetMaxLines(1);
    self:SetTextAlignment("LEFT");
end

function MenuButtonMixin:OnMouseDown(button)
    if button == "LeftButton" then
        self.ButtonText:SetPoint("LEFT", self, "LEFT", BUTTON_TEXT_OFFSET_X + BUTTON_PUSH_OFFSET, 0);
        self.ButtonText:SetPoint("RIGHT", self, "RIGHT", -BUTTON_TEXT_OFFSET_X + BUTTON_PUSH_OFFSET, 0);
    end
end

function MenuButtonMixin:OnMouseUp(button)
    self.ButtonText:SetPoint("LEFT", self, "LEFT", BUTTON_TEXT_OFFSET_X, 0);
    self.ButtonText:SetPoint("RIGHT", self, "RIGHT", -BUTTON_TEXT_OFFSET_X, 0);
end

function MenuButtonMixin:SetButtonText(text, autoScaling, getTextWidth)
    --self.ButtonText:SetFontObject("DUIFont_MenuButton_Normal");
    FontUtil:SetupFontStringByFontObjectName(self.ButtonText, "DUIFont_MenuButton_Normal");

    if autoScaling then
        FontUtil:SetAutoScalingText(self.ButtonText, text);
    else
        self.ButtonText:SetText(text);
        self.ButtonText:SetTextScale(1);
    end

    if getTextWidth then
        return self.ButtonText:GetUnboundedStringWidth()
    end
end

function MenuButtonMixin:SetData(data)
    self.ButtonText:SetFont(data[2], 12, "");
    self.fontFile = data[2];
    self:SetButtonText(data[1]);
end

function MenuButtonMixin:OnClick(button)
    if button == "LeftButton" then
        if self.onClickFunc then
            self.onClickFunc(self, button);
            self:GetParent():MarkButtonSelected(self);
            if not self.keptOpen then
                CloseDropdownMenu();
            end
        end
    elseif button == "RightButton" then
        CloseDropdownMenu();
    end
end

function MenuButtonMixin:OnEnter()
    self:GetParent():HighlightButton(self);
end

function MenuButtonMixin:OnLeave()
    self:GetParent():HighlightButton(nil);
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
    b:SetScript("OnMouseDown", b.OnMouseDown);
    b:SetScript("OnMouseUp", b.OnMouseUp);

    b:OnLoad();

    b:SetWidth(BUTTON_MIN_WIDTH);
    b:SetHeight(BUTTON_HEIGHT);

    return b
end


local DropdownMenuMixin = {};

function DropdownMenuMixin:OnSizeChanged()
    local width, height = self:GetSize();
    local size = math.max(width, height);
    local scale = size / BG_MAX_SIZE;

    if scale > 1 then
        width = width / scale;
        height = height / scale;
    end

    self.Background:SetTexCoord(0, width/BG_MAX_SIZE, 0, height/BG_MAX_SIZE);
    API.UpdateTextureSliceScale(self.Border);

    local shadowWidth = (294/256) * width;
    local offsetY = -26/336 * shadowWidth;

    self.BottomShadow:ClearAllPoints();
    self.BottomShadow:SetPoint("BOTTOM", self, "BOTTOM", 0, offsetY);

    self.BottomShadow:SetSize(shadowWidth, 128/336 * width);
    self.BottomShadow.Left:SetWidth(32/336 * shadowWidth);
    self.BottomShadow.Right:SetWidth(32/336 * shadowWidth);
end

function DropdownMenuMixin:LoadTheme()
    local filePath = ThemeUtil:GetTexturePath();

    local file1 = filePath.."DropdownMenu-Component.png";
    self.Border:SetTexture(file1);
    self.Background:SetTexture(filePath.."DropdownMenu-Background.jpg");
    self.ButtonHighlight.BackTexture:SetTexture(filePath.."Settings-ButtonHighlight.png");

    self.BottomShadow.Left:SetTexture(file1);
    self.BottomShadow.Center:SetTexture(file1);
    self.BottomShadow.Right:SetTexture(file1);
    self.BottomShadow.Left:SetTexCoord(0, 32/1024, 136/512, 265/512);
    self.BottomShadow.Center:SetTexCoord(32/1024, 304/1024, 136/512, 265/512);
    self.BottomShadow.Right:SetTexCoord(304/1024, 336/1024, 136/512, 265/512);

    self.SelectedIcon.Texture:SetTexture(file1);
    self.SelectedIcon.Texture:SetTexCoord(0, 64/1024, 272/512, 336/512);

    self.PageNav.Background:SetTexture(file1);
    self.PageNav.Background:SetTexCoord(0, 192/1024, 336/512, 384/512);

    local arrowTexture = filePath.."Settings-ArrowOption.png";
    self.PageNav.LeftArrow.Texture:SetTexture(arrowTexture);
    self.PageNav.LeftArrow.Highlight:SetTexture(arrowTexture);
    self.PageNav.RightArrow.Texture:SetTexture(arrowTexture);
    self.PageNav.RightArrow.Highlight:SetTexture(arrowTexture);
end

function DropdownMenuMixin:HighlightButton(button)
    self.ButtonHighlight:Hide();
    self.ButtonHighlight:ClearAllPoints();

    if button and button:IsEnabled() then
        self.ButtonHighlight:SetParent(button);
        self.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 2, 0);
        self.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
        self.ButtonHighlight:Show();
    end
end

function DropdownMenuMixin:MarkButtonSelected(button)
    self.SelectedIcon:Hide();
    self.SelectedIcon:ClearAllPoints();

    if button then
        self.SelectedIcon:SetParent(button);
        self.SelectedIcon:SetPoint("CENTER", button, "LEFT", 0, 0);
        self.SelectedIcon:Show();
        --button.ButtonText:SetFontObject("DUIFont_MenuButton_Highlight");
        FontUtil:SetupFontStringByFontObjectName(button.ButtonText, "DUIFont_MenuButton_Highlight");
    end
end

function DropdownMenuMixin:SetOwner(owner, parent)
    local offsetX = 2;

    self.owner = owner;
    self:ClearAllPoints();
    self:SetParent(parent or owner);
    --self:SetUsingParentLevel(true);
    self:SetFrameLevel(owner:GetFrameLevel() + 10);
    self:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", -offsetX, 0);
    --self:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", offsetX, 0);
end

function DropdownMenuMixin:UpdatePixel(scale)
    if not scale then
        scale = self:GetEffectiveScale();
    end

    local pixelOffset = 7.0;
    local offset = API.GetPixelForScale(scale, pixelOffset);
    self.Background:ClearAllPoints();
    self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", offset, -offset);
    self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -offset, offset);
end

function DropdownMenuMixin:OnMouseDown()

end

function DropdownMenuMixin:IsFocused()
    if self:IsMouseOver() then
        return true
    end

    if self.owner and self.owner:IsMouseOver() then
        return true
    end

    return false
end

function DropdownMenuMixin:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not self:IsFocused() then
            self:Hide();
        end
    end
end

function DropdownMenuMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function DropdownMenuMixin:OnHide()
    self:Hide();
    self:ClearAllPoints();
    self:SetParent(nil);
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:SetScript("OnUpdate", nil);

    self.OwnerScrollArea:Hide();
    self.OwnerScrollArea:ClearAllPoints();

    if self.owner then
        if self.owner.OnMenuClosed then
            self.owner:OnMenuClosed();
        end
        self.owner = nil;
    end
end

function DropdownMenuMixin:Release()
    if self.buttonPool then
        self.buttonPool:Release();
    end

    self:MarkButtonSelected(nil);
    self:HighlightButton(nil);
end

function DropdownMenuMixin:UpdateSelectedID()
    if self.menuData and self.menuData.selectedIDGetter then
        local selectedID = self.menuData.selectedIDGetter();
        self.menuData.selectedID = selectedID;
        return selectedID
    end
end

function DropdownMenuMixin:SetMenuData(menuData)
    self:Release();

    local total = menuData and #menuData.buttons or 0;
    local maxPage = math.ceil(total / MAX_BUTTON_PER_PAGE);
    self.menuData = menuData;

    local minMenuWidth = self.owner and (self.owner:GetWidth() + 4);
    local buttonWidth = menuData.buttonWidth or minMenuWidth or (self:GetWidth());
    buttonWidth = API.Round(buttonWidth);
    local buttonHeight = menuData.buttonHeight or BUTTON_HEIGHT;
    local menuWidth = API.Round(minMenuWidth);

    self.buttonWidth = buttonWidth;
    self.buttonHeight = buttonHeight;
    self.menuWidth = menuWidth;
    self.reloadPage = menuData.reloadPage or false;

    local selectedID = self:UpdateSelectedID();
    local bestPage = 1;

    if total > 0 then
        if selectedID ~= nil then
            for i, data in ipairs(menuData.buttons) do
                if data.id == selectedID then
                    bestPage = math.ceil(i / MAX_BUTTON_PER_PAGE);
                    break
                end
            end
        end
    else
        total = 2;
        self:Hide();    --TEMP
        return
    end

    self.totalButtons = total;
    self:SetMaxPage(maxPage);
    self:SetPage(bestPage);
end

function DropdownMenuMixin:OnUpdate(elapsed)
    self.viewTime = self.viewTime + elapsed;
    if self.viewTime > 0.2 then
        self.viewTime = 0;
        if self.pageReloaded and false then
            self:SetScript("OnUpdate", nil);
        else
            self.pageReloaded = true;
            if self:IsShown() then
                self:SetPage(self.page, true);
            end
        end
    end
end

function DropdownMenuMixin:SetMaxPage(maxPage)
    local scrollable = maxPage > 1;
    self.maxPage = maxPage;
    self.OwnerScrollArea:ClearAllPoints();
    if scrollable then
        self:SetScript("OnMouseWheel", self.OnMouseWheel);
        self.PageNav:Show();
        self.scrollable = true;
        if self.owner then
            self.OwnerScrollArea:SetPoint("TOPLEFT", self.owner, "TOPLEFT", 0, 0);
            self.OwnerScrollArea:SetPoint("BOTTOMRIGHT", self.owner, "BOTTOMRIGHT", 0, 0);
            self.OwnerScrollArea:Show();
        else
            self.OwnerScrollArea:Hide();
        end
    else
        self:SetScript("OnMouseWheel", nil);
        self.PageNav:Hide();
        self.scrollable = false;
        self.OwnerScrollArea:Hide();
    end
end

local function EnableArrowButton(arrowButton, enable)
    if enable then
        arrowButton:Enable();
        arrowButton.Texture:SetAlpha(1);
    else
        arrowButton:Disable();
        arrowButton.Texture:SetAlpha(0);
    end
end

function DropdownMenuMixin:SetPage(page, fromReload)
    if page < 0 or page > self.maxPage then
        page = 1;
    end

    self.page = page;
    self.PageNav.PageText:SetText(page.." / "..self.maxPage);

    local menuData = self.menuData;
    if not menuData then
        self:Hide();
        return
    end

    EnableArrowButton(self.PageNav.LeftArrow, page > 1);
    EnableArrowButton(self.PageNav.RightArrow, page < self.maxPage);

    local buttonWidth = self.buttonWidth;
    local buttonHeight = self.buttonHeight;
    local selectedID = self:UpdateSelectedID();
    local fitWidth = menuData.fitWidth == true;
    local autoScaling = menuData.autoScaling == true;
    local matchFound = selectedID == nil;
    local textWidth;
    local maxTextWidth = 0;
    local menuWidth = self.menuWidth;
    local fromIndex = (page - 1) * MAX_BUTTON_PER_PAGE;

    self:Release();

    for i = 1, MAX_BUTTON_PER_PAGE do
        local data = menuData.buttons[i + fromIndex];
        if data then
            local button = self:AcquireButton();
            button:SetParent(self);
            button:SetPoint("TOP", self, "TOP", 0, -MENU_BUTTON_PADDING + (1- i) * buttonHeight);
            button:SetSize(buttonWidth, buttonHeight);
            button.id = data.id;
            button.data = data;
            button.onClickFunc = data.onClickFunc;
            button.keptOpen = data.keptOpen;

            if data.setupFunc then
                textWidth = data.setupFunc(button, data.name);
            else
                textWidth = button:SetButtonText(data.name, autoScaling, fitWidth);
            end

            if (not matchFound) and (selectedID == data.id) then
                matchFound = true;
                self:MarkButtonSelected(button)
            end

            if textWidth and textWidth > maxTextWidth then
                maxTextWidth = textWidth;
            end
        else
            break
        end
    end

    if fitWidth then
        menuWidth = math.max(menuWidth, maxTextWidth + 0.25 + 2*BUTTON_TEXT_OFFSET_X);
        self.buttonPool:ProcessActiveObjects(
            function(menuButton)
                menuButton:SetWidth(menuWidth);
            end
        );
    end

    local footerHeight, numButtons;
    if self.scrollable then
        footerHeight = BUTTON_HEIGHT;
        numButtons = MAX_BUTTON_PER_PAGE;
    else
        footerHeight = MENU_BUTTON_PADDING;
        numButtons = self.totalButtons;
    end

    self:SetSize(menuWidth, numButtons * buttonHeight + footerHeight + MENU_BUTTON_PADDING);


    self.viewTime = 0;
    self.pageReloaded = fromReload or false;
    if self.reloadPage and not self.pageReloaded then
        --For Settings_Font. Some font needs to be loaded twice
        self:SetScript("OnUpdate", self.OnUpdate);
    else
        self:SetScript("OnUpdate", nil);
    end
end

function DropdownMenuMixin:OnMouseWheel(delta)
    if delta > 0 then
        if self.page > 1 then
            self:SetPage(self.page - 1);
        end
    elseif delta < 0 then
        if self.page < self.maxPage then
            self:SetPage(self.page + 1);
        end
    end
end

function DropdownMenuMixin:AcquireButton()
    if not self.buttonPool then
        self.buttonPool = API.CreateObjectPool(CreateMenuButton);
    end
    return self.buttonPool:Acquire();
end

function DropdownMenuMixin:OnPositionChanged()
    if self:IsShown() and self.owner then
        if self.owner.IsInRange then
            if not self.owner:IsInRange() then
                self:Hide();
            end
        end
    end
end

local function UpdateSettingsDropdownMenuPosition()
    if MainDropdownMenu then
        MainDropdownMenu:OnPositionChanged();
    end
end
addon.CallbackRegistry:Register("SettingsUI.OnMouseWheel", UpdateSettingsDropdownMenuPosition);

local function CreateDropdownMenu(parent)
    local f = CreateFrame("Frame", nil, parent, "DUIDropdownMenuTemplate");
    f:Hide();
    API.Mixin(f, DropdownMenuMixin);


    local function PageArrow_OnClick(self)
        f:OnMouseWheel(self.delta);
    end

    --The NavArrow here mainly serves as a visual indicator
    --Its position may shift due to "fitWidth"
    local nav = f.PageNav;
    local centerHalfWidth = 32;
    nav.LeftArrow:ClearAllPoints();
    nav.RightArrow:ClearAllPoints();
    nav.LeftArrow:SetScript("OnClick", PageArrow_OnClick);
    nav.RightArrow:SetScript("OnClick", PageArrow_OnClick);
    nav.LeftArrow:SetPoint("CENTER", nav, "CENTER", -centerHalfWidth, 0);
    nav.RightArrow:SetPoint("CENTER", nav, "CENTER", centerHalfWidth, 0);
    nav.Background:SetSize(4*BUTTON_HEIGHT, BUTTON_HEIGHT);

    f:LoadTheme();
    f:OnSizeChanged();
    f:SetScript("OnSizeChanged", f.OnSizeChanged);
    f:SetScript("OnMouseDown", f.OnMouseDown);
    f:SetScript("OnShow", f.OnShow);
    f:SetScript("OnHide", f.OnHide);
    f:SetScript("OnEvent", f.OnEvent);
    f:UpdatePixel();
    addon.PixelUtil:AddPixelPerfectObject(f);


    --Scroll on the DropdownButton will propagate to the menu
    local OwnerScrollArea = CreateFrame("Frame", nil, f);
    OwnerScrollArea:Hide();
    f.OwnerScrollArea = OwnerScrollArea;
    OwnerScrollArea:SetScript("OnMouseWheel", function(_, delta)
        f:OnMouseWheel(delta);
    end);

    return f
end

local function GetDropdownMenu(parent)
    if not MainDropdownMenu then
        MainDropdownMenu = CreateDropdownMenu(parent);
        addon.DropdownMenu = MainDropdownMenu;
    end
    return MainDropdownMenu
end
addon.GetDropdownMenu = GetDropdownMenu;


--[[
C_Timer.After(4, function()
    local DD = GetDropdownMenu();
    DD:SetPoint("CENTER", 0, 0);
    DD:SetSize(8*24, 4*24);

    TTT = DD
end)
--]]