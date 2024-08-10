-- Rematch shows a pet preset window when targeting a supported NPC, our Hide UI breaks it
-- We move Rematch window out of UIParent then restore it after interaction.

local _, addon = ...


do
    local ADDON_NAME = "Rematch";

    local requiredMethods = {
        "Rematch.interact.ShouldInteract",
        "Rematch.dialog.HideDialog",
    };

    local function OnAddOnLoaded()
        local rematch = Rematch;
        local interact = rematch.interact;
        local ShouldInteract = interact.ShouldInteract;
        local HideDialog = rematch.dialog.HideDialog;   --Hide Prompt
        local RematchFrame = RematchFrame;

        local securecall = securecall;
        local UnitExists = UnitExists;
        local UnitGUID = UnitGUID;
        local InCombatLockdown = InCombatLockdown;
        local CallbackRegistry = addon.CallbackRegistry;
        local GetCreatureIDFromGUID = addon.API.GetCreatureIDFromGUID;
        local GetDBBool = addon.GetDBBool;

        local function ShouldInteractCurrentNPC()
            if UnitExists("npc") then
                local creatureID = GetCreatureIDFromGUID(UnitGUID("npc"));
                if creatureID then
                    return securecall(ShouldInteract, interact, creatureID)
                end
            end
        end

        local FrameUtil = CreateFrame("Frame");
        FrameUtil:SetFrameStrata("FULLSCREEN_DIALOG");
        FrameUtil:SetFixedFrameStrata(true);

        local function ReAdjustRematchFrame()
            --After clicking "Load" (RematchFrame.LoadedTargetPanel.BigLoadSaveButton) the UI re-parents
            if FrameUtil.frameHandled and FrameUtil.dialogueActive then
                RematchFrame:SetParent(FrameUtil);
                RematchFrame:SetScale(UIParent:GetEffectiveScale());
                RematchFrame:SetFrameStrata("FULLSCREEN_DIALOG");
            end
        end

        function FrameUtil:AdjustRematchWindow(dialogType)
            if self.frameHandled then return end;
            self.frameHandled = true;

            local f;

            if dialogType == 1 then --Prompt to Load
                f = rematch.dialog;
                self.defaultScale = f:GetScale();
                f:SetParent(self);
            elseif dialogType == 2 then --Show Window
                f = RematchFrame;
                self.defaultScale = f:GetScale();
                ReAdjustRematchFrame();

                if not self.configureHooked then
                    self.configureHooked = true;
                    hooksecurefunc(rematch.frame, "Configure", ReAdjustRematchFrame);   --Perhaps not the best way to do it
                end
            end

            if f then
                f:SetScale(UIParent:GetEffectiveScale());
            end

            if self.modifiedWindow then
                self:RestoreWindow(self.modifiedWindow);
            end

            self.modifiedWindow = f;
        end

        function FrameUtil:RestoreWindow(f)
            f:SetParent(UIParent);
            f:SetScale(self.defaultScale or 1);
        end

        function FrameUtil:RestoreRematch()
            if self.frameHandled then
                self.frameHandled = false;
                securecall(HideDialog);
                if RematchFrame and RematchFrame:IsShown() then
                    RematchFrame:Hide();
                end
                if self.modifiedWindow then
                    self:RestoreWindow(self.modifiedWindow);
                    self.modifiedWindow = nil;
                end
            end
        end

        local function OnDialogueUIShow()
            --INTERACT_NONE
            if InCombatLockdown() or (not GetDBBool("HideUI")) then return end;

            FrameUtil.dialogueActive = true;

            local settings = rematch.settings;
            if settings and (settings.InteractOnTarget == 1 or settings.InteractOnTarget == 2 or settings.InteractOnSoftInteract == 1 or settings.InteractOnSoftInteract == 2) then   --settings.InteractOnMouseover
                if ShouldInteractCurrentNPC() then
                    FrameUtil:AdjustRematchWindow(settings.InteractOnTarget);
                else
                    FrameUtil:RestoreRematch();
                end
            else
                FrameUtil:RestoreRematch();
            end
        end
        CallbackRegistry:Register("DialogueUI.Show", OnDialogueUIShow);

        local function OnDialogueUIHide()
            FrameUtil.dialogueActive = false;
            FrameUtil:RestoreRematch();
        end
        CallbackRegistry:Register("DialogueUI.Hide", OnDialogueUIHide);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end