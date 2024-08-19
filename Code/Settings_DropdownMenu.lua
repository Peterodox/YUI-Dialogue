local _, addon = ...
local API = addon.API;
local ThemeUtil = addon.ThemeUtil;
local FontUtil = addon.FontUtil;

local BG_MAX_SIZE = 340;

local MainDropdownMenu;


local function CloseDropdownMenu()
    if MainDropdownMenu then
        MainDropdownMenu:Hide();
    end
end
addon.CloseDropdownMenu = CloseDropdownMenu;



local BUTTON_TEXT_OFFSET_X = 12;
local BUTTON_PUSH_OFFSET = 1;
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
    self.ButtonText:SetFontObject("DUIFont_MenuButton_Normal");

    if autoScaling then
        FontUtil:SetAutoScalingText(self.ButtonText, text);
    else
        self.ButtonText:SetText(text);
        self.ButtonText:SetTextScale(1);
    end

    if getTextWidth then
        return (self.ButtonText:GetUnboundedStringWidth()) + 0.25;
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

    b:SetWidth(192);
    b:SetHeight(24);

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

    self.Border:SetTexture(filePath.."DropdownMenu-Component.png");
    self.Background:SetTexture(filePath.."DropdownMenu-Background.jpg");
    self.ButtonHighlight.BackTexture:SetTexture(filePath.."Settings-ButtonHighlight.png");

    self.BottomShadow.Left:SetTexture(filePath.."DropdownMenu-Component.png");
    self.BottomShadow.Center:SetTexture(filePath.."DropdownMenu-Component.png");
    self.BottomShadow.Right:SetTexture(filePath.."DropdownMenu-Component.png");
    self.BottomShadow.Left:SetTexCoord(0, 32/1024, 136/512, 265/512);
    self.BottomShadow.Center:SetTexCoord(32/1024, 304/1024, 136/512, 265/512);
    self.BottomShadow.Right:SetTexCoord(304/1024, 336/1024, 136/512, 265/512);

    self.SelectedIcon.Texture:SetTexture(filePath.."DropdownMenu-Component.png");
    self.SelectedIcon.Texture:SetTexCoord(0, 64/1024, 272/512, 336/512);
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
        button.ButtonText:SetFontObject("DUIFont_MenuButton_Highlight");
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

function DropdownMenuMixin:SetMenuData(menuData)
    self:Release();

    local total = menuData and #menuData.buttons or 0;

    local padding = 8;
    local minMenuWidth = self.owner and (self.owner:GetWidth() + 4);
    local buttonWidth = menuData.buttonWidth or minMenuWidth or (self:GetWidth());
    buttonWidth = API.Round(buttonWidth);
    local buttonHeight = menuData.buttonHeight or 24;

    local menuWidth = API.Round(minMenuWidth);

    if total > 0 then
        local selectedID = menuData.selectedID;
        local fitWidth = menuData.fitWidth == true;
        local autoScaling = menuData.autoScaling == true;
        local matchFound = selectedID == nil;
        local textWidth;
        local maxTextWidth = 0;

        for i, data in ipairs(menuData.buttons) do
            local button = self:AcquireButton();
            button:SetParent(self);
            button:SetPoint("TOP", self, "TOP", 0, -padding + (1- i) * buttonHeight);
            button:SetSize(buttonWidth, buttonHeight);
            textWidth = button:SetButtonText(data.name, autoScaling, fitWidth);
            button.id = data.id;
            button.data = data;
            button.onClickFunc = data.onClickFunc;
            button.keptOpen = data.keptOpen;

            if (not matchFound) and (selectedID == data.id) then
                matchFound = true;
                self:MarkButtonSelected(button)
            end

            if textWidth and textWidth > maxTextWidth then
                maxTextWidth = textWidth;
            end
        end

        if fitWidth then
            menuWidth = math.max(minMenuWidth, maxTextWidth + 2*BUTTON_TEXT_OFFSET_X);
            self.buttonPool:ProcessActiveObjects(
                function(menuButton)
                    menuButton:SetWidth(menuWidth);
                end
            );
        end
    else
        total = 2;
        self:Hide();    --TEMP
    end

    self:SetSize(menuWidth, total * buttonHeight + 2*padding);
end

function DropdownMenuMixin:AcquireButton()
    if not self.buttonPool then
        self.buttonPool = API.CreateObjectPool(CreateMenuButton);
    end
    return self.buttonPool:Acquire();
end

local function CreateDropdownMenu(parent)
    local f = CreateFrame("Frame", nil, parent, "DUIDropdownMenuTemplate");
    f:Hide();
    API.Mixin(f, DropdownMenuMixin);
    f:LoadTheme();
    f:OnSizeChanged();
    f:SetScript("OnSizeChanged", f.OnSizeChanged);
    f:SetScript("OnMouseDown", f.OnMouseDown);
    f:SetScript("OnShow", f.OnShow);
    f:SetScript("OnHide", f.OnHide);
    f:SetScript("OnEvent", f.OnEvent);
    f:UpdatePixel();
    addon.PixelUtil:AddPixelPerfectObject(f);
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