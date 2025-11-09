local _, addon = ...
local API = addon.API;


--local IsInsideQuestBlob = C_Minimap.IsInsideQuestBlob or API.AlwaysFalse;
local IsOnQuest = C_QuestLog.IsOnQuest;
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted;
local GetBestMapForUnit = C_Map.GetBestMapForUnit;


local EL = CreateFrame("Frame");
addon.QuestAreaTrigger = EL;
local CoordTracker = CreateFrame("Frame");


do  --CoordTracker
    local UnitPosition = UnitPosition;
    local GetPlayerMapPosition = C_Map.GetPlayerMapPosition;

    CoordTracker.mapData = {};

    function CoordTracker:CacheMapData(uiMapID)
        if self.mapData[uiMapID] then return end;

        local instance, topLeft = C_Map.GetWorldPosFromMapPos(uiMapID, {x=0, y=0});
        local width, height = C_Map.GetMapWorldSize(uiMapID);

        if topLeft then
            local top, left = topLeft:GetXY()
            self.mapData[uiMapID] = {width, height, left, top};
        end
    end

    function CoordTracker:GetPlayerMapCoordFallback(uiMapID)
        local position = GetPlayerMapPosition(uiMapID, "player");
        if position then
            return position.x, position.Y
        end
    end

    function CoordTracker:GetPlayerMapCoord(uiMapID)
        self.y, self.x = UnitPosition("player");
        if not (self.y and self.x) then return self:GetPlayerMapCoord_Fallback(uiMapID) end;

        if uiMapID ~= self.lastUiMapID then
            self.lastUiMapID = uiMapID;
            self:CacheMapData(uiMapID);
            self.data = self.mapData[uiMapID];
        end

        if not self.data or self.data[1] == 0 or self.data[2] == 0 then return self:GetPlayerMapCoordFallback(uiMapID) end;

        return (self.data[3] - self.x) / self.data[1], (self.data[4] - self.y) / self.data[2]
    end

    function CoordTracker:SetActiveHandler(handler)
        if handler and self.handler and handler ~= self.handler then
            self.handler:OnLeaveArea();
        end

        self.t = 1;
        self.handler = handler;
        self.inArea = nil;
        if handler then
            self.activeUiMapID = handler.uiMapID;
            self:SetScript("OnUpdate", self.OnUpdate);
            --print("CoordTracker ON");
        else
            self:SetScript("OnUpdate", nil);
            --print("CoordTracker OFF");
        end
    end

    function CoordTracker:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.5 then
            self.t = 0;
            self._x, self._y = self:GetPlayerMapCoord(self.activeUiMapID);
            if self._x and self._x > self.handler.x1 and self._x < self.handler.x2 and self._y > self.handler.y1 and self._y < self.handler.y2 then
                if not self.inArea then
                    self.inArea = true;
                    if self.handler then
                        self.handler:OnEnterArea();
                    end
                end
            else
                if self.inArea then
                    self.inArea = false;
                    if self.handler then
                        self.handler:OnLeaveArea();
                    end
                end
            end
        end
    end


    --APIs
    function API.GetPlayerMapCoord(uiMapID)
        return CoordTracker:GetPlayerMapCoord(uiMapID)
    end

    local function YeetPlayerCoord()
        local uiMapID = GetBestMapForUnit("player");
        local x, y = CoordTracker:GetPlayerMapCoord(uiMapID);
        print(string.format("%.4f, %.4f", x, y));
    end
end


do  --EL, QuestAreaTrigger
    EL.supported = C_EventUtils.IsEventValid("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED");

    EL.events = {
        "QUEST_ACCEPTED",
        "QUEST_TURNED_IN",
        "QUEST_REMOVED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_MAP_CHANGED",
    };

    function EL:ListenEvents(state)
        if state then
            for _, event in ipairs(self.events) do
                self:RegisterEvent(event);
            end
            self:SetScript("OnEvent", self.OnEvent);
        else
            for _, event in ipairs(self.events) do
                self:UnregisterEvent(event);
            end
            self:SetScript("OnEvent", nil);
        end
    end

    function EL:OnEvent(event, ...)
        if event == "PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED" then
            self:InsideQuestBlobStateChanged(...);
        else
            self:RequestUpdateQuests();
        end
    end

    function EL:InsideQuestBlobStateChanged(questID, isInside)
        if questID then
            if self.questHandlers[questID] then
                --print(questID, isInside);
            end
        end
    end

    function EL:AddQuestHandler(handler)
        if not self.supported then return end;

        if not handler.questID then
            return
        end

        if not self.questHandlers then
            self.questHandlers = {};
        end

        self.questHandlers[handler.questID] = handler;
        self:RequestUpdateQuests();
        self.t = -2;
    end

    function EL:RequestUpdateQuests()
        self.t = -0.1;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function EL:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            self:UpdateQuestWatches();
        end
    end

    function EL:UpdateQuestWatches()
        local trackQuestBlob;
        local activeHandler;
        local anyValidQuest;

        local uiMapID = GetBestMapForUnit("player");    --May return the continent uiMapID during the initial login

        for questID, handler in pairs(self.questHandlers) do
            if IsOnQuest(questID) then
                if handler.isOnQuest == false then
                    handler:OnAccepted();
                end
                handler.isOnQuest = true;
                if handler.trackQuestBlob then
                    trackQuestBlob = true;
                end

                if handler.uiMapID and handler.uiMapID == uiMapID then
                    activeHandler = handler;
                end
            else
                if handler.isOnQuest then
                    handler:OnRemoved();
                end
                handler.isOnQuest = false;
            end

            if not IsQuestFlaggedCompleted(questID) then
                anyValidQuest = true;
            end
        end

        if trackQuestBlob then
            self:RegisterEvent("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED");
        else
            self:UnregisterEvent("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED");
        end

        CoordTracker:SetActiveHandler(activeHandler);

        self:ListenEvents(anyValidQuest);
    end
end


do  --QuestHandler
    local QuestHandlerMixin = {};

    function QuestHandlerMixin:OnAccepted()
        --print(self.questID, "OnAccepted");
    end

    function QuestHandlerMixin:OnRemoved()
        --print(self.questID, "OnRemoved");
        self:OnLeaveArea();
    end

    function QuestHandlerMixin:OnEnterArea()

    end

    function QuestHandlerMixin:OnLeaveArea()

    end

    function QuestHandlerMixin:SetMapAndCoords(uiMapID, xLow, yLow, xHigh, yHigh)
        self.trackPlayerCoord = true;
        self.trackQuestBlob = nil;
        self.uiMapID = uiMapID;
        self.x1, self.y1, self.x2, self.y2 =  xLow, yLow, xHigh, yHigh;
    end

    function QuestHandlerMixin:SetTrackQuestBlob()
        self.trackQuestBlob = true;
    end


    function EL:CreateQuestHandler(questID)
        local handler = {};
        Mixin(handler, QuestHandlerMixin);
        handler.questID = questID;
        return handler
    end
end