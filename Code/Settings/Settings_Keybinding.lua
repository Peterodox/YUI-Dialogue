local _, addon = ...
local L = addon.L;
local ThemeUtil = addon.ThemeUtil;
local CallbackRegistry = addon.CallbackRegistry;
local BindingUtil = addon.BindingUtil;
local InCombatLockdown = InCombatLockdown;
local pairs = pairs;

local SettingsKeybindingButtons = {};

local function UpdateKeybindings()
    for button in pairs(SettingsKeybindingButtons) do
        if button:IsShown() then
            button:Update();
        end
    end
end
CallbackRegistry:Register("CustomBindingChanged", UpdateKeybindings);


local KeybindListener = CreateFrame("Frame");
KeybindListener:Hide();
KeybindListener.active = false;
do
    function KeybindListener:SetOwner(keybindButton)
        self:Hide();
        if keybindButton:IsVisible() then
            if InCombatLockdown() then
                return
            end
            self:OnHide();
            self:SetParent(keybindButton);
            self.owner = keybindButton;
            self:SetFrameStrata("TOOLTIP");
            self:SetScript("OnKeyDown", self.OnKeyDown);
            self:SetPropagateKeyboardInput(false);
            self.active = true;
            self:Show();
        end
    end

    function KeybindListener:OnShow()
        self:RegisterEvent("PLAYER_REGEN_DISABLED");
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end
    KeybindListener:SetScript("OnShow", KeybindListener.OnShow);

    function KeybindListener:OnHide()
        if self.active then
            self.active = false;
            self:Hide();
            self:SetScript("OnKeyDown", nil);
            self:UnregisterEvent("PLAYER_REGEN_DISABLED");
            self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
            if self.owner then
                self.owner:SetKeybindingMode(false);
                self.owner = nil;
            end
        end
    end
    KeybindListener:SetScript("OnHide", KeybindListener.OnHide);

    function KeybindListener:OnEvent(event)
        if event == "GLOBAL_MOUSE_DOWN" then
            if self.owner and not self.owner:IsMouseMotionFocus() then
                self:Hide();
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            self:Hide();
        end
    end
    KeybindListener:SetScript("OnEvent", KeybindListener.OnEvent);

    function KeybindListener:OnKeyDown(key, down)
        if BindingUtil:IsKeyInvalid(key) then
            self:Hide();
            return
        end

        if self.owner then
            if self.owner.dbKey then
                BindingUtil:CheckAndSetBindingKey(self.owner.dbKey, key, true);
            end
        end

        self:Hide();
    end

    CallbackRegistry:Register("SettingsUI.OnMouseWheel", function()
        if KeybindListener.active then
            KeybindListener:OnHide();
        end
    end);
end


DUIDialogSettingsKeybindingMixin = {};
do
    function DUIDialogSettingsKeybindingMixin:OnLoad()
        self:SetButtonState(4);
        SettingsKeybindingButtons[self] = true;
    end

    function DUIDialogSettingsKeybindingMixin:LoadTexture(file)
        self.Background:SetTexture(file);
    end

    function DUIDialogSettingsKeybindingMixin:SetData(optionData)
        self.dbKey = optionData.action;
        self:Update();
    end

    function DUIDialogSettingsKeybindingMixin:SetButtonState(state)
        local darkMode = ThemeUtil:IsDarkMode();
        local colorKey;

        if state == 1 then
            --Unused
            self.Background:SetTexCoord(0, 0.75, 0.25, 0.375);
            if darkMode then
                colorKey = "DarkModeGold";
            else
                colorKey = "Ivory";
            end
        elseif state == 2 then
            --Set Binding
            self.Background:SetTexCoord(0, 0.75, 0.375, 0.5);
            if darkMode then
                colorKey = "DarkModeGold";
            else
                colorKey = "Ivory";
            end
        elseif state == 3 then
            --Hover, Highlighted
            self.Background:SetTexCoord(0, 0.75, 0.125, 0.25);
            if darkMode then
                colorKey = "DarkModeGold";
            else
                colorKey = "DarkBrown";
            end
        elseif state == 4 then
            --Normal, Unfocused
            self.Background:SetTexCoord(0, 0.75, 0, 0.125);
            if darkMode then
                colorKey = "DarkModeGold";
            else
                colorKey = "DarkBrown";
            end
        end

        ThemeUtil:SetFontColor(self.ValueText, colorKey);
    end

    function DUIDialogSettingsKeybindingMixin:OnEnter()
        self:GetParent():OnEnter();
        if not self.isBinding then
            self:SetButtonState(3);
        end
    end

    function DUIDialogSettingsKeybindingMixin:OnLeave()
        self:GetParent():OnLeave();
        if not self.isBinding then
            self:SetButtonState(4);
        end
    end

    function DUIDialogSettingsKeybindingMixin:SetWidgetHeight(height)
        self:SetSize(6 * height, height);
    end

    function DUIDialogSettingsKeybindingMixin:GetSelectedChoiceTooltip()
        if self.dbKey then
            return BindingUtil:GetActionTooltip(self.dbKey)
        end
    end

    function DUIDialogSettingsKeybindingMixin:OnClick(button)
        if button == "LeftButton" then
            self.isBinding = not self.isBinding;
            self:SetKeybindingMode(self.isBinding);
        else    --RightButton
            BindingUtil:CheckAndSetBindingKey(self.dbKey, nil, true);
            self:SetKeybindingMode(false);
        end
    end

    function DUIDialogSettingsKeybindingMixin:OnMouseDown()
        self.ValueText:SetPoint("CENTER", self, "CENTER", 0, 1);
    end

    function DUIDialogSettingsKeybindingMixin:OnMouseUp()
        self.ValueText:SetPoint("CENTER", self, "CENTER", 0, 2);
    end

    function DUIDialogSettingsKeybindingMixin:ResetState()
        self.isBinding = nil;
        self:SetButtonState(4);
        self:OnMouseUp();
    end

    function DUIDialogSettingsKeybindingMixin:SetKeybindingMode(state)
        self.isBinding = state;
        if state then
            self:SetButtonState(2);
            KeybindListener:SetOwner(self);
            self:GetParent():AdjustScroll();
        else
            if self:IsMouseMotionFocus() then
                self:OnEnter();
            else
                self:SetButtonState(4);
            end
            if KeybindListener.owner == self then
                KeybindListener:Hide();
            end
        end
    end

    function DUIDialogSettingsKeybindingMixin:Update()
        if self.dbKey then
            self.ValueText:SetText(BindingUtil:GetBindingKey(self.dbKey));
        end
    end
end