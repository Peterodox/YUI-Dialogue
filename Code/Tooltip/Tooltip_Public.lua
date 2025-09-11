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



local ItemLinkProcessor = {};
do
    local pairs = pairs;

    local function Tooltip_OnSetItem(tooltip, itemID, itemLink)
        local anyChange;
        for processor in pairs(ItemLinkProcessor) do
            if processor(tooltip, itemID, itemLink) then
                anyChange = true;
            end
        end
        if anyChange then
            tooltip:Show();
        end
    end

    local CALLBACK_ADDED = false;

    local function AddItemTooltipProcessorExternal(processor)
        if not CALLBACK_ADDED then
            CALLBACK_ADDED = true;
            addon.CallbackRegistry:Register("SharedTooltip.SetItem", Tooltip_OnSetItem);
        end
        ItemLinkProcessor[processor] = true;
    end

    DialogueUIAPI.AddItemTooltipProcessorExternal = AddItemTooltipProcessorExternal;
end