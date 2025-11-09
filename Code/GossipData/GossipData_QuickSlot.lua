-- Show Quick Slot to use QuestLogSpecialItem


local _, addon = ...
if not addon.IS_MIDNIGHT then return end;


local QuestAreaTrigger = addon.QuestAreaTrigger;
local API = addon.API;


local Handler_86838 = QuestAreaTrigger:CreateQuestHandler(86838);    --Renewal for the Weary (Show Quick Slot to use Faol's Benediction)
do
    Handler_86838:SetMapAndCoords(2424, 0.5056, 0.4122, 0.5473, 0.4865);

    function Handler_86838:IsConditionMet()
        if API.ReadyForTurnIn(self.questID) then
            return false
        end
        return API.DoesValueExist(C_UnitAuras.GetUnitAuraBySpellID("npc", 1264471));    --requires buff: "Nearly Depleted"
    end

    function Handler_86838:OnEvent(event, ...)
        if event == "GOSSIP_SHOW" then
            if Handler_86838:IsConditionMet() then
                Handler_86838:TryShowQuickSlot();
            else
                Handler_86838:HideQuickSlot();
            end
        elseif event == "GOSSIP_CLOSED" then
            Handler_86838:HideQuickSlot();
        elseif event == "PLAYER_TARGET_CHANGED" or event == "UNIT_AURA" then
            if not Handler_86838:IsConditionMet() then
                Handler_86838:HideQuickSlot();
            end
        end
    end

    function Handler_86838:OnEnterArea()
        if self.inArea then return end;
        self.inArea = true;

        if not self.listener then
            self.listener = CreateFrame("Frame");
            self.listener:SetScript("OnEvent", self.OnEvent);
        end
        self.listener:RegisterEvent("GOSSIP_SHOW");
        self.listener:RegisterEvent("GOSSIP_CLOSED");
        self.listener:RegisterEvent("PLAYER_TARGET_CHANGED");
        self.listener:RegisterUnitEvent("UNIT_AURA", "npc");
        self:OnEvent();
    end

    function Handler_86838:OnLeaveArea()
        if not self.inArea then return end;
        self.inArea = false;

        if self.listener then
            self.listener:UnregisterEvent("GOSSIP_SHOW");
            self.listener:UnregisterEvent("GOSSIP_CLOSED");
            self.listener:UnregisterEvent("PLAYER_TARGET_CHANGED");
            self.listener:UnregisterEvent("UNIT_AURA");
        end
        self:HideQuickSlot();
    end

    function Handler_86838:TryShowQuickSlot()
        if addon.QuickSlotManager:AddQuestLogSpecialItem(self.questID) then
            self.buttonShown = true;
        end
    end

    function Handler_86838:HideQuickSlot(useDelay)
        if self.buttonShown then
            self.buttonShown = false;
            addon.QuickSlotManager:HideItemButton(true);
        end
    end
end


addon.CallbackRegistry:RegisterLoadingCompleteCallback(function()
    QuestAreaTrigger:AddQuestHandler(Handler_86838);
end);