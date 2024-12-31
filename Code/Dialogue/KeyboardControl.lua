-- Press Key to select option


local _, addon = ...
local API = addon.API;
local Clipboard = addon.Clipboard;
local SecureButtonContainer = addon.SecureButtonContainer;
local BindingUtil = addon.BindingUtil;


local GAMEPAD_CONFIRM = "PAD1";
local GAMEPAD_CANCEL = "PAD2";
local GAMEPAD_ALT = "PAD4";
local IS_KBM = true;


local USE_CUSTOM_BINDINGS = false;

-- Custom Settings
local ENABLE_KEYCONTROL_IN_COMBAT = true;
local DISABLE_CONTROL_KEY = false;          --If true, pressing the key (Space) will not continue quest
local CYCLE_REWARD_ENABLED = false;         --Press Tab to cycle through choosable rewards
local TTS_ENABLED = false;
local TTS_HOTKEY_ENABLED = false;
local DEBUG_SHOW_GAMEPAD_BUTTON = false;    --[TEMP] Console user
------------------

local InCombatLockdown = InCombatLockdown;
local IsModifierKeyDown = IsModifierKeyDown;
local type = type;

local KeyboardControl = CreateFrame("Frame");
KeyboardControl:Hide();
KeyboardControl:SetFrameStrata("TOOLTIP");
KeyboardControl:SetFixedFrameStrata(true);
addon.KeyboardControl = KeyboardControl;

KeyboardControl.combatFrame = CreateFrame("Frame", nil, KeyboardControl);   --"combatFrame" doesn't change KeyProgation dynamically based on input
KeyboardControl.combatFrame:SetPropagateKeyboardInput(true);

function KeyboardControl:ResetKeyActions()
    self.keyActions = {};
    self.actions = {};
end
KeyboardControl:ResetKeyActions()

function KeyboardControl:CanSetKey(key)
    if key then
        if type(key) == "number" then
            return key <= 9
        else
            return true
        end
    end
    return false
end

--[[
function KeyboardControl:SetKeyFunction(key, func, override)
    if not self:CanSetKey(key) then return end;

    key = tostring(key);

    if (not self.keyActions[key]) or override then
        self.keyActions[key] = {
            obj = func,
            type = "function",
        };
        return key
    end
end

function KeyboardControl:SetKeyButton(key, buttonToClick, override)
    if key == "PRIMARY" then
        key = PRIMARY_CONTROL_KEY;
    end

    if not self:CanSetKey(key) then return end;

    key = tostring(key)

    if (not self.keyActions[key]) or override then
        self.keyActions[key] = {
            obj = buttonToClick,
            type = "button",
        };
        return key
    end
end
--]]

function KeyboardControl:SetAction(action, buttonToClick, override)
    if (not self.actions[action]) or override then
        self.actions[action] = {
            obj = buttonToClick,
            type = "button",
        };
        return BindingUtil:GetActiveActionKey(action)
    end
end

function KeyboardControl:SetIndexedAction(buttonIndex, buttonToClick, override)
    if buttonIndex <= 9 then
        if buttonIndex == 1 then
            self:SetAction("Confirm", buttonToClick, override);
        end
        local action = "Option"..buttonIndex;
        return self:SetAction(action, buttonToClick, override)
    end
end

function KeyboardControl:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:RegisterEvent("PLAYER_REGEN_ENABLED");
        self:SetPropagateKeyboardInput(true);
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self:IsVisible() then

        end
    elseif event == "UPDATE_BINDINGS" then
        self.bindingDirty = true;
    end
end
KeyboardControl:SetScript("OnEvent", KeyboardControl.OnEvent);

function KeyboardControl:OnHide()
    self:StopListeningKeys();
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    self:ResetKeyActions();
    self:StopRepeatingAction();
end
KeyboardControl:SetScript("OnHide", KeyboardControl.OnHide);

function KeyboardControl:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");

    if self.bindingDirty then
        self.bindingDirty = nil;
        BindingUtil:LoadBindings();
    end
end

KeyboardControl:SetScript("OnShow", KeyboardControl.OnShow);

function KeyboardControl:OnKeyDown(key, fromGamePad)
    local inCombat = InCombatLockdown();

    if SecureButtonContainer:IsActionKey(key) and not inCombat then
        KeyboardControl:SetPropagateKeyboardInput(true);
        return
    end

    local valid = false;
    local processed = false;
    local action;

    if key == "ESCAPE" then
        action = "Exit";
    end

    if key == GAMEPAD_CONFIRM then
        valid = KeyboardControl.parent:ClickFocusedObject();
        if valid then
            processed = true;
            action = nil;
        else
            action = "Confirm";
        end
    end

    if (not processed) and (not action) then
        action = BindingUtil:GetActiveKeyAction(key);
    end

    if action == "Exit" then
        valid = true;

        if Clipboard:CloseIfShown() then
            processed = true;
        elseif addon.SettingsUI:IsShown() then
            addon.SettingsUI:Hide();
            processed = true;
        elseif addon.BookUI:IsShown() then
            addon.BookUI:Hide();
            processed = true;
        else
            if fromGamePad then

            else
                if KeyboardControl.parent.HideUI then
                    local cancelPopupFirst = true;
                    KeyboardControl.parent:HideUI(cancelPopupFirst);
                    processed = true;
                else
                    KeyboardControl.parent:Hide();
                    processed = true;
                end
            end
        end
    elseif key == "GAMEPAD_UP" then
        valid = true;
        processed = true;
        KeyboardControl.parent:FocusPreviousObject();
    elseif key == "GAMEPAD_DOWN" then
        valid = true;
        processed = true;
        KeyboardControl.parent:FocusNextObject();
    elseif action == "Settings" or key == "SETTINGS" then
        valid = true;
        processed = true;
        addon.SettingsUI:ToggleUI();
    elseif action == "TTS" and not IsModifierKeyDown() then
        if TTS_ENABLED and TTS_HOTKEY_ENABLED then
            valid = true;
            processed = true;
            addon.TTSUtil:ToggleSpeaking();
        end
    elseif (CYCLE_REWARD_ENABLED and IS_KBM) and key == "TAB" and not inCombat then
        local delta = IsModifierKeyDown() and -1 or 1;
        if addon.DialogueUI:CycleRewardChoice(delta) then
            valid = true;
        end
    end

    if action == "Confirm" and DISABLE_CONTROL_KEY and not USE_CUSTOM_BINDINGS then
        processed = true;
        valid = false;
    end

    if (not processed) and action and KeyboardControl.actions[action] then
        valid = true;

        local actionType = KeyboardControl.actions[action].type;
        local object = KeyboardControl.actions[action].obj;

        if actionType == "function" then
            object();
        elseif actionType == "button" then
            if object:IsEnabled() and object:IsVisible() then
                local noFeedback = object:OnClick("GamePad");
                if (not noFeedback) and object.PlayKeyFeedback then
                    object:PlayKeyFeedback();
                end
            end
        end
    end

    if not inCombat then
        KeyboardControl:SetPropagateKeyboardInput(not valid);
    end
end

function KeyboardControl:SetParentFrame(frame)
    self.parent = frame;
    self:SetParent(frame);
    self:Show();

    self:StopListeningKeys();

    local listener;

    if InCombatLockdown() then
        if ENABLE_KEYCONTROL_IN_COMBAT then
            listener = self.combatFrame;
        end
    else
        listener = self;
    end

    if listener then
        listener:SetScript("OnKeyDown", self.OnKeyDown);
        listener:SetScript("OnGamePadButtonDown", self.OnGamePadButtonDown);
        listener:SetScript("OnGamePadButtonUp", self.OnGamePadButtonUp)
        listener:EnableGamePadButton(true);
        listener:EnableKeyboard(true);
    end
end

function KeyboardControl:StopListeningKeys()
    self:SetScript("OnKeyDown", nil);
    self.combatFrame:SetScript("OnKeyDown", nil);

    self:SetScript("OnGamePadButtonDown", nil);
    self.combatFrame:SetScript("OnGamePadButtonDown", nil);
    self:SetScript("OnGamePadButtonUp", nil);
    self.combatFrame:SetScript("OnGamePadButtonUp", nil);

    self:EnableGamePadButton(false);
    self.combatFrame:EnableGamePadButton(false);

    self:EnableKeyboard(false);
    self.combatFrame:EnableKeyboard(false);
end


do  --GamePad/Controller
    local KeyRemap = {
        PAD2 = "ESCAPE",
        PADDUP = "GAMEPAD_UP",
        PADDDOWN = "GAMEPAD_DOWN",
        PADFORWARD = "SETTINGS",  --Toggle Settings
        PADMENU = "SETTINGS",
        PADBACK = "ESCAPE",
        PADDLEFT = "GAMEPAD_UP",
        PADDRIGHT = "GAMEPAD_DOWN",
    };

    local RepeatableButton = {
        PADDUP = true,
        PADDDOWN = true,
        PADDLEFT = true,
        PADDRIGHT = true,
    };

    local REPEAT_INTERVAL = 0.125;

    function KeyboardControl:OnGamePadButtonDown(button)
        self:StopRepeatingAction();

        if addon.HelpTip:CloseAll() then
            return
        end

        local inCombat = InCombatLockdown();
        if SecureButtonContainer:IsActionKey(button) and not inCombat then
            KeyboardControl:SetPropagateKeyboardInput(true);
            return
        end

        if button == "PADRTRIGGER" then --Debug Console
            DEBUG_SHOW_GAMEPAD_BUTTON = not DEBUG_SHOW_GAMEPAD_BUTTON;
            if DEBUG_SHOW_GAMEPAD_BUTTON then
                addon.DevTool:PrintText("|cffffd100Display Pressed Buttons|r");
            else
                addon.DevTool:PrintText("|cffffd100No Longer Display Pressed Buttons|r");
            end
            if not inCombat then
                KeyboardControl:SetPropagateKeyboardInput(false);
            end
            return
        end

        if button == "PADLTRIGGER" then
            if TTS_HOTKEY_ENABLED then
                addon.TTSUtil:ToggleSpeaking();
                if not inCombat then
                    KeyboardControl:SetPropagateKeyboardInput(false);
                end
                return
            end
        end

        if DEBUG_SHOW_GAMEPAD_BUTTON then
            addon.DevTool:PrintText(button);
        end

        if button == GAMEPAD_CONFIRM then

        elseif button == GAMEPAD_ALT then
            local TooltipFrame = addon.SharedTooltip;
            if TooltipFrame and TooltipFrame:IsShown() then
                TooltipFrame:ToggleAlternateInfo();
            end
        else
            if RepeatableButton[button] then
                self:RepeatAction(KeyRemap[button]);
            end
            button = KeyRemap[button];
        end

        if button then
            KeyboardControl:OnKeyDown(button, true);
        end
    end

    function KeyboardControl:OnGamePadButtonUp(button)
        self:StopRepeatingAction();
    end

    local function RepeatGamePadButton_OnUpdate(self, elapsed)
        self.repeatElapsed = self.repeatElapsed + elapsed;
        if self.repeatElapsed >= REPEAT_INTERVAL then
            self.repeatElapsed = 0;
            if self.repeatButton then
                KeyboardControl:OnKeyDown(self.repeatButton, true);
            else
                self:StopRepeatingAction();
            end
        end
    end

    function KeyboardControl:RepeatAction(button)
        self.repeatElapsed = -0.375;
        self.repeatButton = button;
        self:SetScript("OnUpdate", RepeatGamePadButton_OnUpdate);
    end

    function KeyboardControl:StopRepeatingAction()
        self:SetScript("OnUpdate", nil);
        self.repeatElapsed = nil;
    end


    local function PostInputDeviceChanged(dbValue)
        IS_KBM = dbValue == 1;

        --Switch ABXY is reversed
        local isSwitch = dbValue == 4;

        if isSwitch then
            GAMEPAD_CONFIRM = "PAD2";
            GAMEPAD_CANCEL = "PAD1";
            GAMEPAD_ALT = "PAD3";
            KeyRemap.PAD1 = "ESCAPE";
            KeyRemap.PAD2 = nil;
        else
            GAMEPAD_CONFIRM = "PAD1";
            GAMEPAD_CANCEL = "PAD2";
            GAMEPAD_ALT = "PAD4";
            KeyRemap.PAD1 = nil;
            KeyRemap.PAD2 = "ESCAPE";
        end
    end
    addon.CallbackRegistry:Register("PostInputDeviceChanged", PostInputDeviceChanged);
end


do  --Settings
    local function Settings_PrimaryControlKey(dbValue)
        DISABLE_CONTROL_KEY = false;

        if dbValue == 1 then
            KeyboardControl:UnregisterEvent("UPDATE_BINDINGS");
        elseif dbValue == 2 then
            KeyboardControl:RegisterEvent("UPDATE_BINDINGS");
        elseif dbValue == 0 then
            KeyboardControl:UnregisterEvent("UPDATE_BINDINGS");
            DISABLE_CONTROL_KEY = true;
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.PrimaryControlKey", Settings_PrimaryControlKey);

    local function Settings_CycleRewardHotkeyEnabled(dbValue)
        CYCLE_REWARD_ENABLED = dbValue == true
    end
    addon.CallbackRegistry:Register("SettingChanged.CycleRewardHotkeyEnabled", Settings_CycleRewardHotkeyEnabled);

    local function Settings_TTSEnabled(dbValue)
        TTS_ENABLED = dbValue == true
    end
    addon.CallbackRegistry:Register("SettingChanged.TTSEnabled", Settings_TTSEnabled);

    local function Settings_TTSUseHotkey(dbValue)
        TTS_HOTKEY_ENABLED = dbValue == true
    end
    addon.CallbackRegistry:Register("SettingChanged.TTSUseHotkey", Settings_TTSUseHotkey);

    local function Settings_UseCustomBindings(dbValue)
        USE_CUSTOM_BINDINGS = dbValue == true;
    end
    addon.CallbackRegistry:Register("SettingChanged.UseCustomBindings", Settings_UseCustomBindings);
end


do  --Error Prevention Disable Hotkey
    function KeyboardControl:DisableGossipHotkeys()
        local anyChange;

        if self.keyActions then
            for key, v in pairs(self.keyActions) do
                if v.obj and v.obj.type == "gossip" then
                    self.keyActions[key] = nil;
                    anyChange = true;
                end
            end
        end

        if anyChange then
            
        end
    end
end