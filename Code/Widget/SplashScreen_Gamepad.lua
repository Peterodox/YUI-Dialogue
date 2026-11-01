local _, addon = ...

local SHOULD_SHOW_SPLASH_SCREEN; -- turns True if: Never shown before & Gamepad is active but DUI layout is not set to controller
local SHOWN_DBKEY = "SplashScreen_Gamepad";

local SplashScreen;

local function FlagSplashScreenShown()
    SHOULD_SHOW_SPLASH_SCREEN = false;
    addon.SetDBValue(SHOWN_DBKEY, true);
end

local function HideSplashScreen()
    if SplashScreen then
        SplashScreen:Hide();
    end
end

local function CreateRectButton(parent)
    local f = CreateFrame("Button", nil, parent, "DUIDialogOptionButtonTemplate");
    f.HotkeyFrame = CreateFrame("Frame", nil, f, "DUIDialogHotkeyTemplate");
    return f;
end

local function CreateSplashScreen()
    local L = addon.L;
    local API = addon.API;
    local CallbackRegistry = addon.CallbackRegistry;
    local DeviceUtil = addon.DeviceUtil;
    local layoutInfo = addon.SettingsUtil.GetLayoutInfo();
    local frameWidth = layoutInfo.optionButtonWidth;
    local frameHeight = math.min(frameWidth * 3/4, UIParent:GetHeight());
    local widgetSize = layoutInfo.widgetHeight;
    local step = 1;


    local f = CreateFrame("Frame");
    SplashScreen = f;
    f:Hide();
    f:SetSize(frameWidth, frameHeight);
    f:SetPoint("CENTER", 0, 0);
    f:SetFrameStrata("FULLSCREEN");
    f:EnableMouse(true);
    f:SetToplevel(true);
    f.BackgroundFrame = CreateFrame("Frame", nil, f, "DUIGenericTitledFrameTemplate");

    -- BlackScreen always fade in/out
    local BlackScreen = CreateFrame("Frame", nil, nil);
    BlackScreen:SetAllPoints(UIParent);
    BlackScreen:SetUsingParentLevel(true);
    BlackScreen.Texture = BlackScreen:CreateTexture(nil, "BACKGROUND", nil, -1);
    BlackScreen.Texture:SetColorTexture(0, 0, 0, 0.5);
    BlackScreen.Texture:SetAllPoints(BlackScreen);
    BlackScreen:SetAlpha(0);
    BlackScreen:SetFrameStrata("FULLSCREEN");

    local BackgroundDecor = f:CreateTexture(nil, "ARTWORK");
    BackgroundDecor:SetTexture("Interface/AddOns/DialogueUI/Art/ParchmentDecor/Dalaran.png");
    BackgroundDecor:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0);
    BackgroundDecor:SetSize(0.85 * frameHeight, 0.85 * frameHeight);


    -- Create the DeviceSelctor
    local DummyContainer = CreateFrame("Frame", nil, f);
    DummyContainer:SetSize(widgetSize, widgetSize);
    DummyContainer:SetPoint("CENTER", f, "CENTER", 0, 0);

    function DummyContainer:OnEnter()
    end

    function DummyContainer:OnLeave()
    end

    local DeviceSelctor = addon.SettingsUtil.CreateInputDeviceSelector(DummyContainer);
    DeviceSelctor:SetPoint("CENTER", f, "CENTER", 0, 0);
    DeviceSelctor:SetPoint("CENTER", DummyContainer, "CENTER", 0, 0);
    local a = -4; -- Make the arrow's clickable area larger
    DeviceSelctor.LeftArrow:SetHitRectInsets(a, a, a, a);
    DeviceSelctor.RightArrow:SetHitRectInsets(a, a, a, a);

    function DeviceSelctor:PostClick()
        local value = self.choices[self.selectedID].dbValue;
        addon.SetDBValue("InputDevice", value);
    end

    local iconSize = 16 * widgetSize / 24;
    local iconOffset = 4;

    local LeftKeyIcon = DeviceSelctor:CreateTexture(nil, "BACKGROUND");
    LeftKeyIcon:SetSize(iconSize, iconSize);
    LeftKeyIcon:SetPoint("RIGHT", DeviceSelctor, "LEFT", -iconOffset, 0);
    local RightKeyIcon = DeviceSelctor:CreateTexture(nil, "BACKGROUND");
    RightKeyIcon:SetSize(iconSize, iconSize);
    RightKeyIcon:SetPoint("LEFT", DeviceSelctor, "RIGHT", iconOffset, 0);

    local function UpdateDPadIcons()
        if DeviceUtil:IsUsingControllerLayout() then
            LeftKeyIcon:Show();
            RightKeyIcon:Show();
            LeftKeyIcon:SetTexture(addon.ThemeUtil:GetTextureFile("D-PAD-LEFT.png"));
            RightKeyIcon:SetTexture(addon.ThemeUtil:GetTextureFile("D-PAD-RIGHT.png"));
        else
            LeftKeyIcon:Hide();
            RightKeyIcon:Hide();
        end
    end


    -- The Instruction
    local Text1 = f:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Paragraph");
    Text1:SetSpacing(Text1:GetFontHeight(true) * 0.35);
    Text1:SetJustifyH("CENTER");
    Text1:SetJustifyV("TOP");
    Text1:SetWidth(frameWidth * 0.8);


    local ButtonHighlight = CreateFrame("Frame", nil, f, "DUIDialogueOptionButtonHighlightTemplate");

    function f:HighlightButton(optionButton)
        ButtonHighlight:ClearAllPoints();
        ButtonHighlight:Hide();
        if optionButton then
            optionButton:SetParentHighlightTexture(ButtonHighlight);
        end
    end


    -- Continue Button
    local ContinueButton = CreateRectButton(f);
    ContinueButton.keyAction = "PRIMARY";
    ContinueButton:SetButtonWidth(DeviceSelctor:GetWidth() * 1.25);
    ContinueButton:SetButtonArt(1);
    ContinueButton:SetOwner(f);
    ContinueButton:SetButtonText(CONTINUE, true);

    function ContinueButton:Refresh()
        self:SetHotkey(self.keyAction);
    end

    ContinueButton:Refresh();

    local ContinueButtonHeight = ContinueButton:GetHeight();
    ContinueButton:SetPoint("BOTTOM", f, "BOTTOM", 0, ContinueButtonHeight);
    Text1:SetPoint("TOP", f, "TOP", 0, -2 * ContinueButtonHeight);


    local UpdateStep;

    local function GoToNextStep()
        PlaySound(SOUNDKIT.IG_MAINMENU_QUIT);
        step = step + 1;
        if step > 2 then
            FlagSplashScreenShown();
            f:Hide();
        else
            UpdateStep();
        end
    end

    ContinueButton:SetScript("OnClick", GoToNextStep);

    function UpdateStep()
        DeviceSelctor:SetShown(step == 1);
        ContinueButton:SetButtonText(step == 1 and CONTINUE or L["Got It"], true);
        Text1:SetText(step == 1 and L["Tutorial Choose Input Device"] or L["Instruction Open Settings Console"]);
    end

    local function UpdateTheme()
        local themeID;

        if addon.ThemeUtil:IsDarkMode() then
            themeID = 2;
            BackgroundDecor:SetBlendMode("ADD");
            BackgroundDecor:SetAlpha(1);
            BackgroundDecor:SetVertexColor(0.15, 0.15, 0.15);
        else
            themeID = 1;
            BackgroundDecor:SetBlendMode("BLEND");
            BackgroundDecor:SetAlpha(0.5);
            BackgroundDecor:SetVertexColor(173/255, 114/255, 65/255);
        end

        DeviceSelctor:OnThemeChanged(themeID);
        ContinueButton:LoadTheme();
        UpdateDPadIcons();
    end

    UpdateStep();
    UpdateTheme();

    local function OnKeyDown(self, key)
        if InCombatLockdown() then
            self:Hide();
        else
            local propagate = true;
            if key == self.confirmKeyboardKey then
                propagate = false;
                GoToNextStep();
                ContinueButton:OnMouseDown("LeftButton");
            elseif key == "ESCAPE" then
                propagate = false;
                self:Hide();
            end
            self:SetPropagateKeyboardInput(propagate);
        end
    end

    local function OnKeyUp(self, key)
        if InCombatLockdown() then return; end

        if key == self.confirmKeyboardKey then
            ContinueButton:OnMouseUp();
            self:SetPropagateKeyboardInput(false);
        else
            self:SetPropagateKeyboardInput(true);
        end
    end

    local function OnGamePadButtonDown(self, button)
        if InCombatLockdown() then
            self:Hide();
        else
            local propagate = true;
            if button == "PADBACK" then
                propagate = false;
                self:Hide();
            elseif button == "PADMENU" or button == "PADFORWARD" then
                propagate = false;
                addon.SettingsUI:ToggleUI();
                FlagSplashScreenShown();
            elseif button == DeviceUtil:GetConfirmKey() then
                propagate = false;
                if not API.CheckActionThrottled("SplashScreenNext") then
                    GoToNextStep();
                    ContinueButton:OnMouseDown("LeftButton");
                end
            elseif button == "PADDLEFT" or button == "PADDRIGHT" then
                propagate = false;
                if DeviceSelctor:IsShown() then
                    DeviceSelctor:SelectChoiceByDelta(button == "PADDLEFT" and -1 or 1);
                end
            elseif button == "PAD1" or button == "PAD2" then
                -- Don't allow PAD2 cancel and forbit PAD1 to click Accept on DUI
                propagate = false;
            end
            self:SetPropagateKeyboardInput(propagate);
        end
    end

    local function OnGamePadButtonUp(self, button)
        ContinueButton:OnMouseUp();
    end

    f:SetScript("OnShow", function(self)
        self:Raise();
        self:RegisterEvent("PLAYER_REGEN_DISABLED");
        self.confirmKeyboardKey = addon.BindingUtil:GetActiveConfirmKey();
        self:SetScript("OnKeyDown", OnKeyDown);
        self:SetScript("OnKeyUp", OnKeyUp);
        self:SetScript("OnGamePadButtonDown", OnGamePadButtonDown);
        self:SetScript("OnGamePadButtonUp", OnGamePadButtonUp);

        BlackScreen.alpha = BlackScreen:GetAlpha();
        BlackScreen:SetScript("OnUpdate", function(bs, elapsed)
            bs.alpha = bs.alpha + 5 * elapsed;
            if bs.alpha >= 1 then
                bs.alpha = 1;
                bs:SetScript("OnUpdate", nil);
            end
            bs:SetAlpha(bs.alpha);
        end);
        BlackScreen:Show();
        API.UIFrameFadeIn(self, 0.2);
    end);

    f:SetScript("OnHide", function(self)
        self:UnregisterEvent("PLAYER_REGEN_DISABLED");
        self:SetScript("OnKeyDown", nil);
        self:SetScript("OnKeyUp", nil);
        self:SetScript("OnGamePadButtonDown", nil);
        self:SetScript("OnGamePadButtonUp", nil);

        BlackScreen.alpha = BlackScreen:GetAlpha();
        BlackScreen:SetScript("OnUpdate", function(bs, elapsed)
            bs.alpha = bs.alpha - 2 * elapsed;
            if bs.alpha <= 0 then
                bs.alpha = 0;
                bs:SetScript("OnUpdate", nil);
                bs:Hide();
            end
            bs:SetAlpha(bs.alpha);
        end);
    end);

    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            self:Hide();
        end
    end);


    -- Add Callbacks
    CallbackRegistry:Register("SettingChanged.InputDevice", function(deviceIndex)
        DeviceSelctor:SelectChoiceByIndex(deviceIndex);
        ContinueButton:Refresh();
        UpdateDPadIcons();
        UpdateStep();
    end);

    CallbackRegistry:Register("ThemeChanged", UpdateTheme);

    CallbackRegistry:Register("SettingsUI.Show", function()
        HideSplashScreen();
    end);

    CallbackRegistry:Register("DialogueUI.Show", function()
        f:Raise();
    end);

    CallbackRegistry:Register("DialogueUI.Hide", HideSplashScreen);
    CallbackRegistry:Register("BookUI.Hide", HideSplashScreen);
end

local function TryShowGamepadSplashScreen()
    if SHOULD_SHOW_SPLASH_SCREEN == nil then
        SHOULD_SHOW_SPLASH_SCREEN = addon.GetDBValue(SHOWN_DBKEY) == nil;
    end

    if InCombatLockdown() then return; end

    if SHOULD_SHOW_SPLASH_SCREEN then
        if not SplashScreen then
            CreateSplashScreen();
        end
        SplashScreen:Show();
        SplashScreen:Raise();
        return true;
    end
end
addon.TryShowGamepadSplashScreen = TryShowGamepadSplashScreen;

-- Debug
--C_Timer.After(0, function() SHOULD_SHOW_SPLASH_SCREEN = true; TryShowGamepadSplashScreen(); end)
