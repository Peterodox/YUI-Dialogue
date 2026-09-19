local _, addon = ...
local GossipDataProvider = addon.GossipDataProvider;


local OverrideOrder = {
    --Change the order of certain gossipOptions so player can proceed by pressing Space.
    --Smaller number means front
    --[gossipOptionID] = number,

    --Delve-O-Bot 7001
    [140192] = 8,   --Take me to a Midnight delve please.
    [140193] = 9,   --Take me to a Khaz Algar delve please.
};


function GossipDataProvider:GetOverrideOrder(gossipOptionID)
    return gossipOptionID and OverrideOrder[gossipOptionID];
end
