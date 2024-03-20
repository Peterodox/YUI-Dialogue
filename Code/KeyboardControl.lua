-- Press Key to select option
-- Planned to support controller in the future

local _, addon = ...
local API = addon.API;
local Clipboard = addon.Clipboard;


local DEFAULT_CONTROL_KEY = "SPACE";

-- Custom Settings
local ENABLE_KEYCONTROL_IN_COMBAT = true;
local PRIMARY_CONTROL_KEY = DEFAULT_CONTROL_KEY;
local USE_INTERACT_KEY = false;
------------------

local InCombatLockdown = InCombatLockdown;
local tostring = tostring;
local type = type;

local KeyboardControl = CreateFrame("Frame");
KeyboardControl:Hide();
KeyboardControl:SetFrameStrata("TOOLTIP");
KeyboardControl:SetFixedFrameStrata(true);
addon.KeyboardControl = KeyboardControl;

KeyboardControl.noPropagateFrame = CreateFrame("Frame", nil, KeyboardControl);
KeyboardControl.noPropagateFrame:SetPropagateKeyboardInput(false);

function KeyboardControl:ResetKeyActions()
    self.keyActions = {};
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

function KeyboardControl:SetKeyFunction(key, func)
    if not self:CanSetKey(key) then return end;

    key = tostring(key);

    if not self.keyActions[key] then
        self.keyActions[key] = {
            obj = func,
            type = "function",
        };
        return key
    end
end

function KeyboardControl:SetKeyButton(key, buttonToClick)
    if key == "PRIMARY" then
        key = PRIMARY_CONTROL_KEY;
    end

    if not self:CanSetKey(key) then return end;

    key = tostring(key)

    if not self.keyActions[key] then
        self.keyActions[key] = {
            obj = buttonToClick,
            type = "button",
        };
        return key
    end
end

function KeyboardControl:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:RegisterEvent("PLAYER_REGEN_ENABLED");
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
end
KeyboardControl:SetScript("OnHide", KeyboardControl.OnHide);

function KeyboardControl:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");

    if self.bindingDirty then
        self.bindingDirty = nil;
        if USE_INTERACT_KEY then
            local newKey = API.GetBestInteractKey();
            if newKey and newKey ~= PRIMARY_CONTROL_KEY then
                PRIMARY_CONTROL_KEY = newKey;
                addon.DialogueUI:OnSettingsChanged();
            end
        end
    end
end

KeyboardControl:SetScript("OnShow", KeyboardControl.OnShow);

function KeyboardControl:OnKeyDown(key, fromGamePad)
    local valid = false;
    local processed = false;

    if key == "PAD1" then
        valid = KeyboardControl.parent:ClickFocusedObject();
        if valid then
            processed = true;
        else
            key = PRIMARY_CONTROL_KEY;
        end
    end

    if (not processed) and (key == PRIMARY_CONTROL_KEY) and (not KeyboardControl.keyActions[key]) then
        key = "1";
    end

    if key == "ESCAPE" then
        valid = true;

        if Clipboard:IsShown() then
            Clipboard:Hide();
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
    elseif key == "UP" then
        valid = true;
        processed = true;
        KeyboardControl.parent:FocusPreviousObject();
    elseif key == "DOWN" then
        valid = true;
        processed = true;
        KeyboardControl.parent:FocusNextObject();
    elseif key == "F1" then
        valid = true;
        processed = true;
        DialogueUI_ShowSettingsFrame();
    end

    if (not processed) and KeyboardControl.keyActions[key] then
        valid = true;

        local actionType = KeyboardControl.keyActions[key].type;
        local object = KeyboardControl.keyActions[key].obj;

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

    if not InCombatLockdown() then
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
            listener = self.noPropagateFrame;
        end
    else
        listener = self;
    end

    if listener then
        listener:SetScript("OnKeyDown", self.OnKeyDown);
        listener:SetScript("OnGamePadButtonDown", self.OnGamePadButtonDown);
        listener:EnableGamePadButton(true);
        listener:EnableKeyboard(true);
    end
end

function KeyboardControl:StopListeningKeys()
    self:SetScript("OnKeyDown", nil);
    self.noPropagateFrame:SetScript("OnKeyDown", nil);

    self:SetScript("OnGamePadButtonDown", nil);
    self.noPropagateFrame:SetScript("OnGamePadButtonDown", nil);

    self:EnableGamePadButton(false);
    self.noPropagateFrame:EnableGamePadButton(false);

    self:EnableKeyboard(false);
    self.noPropagateFrame:EnableKeyboard(false);
end

function KeyboardControl.GetPrimaryControlKey()
    return PRIMARY_CONTROL_KEY
end


do  --GamePad/Controller
    local KeyRemap = {
        PAD2 = "ESCAPE",
        PADDUP = "UP",
        PADDDOWN = "DOWN",
        PADFORWARD = "F1",  --Toggle Settings
        PADBACK = "ESCAPE",
        PADDLEFT = "UP",
        PADDRIGHT = "DOWN",
    };

    function KeyboardControl:OnGamePadButtonDown(button)
        --print("|cFF8cd964"..button);
        if button == "PAD1" then

        elseif button == "PAD4" then
            local TooltipFrame = addon.SharedTooltip;
            if TooltipFrame and TooltipFrame:IsShown() then
                TooltipFrame:ToggleAlternateInfo()
            end
        else
            button = KeyRemap[button];
        end
        
        if button then
            KeyboardControl:OnKeyDown(button, true);
        end
    end
end


do  --Settings
    local function Settings_PrimaryControlKey(dbValue)
        local newKey;

        if dbValue == 1 then
            newKey = DEFAULT_CONTROL_KEY;
            KeyboardControl:UnregisterEvent("UPDATE_BINDINGS");
            USE_INTERACT_KEY = false;
        elseif dbValue == 2 then
            newKey = API.GetBestInteractKey();
            KeyboardControl:RegisterEvent("UPDATE_BINDINGS");
            USE_INTERACT_KEY = true;
        end

        if newKey and newKey ~= PRIMARY_CONTROL_KEY then
            PRIMARY_CONTROL_KEY = newKey;
            addon.DialogueUI:OnSettingsChanged();
            print("KEY", dbValue, newKey)
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.PrimaryControlKey", Settings_PrimaryControlKey);
end