local _, addon = ...

local CallbackRegistry = {};
CallbackRegistry.events = {};
addon.CallbackRegistry = CallbackRegistry;

local tinsert = table.insert;
local type = type;
local ipairs = ipairs;

--[[
    callbackType:
        1. Function func(owner)
        2. Method owner:func()
--]]

function CallbackRegistry:Register(event, func, owner)
    if not self.events[event] then
        self.events[event] = {};
    end

    local callbackType;

    if type(func) == "string" then
        callbackType = 2;
    else
        callbackType = 1;
    end

    tinsert(self.events[event], {callbackType, func, owner})
end

function CallbackRegistry:Trigger(event, ...)
    if self.events[event] then
        for _, cb in ipairs(self.events[event]) do
            if cb[1] == 1 then
                if cb[3] then
                    cb[2](cb[3], ...);
                else
                    cb[2](...);
                end
            else
                cb[3][cb[2]](cb[3], ...);
            end
        end
    end
end

function CallbackRegistry:RegisterTutorial(tutorialFlag, func, owner)
    local event = "Tutorial."..tutorialFlag;
    self:Register(event, func, owner);
end


do  --UIParent OnShow/OnHide
    local frame = CreateFrame("Frame", nil, UIParent);

    frame:SetScript("OnShow", function()
        CallbackRegistry:Trigger("UIParent.Show");
    end);

    frame:SetScript("OnHide", function()
        CallbackRegistry:Trigger("UIParent.Hide");
    end);
end


do  --Public methods for addon compatibility (NOT IMPLEMENTED)

    --Private
    local IsCallbackAllowed = {};
    local EventObject = {};
    local PublicCallbacks = {};

    local function AddSupportedPublicCallback(event, objectGetter)
        IsCallbackAllowed[event] = true;
        if objectGetter then
            if EventObject[event] then
                addon.API.PrintMessage(string.format("Public Event (%s) already has a owner"));
            else
                EventObject[event] = objectGetter;
            end
        end
    end
    addon.AddSupportedPublicCallback = AddSupportedPublicCallback;


    function CallbackRegistry:TriggerExternalEvent(event, ...)
        if IsCallbackAllowed[event] and PublicCallbacks[event] then
            local objectGetter = EventObject[event];
            local obj;

            if objectGetter then
                obj = objectGetter();
            end

            for _, cb in ipairs(PublicCallbacks[event]) do
                cb(obj, ...);
            end
        end
    end


    --Public
    local function RegisterCallback(event, callback)
        --payloads: isRegistered, isNew

        if event and type(event) == "string" and callback and type(callback) == "function" then
            if not PublicCallbacks[event] then
                PublicCallbacks[event] = {};
            end

            for _, cb in ipairs(PublicCallbacks[event]) do
                if cb == callback then
                    return true, false
                end
            end

            table.insert(PublicCallbacks[event], callback);

            return true, true
        end

        return false, false
    end
    --DialogueUIAPI.RegisterCallback = RegisterCallback;
end