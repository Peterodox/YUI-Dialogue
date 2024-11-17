local _, addon = ...

local TooltipFrame;

local PSEUDO_NAME = "DialogueUISecondaryTooltip";

local function ObjectGetter()
    if not TooltipFrame then
        TooltipFrame = addon.CreateTooltipBase();

        function TooltipFrame:GetOwner()

        end

        if TooltipFrame.Init then
            TooltipFrame:Init();
        end

        function TooltipFrame:GetName()
            return PSEUDO_NAME
        end

        TooltipFrame:SetMaxTextWidth(360);
    end

    return TooltipFrame
end
addon.AddSupportedPublicCallback("TooltipSetHyperLink", ObjectGetter);