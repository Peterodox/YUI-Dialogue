-- Let InteractiveWormholes handle gossip options when needed
local _, addon = ...


do
    local ADDON_NAME = "InteractiveWormholes";

    local requiredMethods = {
        "InteractiveWormholes.IsActive",
    };

    local function OnAddOnLoaded()
        local MainFrame = addon.DialogueUI;
        local API = InteractiveWormholes;

        MainFrame.IsGossipHandledExternally = function()
            return API:IsActive()
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end