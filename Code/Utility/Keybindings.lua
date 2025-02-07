local _, addon = ...
local L = addon.L;
local API = addon.API;
local CallbackRegistry = addon.CallbackRegistry;
local pairs = pairs;
local DB_Bindings;

local BindingUtil = {};
addon.BindingUtil = BindingUtil;

local DefaultKeybindings = {    --KB&M only
    Confirm = "SPACE",
    Settings = "F1",
    TTS = "R",
    Option1 = "1",
    Option2 = "2",
    Option3 = "3",
    Option4 = "4",
    Option5 = "5",
    Option6 = "6",
    Option7 = "7",
    Option8 = "8",
    Option9 = "9",
};

local SetBindingResult = {
    Unchanged = 0,
    Success = 1,
    Conflict = 2,
    Invalid = 3,
};

local InvalidKeys = {
    ESCAPE = true,
    UNKNOWN = true,
    PRINTSCREEN = true,
    LALT = true,
    RALT = true,
    LSHIFT = true,
    RSHIFT = true,
    LCTRL = true,
    RCTRL = true,
    TAB = true,
    BACKSPACE = true,
    CAPSLOCK = true,
    --F1 = true,          --Reserved for Settings
};

BindingUtil.KeyToAction = {};
BindingUtil.ActionToKey = {};

function BindingUtil:IsKeyInvalid(key)
    return InvalidKeys[key]
end

function BindingUtil:GetBindingKey(action)
    return self.ActionToKey[action]
end

function BindingUtil:SetKeyAction(key, action)
    if key then
        self.KeyToAction[key] = action;
    end
end

function BindingUtil:SetActionKey(action, key)
    self.ActionToKey[action] = key;
end

function BindingUtil:SetBindingKey(action, key)
    for a, k in pairs(DB_Bindings) do
        if k == key then
            DB_Bindings[a] = nil;
        end
    end
    DB_Bindings[action] = key;
    self:SetKeyAction(key, action);
    self:SetActionKey(action, key);
end

function BindingUtil:GetKeyAction(key)
    return self.KeyToAction[key]
end

function BindingUtil:CheckAndSetBindingKey(action, newKey, override)
    local result;

    if newKey and self:IsKeyInvalid(newKey) then
        result = SetBindingResult.Invalid;
    else
        if self:GetBindingKey(action) == newKey then
            result = SetBindingResult.Unchanged;
        else
            local oldAction = self:GetKeyAction(newKey);
            if oldAction then
                if override then
                    self:SetBindingKey(action, newKey);
                    result = SetBindingResult.Success;
                else
                    result = SetBindingResult.Conflict;
                end
            else
                self:SetBindingKey(action, newKey);
                result = SetBindingResult.Success;
            end
        end
    end

    if result == SetBindingResult.Success then
        self:LoadBindings();
    end

    return result
end

function BindingUtil:ClearCustomKeybindings()
    for action, defaultKey in pairs(DefaultKeybindings) do
        DB_Bindings[action] = nil;
    end
end

function BindingUtil:RemapActions()
    self.ActionToKey = {};
    for key, action in pairs(self.KeyToAction) do
        self.ActionToKey[action] = key;
    end
end

function BindingUtil:LoadBindings()
    self.KeyToAction = {};
    self.ActionToKey = {};

    if not DB_Bindings then return end;

    local type = type;
    local key;

    for action, defaultKey in pairs(DefaultKeybindings) do
        key = DB_Bindings[action];
        if key == DefaultKeybindings[action] then
            key = nil;
            DB_Bindings[action] = nil;
        end
        if key ~= nil then
            if type(key) == "string" and not self.KeyToAction[key] then
                self.KeyToAction[key] = action;
                self.ActionToKey[action] = key;
            else
                DB_Bindings[action] = nil;
            end
        end
    end

    for action, defaultKey in pairs(DefaultKeybindings) do
        if not self.ActionToKey[action] then
            if not self.KeyToAction[defaultKey] then
                self.ActionToKey[action] = defaultKey;
                self.KeyToAction[defaultKey] = action;
            end
        end
    end

    BindingUtil:RemapActions();
    self:UpdateSettings();
end

do  --Control Used in KeyboardControl.lua
    local ActiveKeyActions = {};
    local ActiveActionKeys = {};

    function BindingUtil:UpdateSettings()
        ActiveKeyActions = {};
        ActiveActionKeys = {};

        if addon.GetDBBool("UseCustomBindings") then
            ActiveKeyActions = self.KeyToAction;
            ActiveActionKeys = self.ActionToKey;
        else
            local newConfirmKey;
            local dbValue = addon.GetDBValue("PrimaryControlKey");

            if dbValue == 1 then
                newConfirmKey = DefaultKeybindings.Confirm;
            elseif dbValue == 2 then
                newConfirmKey = API.GetBestInteractKey() or DefaultKeybindings.Confirm;
            elseif dbValue == 0 then
                newConfirmKey = "DISABLED";
            end

            for action, key in pairs(DefaultKeybindings) do
                if action == "Confirm" then
                    key = newConfirmKey;
                end
                ActiveKeyActions[key] = action;
                ActiveActionKeys[action] = key;
            end
        end

        CallbackRegistry:Trigger("CustomBindingChanged");
    end

    function BindingUtil:GetActiveKeyAction(key)
        return ActiveKeyActions[key]
    end

    function BindingUtil:GetActiveActionKey(action)
        if ActiveActionKeys[action] and ActiveActionKeys[action] ~= "DISABLED" then
            return ActiveActionKeys[action]
        end
    end

    function BindingUtil:GetActionTooltip(action)
        local key = self:GetActiveActionKey(action);
        if key then
            return L["Bound To"]..key
        else
            return L["Not Bound"]
        end
    end
end

local function DialogueUI_Loaded(savedVariable)
    if not (savedVariable.CustomBindings and type(savedVariable.CustomBindings) == "table") then
        savedVariable.CustomBindings = {};
    end
    DB_Bindings = savedVariable.CustomBindings;
    BindingUtil:LoadBindings();
end
CallbackRegistry:Register("ADDON_LOADED", DialogueUI_Loaded);


local function Settings_UseCustomBindings(dbValue)
    BindingUtil:LoadBindings();
end
CallbackRegistry:Register("SettingChanged.UseCustomBindings", Settings_UseCustomBindings);
CallbackRegistry:Register("SettingChanged.PrimaryControlKey", Settings_UseCustomBindings);