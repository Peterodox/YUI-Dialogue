-- TomTom's Crazy Arrow is parented to UIParent, so our Hide UI hides it during dialogue.
-- We move it out of UIParent while the dialogue is open, then restore it afterwards.
-- Its own OnUpdate only hides it when the waypoint is gone, so nothing else needs patching.

local _, addon = ...


do
    local ADDON_NAME = "TomTom";

    local requiredMethods = {
        "TomTomCrazyArrow",
    };

    local function OnAddOnLoaded()
        local CallbackRegistry = addon.CallbackRegistry;
        local GetDBBool = addon.GetDBBool;
        local InCombatLockdown = InCombatLockdown;
        local UIParent = UIParent;
        local CrazyArrow = TomTomCrazyArrow;

        local FrameUtil = CreateFrame("Frame");

        function FrameUtil:MoveOutOfUIParent()
            if self.frameHandled or InCombatLockdown() then return end;
            self.frameHandled = true;

            --Carry UIParent's scale on the holder so TomTom's own SetScale keeps working
            self:SetScale(UIParent:GetEffectiveScale());
            self:SetAllPoints(UIParent);
            CrazyArrow:SetParent(self);
        end

        function FrameUtil:RestoreToUIParent()
            if not self.frameHandled then return end;

            if InCombatLockdown() then
                self:RegisterEvent("PLAYER_REGEN_ENABLED");
                return
            end

            self:UnregisterEvent("PLAYER_REGEN_ENABLED");
            self.frameHandled = false;
            CrazyArrow:SetParent(UIParent);
        end

        FrameUtil:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_REGEN_ENABLED" then
                self:RestoreToUIParent();
            end
        end);

        local function OnDialogueUIShow()
            if not (GetDBBool("HideUI") and GetDBBool("KeepTomTomArrowVisible")) then return end;
            FrameUtil:MoveOutOfUIParent();
        end
        CallbackRegistry:Register("DialogueUI.Show", OnDialogueUIShow);

        local function OnDialogueUIHide()
            FrameUtil:RestoreToUIParent();
        end
        CallbackRegistry:Register("DialogueUI.Hide", OnDialogueUIHide);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end
