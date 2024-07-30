-- Let InteractiveWormholes handle gossip options when needed
local _, addon = ...


do
    local ADDON_NAME = "InteractiveWormholes";


    local function OnAddOnLoaded()
        if not (InteractiveWormholes and InteractiveWormholes.IsActive) then return end;

        local MainFrame = addon.DialogueUI;
        local API = InteractiveWormholes;

        MainFrame.IsGossipHandledExternally = function()
            return API:IsActive()
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end