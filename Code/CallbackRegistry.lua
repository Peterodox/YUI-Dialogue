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