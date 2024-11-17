local _, addon = ...

local API = addon.API;
local pairs = pairs;

local Throttler;

local DEFAULT_DURATION = 0.5;

local ThrottleDuration = {
    --[ActionName] = second,

    GamePadChooseQuestReward = 0.5,
};

local Counter = {};

local function Throttler_OnUpdate(self, elapsed)
    local anyUp;

    for k, v in pairs(Counter) do
        if v < (ThrottleDuration[k] or DEFAULT_DURATION) then
            Counter[k] = v + elapsed;
            anyUp = true;
        else
            Counter[k] = nil;
        end
    end

    if not anyUp then
        self:SetScript("OnUpdate", nil);
    end
end

local function CheckActionThrottled(actionName)
    --Query puts the action on timer

    if not Throttler then
        Throttler = CreateFrame("Frame");
    end

    if not Counter[actionName] then
        Counter[actionName] = 0;
        return false
    end

    Throttler:SetScript("OnUpdate", Throttler_OnUpdate);
    return true
end
API.CheckActionThrottled = CheckActionThrottled;