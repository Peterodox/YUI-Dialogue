local _, addon = ...

local CallbackRegistry = {};
CallbackRegistry.events = {};
addon.CallbackRegistry = CallbackRegistry;

local tinsert = table.insert;
local tremove = table.remove;
local type = type;
local ipairs = ipairs;

--[[
    callbackType:
        1. Function func(owner)
        2. Method owner:func()
--]]

function CallbackRegistry:Register(event, func, owner, prioritized)
    if not self.events[event] then
        self.events[event] = {};
    end

    local callbackType;

    if type(func) == "string" then
        callbackType = 2;
    else
        callbackType = 1;
    end

    if prioritized then
        tinsert(self.events[event], 1, {callbackType, func, owner})
    else
        tinsert(self.events[event], {callbackType, func, owner})
    end
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

function CallbackRegistry:UnregisterCallback(event, callback, owner)
    if self.events[event] then
        local callbacks = self.events[event];
        local i = 1;
        local cb = callbacks[i];

        if type(callback) == "string" then
            if owner then
                while cb do
                    if cb[1] == 2 and cb[2] == callback and cb[3] == owner then
                        tremove(callbacks, i);
                    else
                        i = i + 1;
                    end
                    cb = callbacks[i];
                end
            else
                while cb do
                    if cb[1] == 2 and cb[2] == callback then
                        tremove(callbacks, i);
                    else
                        i = i + 1;
                    end
                    cb = callbacks[i];
                end
            end
        else
            while cb do
                if cb[1] == 1 and cb[2] == callback then
                    tremove(callbacks, i);
                else
                    i = i + 1;
                end
                cb = callbacks[i];
            end
        end
    end
end

function CallbackRegistry:UnregisterEvent(event)
    self.events[event] = nil;
end

function CallbackRegistry:RegisterTutorial(tutorialFlag, func, owner)
    local event = "Tutorial."..tutorialFlag;
    self:Register(event, func, owner);
end

function CallbackRegistry:RegisterLoadingCompleteCallback(func, owner, prioritized)
    self:Register("LOADING_SCREEN_DISABLED", func, owner, prioritized)
end


local Processor = CreateFrame("Frame");

local function Processor_OnUpdate(self, elapsed)
    self:SetScript("OnUpdate", nil);
    if self.triggerQueue and self.anyDelayedTrigger then
        self.anyDelayedTrigger = nil;
        for event, args in pairs(self.triggerQueue) do
            CallbackRegistry:Trigger(event, args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]);
        end
        self.triggerQueue = nil;
    end
end

function CallbackRegistry:TriggerOnNextUpdate(event, ...)
    --Use Case: in case Lua error appears and clogs other important processes
    --Currently used by HelpTip
    if self.events[event] then
        if not Processor.anyDelayedTrigger then
            Processor.triggerQueue = {};
            Processor.anyDelayedTrigger = true;
        end
        Processor.triggerQueue[event] = {...};
        Processor:SetScript("OnUpdate", Processor_OnUpdate);
    end
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


do  --AsyncCallback
    local EL = CreateFrame("Frame");

    --LoadQuestAPI is not available in 60 Classic
    --In this case we will run all callbacks when the time is up
    EL.LoadQuest = C_QuestLog.RequestLoadQuestByID;
    EL.LoadItem = C_Item.RequestLoadItemDataByID;
    EL.LoadSpell = C_Spell.RequestLoadSpellData;

    function EL:RunAllCallbacks(list)
        for id, callbacks in pairs(list) do
            for _, callbackInfo in ipairs(callbacks) do
                if (callbackInfo.oneTime and not callbackInfo.processed) or (callbackInfo.oneTime == false) then
                    callbackInfo.processed = true;
                    callbackInfo.func(id);
                end
            end
        end
    end

    function EL:OnEvent(event, ...)
        local id, success = ...
        local list;

        if event == "QUEST_DATA_LOAD_RESULT" then
            list = self.questCallbacks;
        elseif event == "ITEM_DATA_LOAD_RESULT" then
            list = self.itemCallbacks;
        elseif event == "SPELL_DATA_LOAD_RESULT" then
            list = self.spellCallbacks;
        elseif event == "TOOLTIP_DATA_UPDATE" then
            list = self.npcCallbacks;
            success = true;
        end

        if list and id and success then
            if list[id] then
                for _, callbackInfo in ipairs(list[id]) do
                    if (callbackInfo.oneTime and not callbackInfo.processed) or (callbackInfo.oneTime == false) then
                        callbackInfo.processed = true;
                        callbackInfo.func(id);
                    end
                end
            end
        end

        self.t = 0; --Reset close count down
    end
    EL:SetScript("OnEvent", EL.OnEvent);

    function EL:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.5 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);

            if self.questCallbacks then
                if self.LoadQuest then
                    self:UnregisterEvent("QUEST_DATA_LOAD_RESULT");
                end
                if self.runCallbackAfter then
                    self:RunAllCallbacks(self.questCallbacks);
                end
                self.questCallbacks = nil;
            end

            if self.itemCallbacks then
                if self.LoadItem then
                    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
                end
                self:RunAllCallbacks(self.itemCallbacks);
                self.itemCallbacks = nil;
            end

            if self.spellCallbacks then
                if self.LoadSpell then
                    self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
                end
                self:RunAllCallbacks(self.spellCallbacks);
                self.spellCallbacks = nil;
            end

            if self.npcCallbacks then
                if self.LoadNPC then
                    self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
                end
                self:RunAllCallbacks(self.npcCallbacks);
                self.npcCallbacks = nil;
            end
        end
    end

    function EL:AddCallback(key, id, callback, oneTime)
        if not self[key] then
            self[key] = {};
        end

        if not self[key][id] then
            self[key][id] = {};
        end

        if oneTime == nil then
            oneTime = true;
        end

        local callbackInfo = {
            func = callback,
            oneTime = oneTime,
            processed = false,
        };

        tinsert(self[key][id], callbackInfo);
    end


    function CallbackRegistry:LoadQuest(id, callback, oneTime)
        EL:AddCallback("questCallbacks", id, callback, oneTime);
        if EL.LoadQuest then
            EL:RegisterEvent("QUEST_DATA_LOAD_RESULT");
            EL.LoadQuest(id);
        else
            EL.runCallbackAfter = true;
        end
        EL.t = 0;
        EL:SetScript("OnUpdate", EL.OnUpdate);
    end

    function CallbackRegistry:LoadItem(id, callback, oneTime)
        EL:AddCallback("itemCallbacks", id, callback, oneTime);
        if EL.LoadItem then
            EL:RegisterEvent("ITEM_DATA_LOAD_RESULT");
            EL.LoadItem(id);
        else
            EL.runCallbackAfter = true;
        end
        EL.t = 0;
        EL:SetScript("OnUpdate", EL.OnUpdate);
    end

    function CallbackRegistry:LoadSpell(id, callback, oneTime)
        EL:AddCallback("spellCallbacks", id, callback, oneTime);
        if EL.LoadSpell then
            EL:RegisterEvent("SPELL_DATA_LOAD_RESULT");
            EL.LoadSpell(id);
        else
            EL.runCallbackAfter = true;
        end
        EL.t = 0;
        EL:SetScript("OnUpdate", EL.OnUpdate);
    end


    if C_TooltipInfo then
        function CallbackRegistry:LoadNPC(creatureID, callback, isRequery)
            local tooltipData = addon.TooltipAPI.GetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            local dataInstanceID, newCallback;
            if tooltipData and tooltipData.lines then
                local name = tooltipData.lines[1].leftText;
                if name and name ~= "" then
                    callback(creatureID, name);
                else
                    dataInstanceID = tooltipData.dataInstanceID;
                    newCallback = function()
                        local tooltipData = addon.TooltipAPI.GetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
                        local name = tooltipData.lines[1].leftText;
                        if name and name ~= "" then
                            callback(creatureID, name);
                        end
                    end
                end
            elseif not isRequery then
                dataInstanceID = 0;
                newCallback = function()
                    local tooltipData = addon.TooltipAPI.GetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
                    local name = tooltipData and tooltipData.lines and tooltipData.lines[1].leftText;
                    if name and name ~= "" then
                        callback(creatureID, name);
                    end
                end
            end

            if dataInstanceID and newCallback then
                EL:AddCallback("npcCallbacks", dataInstanceID, newCallback);
                EL:RegisterEvent("TOOLTIP_DATA_UPDATE");
                if not EL.t then
                    EL.t = 0;
                end
                if EL.t > 0 then
                    --Extend the shutdown countdown because we usually acquire NPC name during log-in
                    EL.t = -0.5;
                end
                EL:SetScript("OnUpdate", EL.OnUpdate);
            end
        end
    else
        function CallbackRegistry:LoadNPC()

        end
    end
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