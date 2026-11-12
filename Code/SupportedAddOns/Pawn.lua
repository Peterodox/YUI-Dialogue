-- Pawn Upgrade Arrow
local _, addon = ...
local API = addon.API;


do
    local ADDON_NAME = "Pawn";

    local requiredMethods = {
        "PawnIsItemAnUpgrade";
        "PawnAddValuesToTooltip",
        "PawnGetItemData",
    };

    local function OnAddOnLoaded()
        local ShouldShowUpgrade = PawnShouldItemLinkHaveUpgradeArrow;   --2nd arg: CheckLevel
        local AddValuesToTooltip = PawnAddValuesToTooltip;
        local TooltipCapture = addon.TooltipCapture;

        local function isItemUpgrade(itemLink)
            local isUpgrade = ShouldShowUpgrade(itemLink, false);
            local isDataReady = isUpgrade ~= nil;
            return isUpgrade, isDataReady;
        end

        local function tooltipWritter(tooltipCapture, itemLink)
            if ShouldShowUpgrade(itemLink, false) then
                local Item = PawnGetItemData(itemLink)
                if Item then
                    local UpgradeInfo, ItemLevelIncrease, BestItemFor, SecondBestItemFor, NeedsEnhancements = PawnIsItemAnUpgrade(Item);
                    AddValuesToTooltip(TooltipCapture, Item.Values, UpgradeInfo, BestItemFor, SecondBestItemFor, NeedsEnhancements, Item.InvType);
                    return true;
                end
            end
        end

        addon.ItemEvaluator:AddThirdPartyEvaluator(ADDON_NAME, isItemUpgrade, tooltipWritter);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end
