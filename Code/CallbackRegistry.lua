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


do  --AsyncCallback
    local EL = CreateFrame("Frame");

    EL.LoadQuest = C_QuestLog.RequestLoadQuestByID;     --Not available in 60 Classic
    EL.LoadItem = C_Item.RequestLoadItemDataByID;
    EL.LoadSpell = C_Spell.RequestLoadSpellData;

    function EL:RunAllCallbacks(list)
        for id, callbacks in pairs(list) do
            for _, callback in ipairs(callbacks) do
                callback(id);
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
        end

        if list and id and success then
            if list[id] then
                for _, callback in ipairs(list[id]) do
                    callback(id);
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
        end
    end

    function EL:AddCallback(key, id, callback)
        if not self[key] then
            self[key] = {};
        end

        if not self[key][id] then
            self[key][id] = {};
        end

        tinsert(self[key][id], callback);
    end


    function CallbackRegistry:LoadQuest(id, callback)
        EL:AddCallback("questCallbacks", id, callback);
        if EL.LoadQuest then
            EL:RegisterEvent("QUEST_DATA_LOAD_RESULT");
            EL.LoadQuest(id);
        else
            EL.runCallbackAfter = true;
        end
        EL.t = 0;
        EL:SetScript("OnUpdate", EL.OnUpdate);
    end

    function CallbackRegistry:LoadItem(id, callback)
        EL:AddCallback("itemCallbacks", id, callback);
        if EL.LoadItem then
            EL:RegisterEvent("ITEM_DATA_LOAD_RESULT");
            EL.LoadItem(id);
        else
            EL.runCallbackAfter = true;
        end
        EL.t = 0;
        EL:SetScript("OnUpdate", EL.OnUpdate);
    end

    function CallbackRegistry:LoadSpell(id, callback)
        EL:AddCallback("spellCallbacks", id, callback);
        if EL.LoadSpell then
            EL:RegisterEvent("SPELL_DATA_LOAD_RESULT");
            EL.LoadSpell(id);
        else
            EL.runCallbackAfter = true;
        end
        EL.t = 0;
        EL:SetScript("OnUpdate", EL.OnUpdate);
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