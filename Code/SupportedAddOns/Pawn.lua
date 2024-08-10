-- Pawn Upgrade Arrow
local _, addon = ...


do
    local ADDON_NAME = "Pawn";

    local requiredMethods = {
        "PawnShouldItemLinkHaveUpgradeArrow";
    };

    local function OnAddOnLoaded()
        local shouldShowUpgrade = PawnShouldItemLinkHaveUpgradeArrow;

        local tooltip = addon.SharedTooltip;
        local ICON = "Interface/AddOns/DialogueUI/Art/Icons/UpgradeArrow.png";
        local TEXT = addon.L["Item Is An Upgrade"];

        function tooltip:ProcessItemExternal(item)
            if shouldShowUpgrade(item, true) then
                self:AddBlankLine();
                local size = nil;   --follow font size
                self:AddSimpleIconText(ICON, size, TEXT, 0, 1, 0, true);
            end
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end