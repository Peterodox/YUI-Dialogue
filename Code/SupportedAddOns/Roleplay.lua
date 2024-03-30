-- (Optional) Replace player name with RP name

local _, addon = ...


do
    local ADDON_NAME = "TotalRP3";

    local function OnAddOnLoaded()
        --print(ADDON_NAME, "LOADED");
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end


do
    local ADDON_NAME = "XRP";

    local function OnAddOnLoaded()
        --print(ADDON_NAME, "LOADED");
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end