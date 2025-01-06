local _, addon = ...
local API = addon.API;
local TooltipFrame = addon.SharedTooltip;


local BUTTON_SIZE = 24;
local ICON_SIZE = 16;
local ALPHA_UNFOCUSED = 0.6;


local TranslatorButtonMixin = {};

function TranslatorButtonMixin:OnEnter()
    self.Icon:SetAlpha(1);
    self:ShowTooltip();
end

function TranslatorButtonMixin:OnLeave()
    self.Icon:SetAlpha(ALPHA_UNFOCUSED);
    TooltipFrame.HideTooltip();
end

function TranslatorButtonMixin:SetTheme(themeID)
    themeID = themeID or 1;
    local x = 0.25 * (themeID - 1);
    self.Icon:SetTexCoord(x, x + 0.25, 0, 1);
end

function TranslatorButtonMixin:ShowTooltip()
    --Override
end

function TranslatorButtonMixin:OnClick(button)
    if self.onClickFunc then
        self.onClickFunc(button)
    end
end

function TranslatorButtonMixin:SetOnClickFunc(onClickFunc)
    self.onClickFunc = onClickFunc;
end

local function CreateTranslatorButton(parent, onClickFunc)
    local b = CreateFrame("Button", nil, parent);
    b:SetSize(BUTTON_SIZE, BUTTON_SIZE);

    b.Icon = b:CreateTexture(nil, "OVERLAY");
    b.Icon:SetSize(ICON_SIZE, ICON_SIZE);
    b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0);
    b.Icon:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/TranslationButton.png");
    b.Icon:SetAlpha(ALPHA_UNFOCUSED);

    API.Mixin(b, TranslatorButtonMixin);

    b:SetScript("OnClick", b.OnClick);
    b:SetScript("OnEnter", b.OnEnter);
    b:SetScript("OnLeave", b.OnLeave);

    b:SetTheme(addon.ThemeUtil:GetThemeID());
    addon.CallbackRegistry:Register("ThemeChanged", "SetTheme", b);

    b.onClickFunc = onClickFunc;

    return b
end
addon.CreateTranslatorButton = CreateTranslatorButton;