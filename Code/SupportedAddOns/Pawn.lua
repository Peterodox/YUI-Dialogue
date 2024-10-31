-- Pawn Upgrade Arrow
local _, addon = ...


do
    local ADDON_NAME = "Pawn";

    local requiredMethods = {
        "PawnIsItemAnUpgrade";
        "PawnAddValuesToTooltip",
    };

    local function OnAddOnLoaded()
        local ShouldShowUpgrade = PawnShouldItemLinkHaveUpgradeArrow;
        local AddValuesToTooltip = PawnAddValuesToTooltip;
        local tooltip = addon.SharedTooltip;
        local TooltipCapture = addon.TooltipCapture;

        function tooltip:ProcessItemExternal(itemLink)
            TooltipCapture:ClearLines();
            if ShouldShowUpgrade(itemLink, true) then
                local Item = PawnGetItemData(itemLink)
                if Item then
                    self:AddBlankLine();
                    local UpgradeInfo, ItemLevelIncrease, BestItemFor, SecondBestItemFor, NeedsEnhancements = PawnIsItemAnUpgrade(Item);
                    AddValuesToTooltip(TooltipCapture, Item.Values, UpgradeInfo, BestItemFor, SecondBestItemFor, NeedsEnhancements, Item.InvType);
                    TooltipCapture:SendToProcess(self);
                end
            end
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end