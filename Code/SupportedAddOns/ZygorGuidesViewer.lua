-- Zygor's guide window is parented to UIParent, so our Hide UI hides it during dialogue.
-- We move it out of UIParent while the dialogue is open, then restore it afterwards.
-- Zygor's waypoint arrow sits outside UIParent, but Zygor's own OnUpdate
-- (Pointer.ArrowFrame_OnUpdate_Common) hides it whenever UIParent isn't visible,
-- so we block that Hide for as long as the dialogue is open.

local _, addon = ...


do
    local ADDON_NAME = nil;     --Folder name differs per flavor (ZygorGuidesViewer, ZygorGuidesViewerForever...)

    local requiredMethods = {
        "ZygorGuidesViewerFrameMaster",
    };

    local function OnAddOnLoaded()
        local CallbackRegistry = addon.CallbackRegistry;
        local GetDBBool = addon.GetDBBool;
        local InCombatLockdown = InCombatLockdown;
        local UIParent = UIParent;
        local ZygorFrame = ZygorGuidesViewerFrameMaster;

        local function DoNothing() end

        local function GetArrowFrame()
            local ZGV = ZygorGuidesViewer;
            return ZGV and ZGV.Pointer and ZGV.Pointer.ArrowFrame    --Recreated when the arrow skin changes
        end

        local FrameUtil = CreateFrame("Frame");

        function FrameUtil:MoveOutOfUIParent()
            if self.frameHandled or InCombatLockdown() then return end;
            self.frameHandled = true;

            --Same rect and scale as UIParent, so Zygor's anchors and its own SetScale keep working
            self:SetScale(UIParent:GetEffectiveScale());
            self:SetAllPoints(UIParent);
            ZygorFrame:SetParent(self);

            local arrow = GetArrowFrame();
            if arrow and arrow:IsShown() then
                self.patchedArrow = arrow;
                arrow.Hide = DoNothing;
            end
        end

        function FrameUtil:RestoreToUIParent()
            if not self.frameHandled then return end;

            if InCombatLockdown() then
                self:RegisterEvent("PLAYER_REGEN_ENABLED");
                return
            end

            self:UnregisterEvent("PLAYER_REGEN_ENABLED");
            self.frameHandled = false;
            ZygorFrame:SetParent(UIParent);

            if self.patchedArrow then
                self.patchedArrow.Hide = nil;   --Back to the widget method
                self.patchedArrow = nil;
            end
        end

        FrameUtil:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_REGEN_ENABLED" then
                self:RestoreToUIParent();
            end
        end);

        local function OnDialogueUIShow()
            if not (GetDBBool("HideUI") and GetDBBool("KeepZygorVisible")) then return end;
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
