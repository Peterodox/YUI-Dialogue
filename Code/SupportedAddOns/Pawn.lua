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
        local tooltip = addon.SharedTooltip;
        local TooltipCapture = addon.TooltipCapture;

        API.IsItemAnUpgrade_External = function(itemLink)
            local result = ShouldShowUpgrade(itemLink, false);
            return result, result ~= nil
        end

        function tooltip:CompareItemExternal(itemLink)
            TooltipCapture:ClearLines();
            if ShouldShowUpgrade(itemLink, false) then
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