local _, addon = ...
local L = addon.L;
local GetFactionStatusText = addon.API.GetFactionStatusText;
local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo;
local GetItemCount = C_Item.GetItemCount;


local function SetupTooltip_Reputation(tooltip, factionID)
    local status, factionName = GetFactionStatusText(factionID);
    if status and factionName then
        tooltip:Hide();
        tooltip:SetOwner(nil, "ANCHOR_NONE");
        tooltip:SetTitle(factionName, 1, 0.82, 0);
        tooltip:AddLine(status);
        return true
    end
end

local function SetupTooltip_Currency(tooltip, currencyID)
    local currencyInfo = GetCurrencyInfo(currencyID);
    if currencyInfo then
        tooltip:Hide();
        tooltip:SetOwner(nil, "ANCHOR_NONE");
        tooltip:SetTitle(currencyInfo.name, 1, 1, 1);
        tooltip:AddLine(L["Format You Have X"]:format(BreakUpLargeNumbers(currencyInfo.quantity)), 1, 0.82, 0);
        return true
    end
end

local function SetupTooltip_Item(tooltip, itemID)
    local name = C_Item.GetItemNameByID(itemID);
    local count = GetItemCount(itemID, true, true, true, true);
    if name then
        tooltip:Hide();
        tooltip:SetOwner(nil, "ANCHOR_NONE");
        tooltip:SetTitle(name, 1, 1, 1);
        tooltip:AddLine(L["Format You Have X"]:format(BreakUpLargeNumbers(count)), 1, 0.82, 0);
        return true
    end
end

local function SetupTooltip_Spell(tooltip, spellID)
    tooltip:Hide();
    tooltip:SetOwner(nil, "ANCHOR_NONE");
    tooltip:SetSpellByID(spellID);
    return true
end


local GossipXReputation = {
    --[gossipOptionID] = factionID

    --Tillers Shrine, Halfhill
    [40080] = 1277,     --Chee Chee
    [40081] = 1275,     --Ella
    [40082] = 1282,     --Fish Fellreed
    [40083] = 1283,     --Farmer Fung
    [40084] = 1281,     --Gina Mudclaw
    [40085] = 1273,     --Jogu the Drunk
    [40086] = 1279,     --Haohan Mudclaw
    [40087] = 1276,     --Old Hillpaw
    [40088] = 1278,     --Sho
    [40089] = 1280,     --Tina Mudclaw

    --Classic (Horde)
    [126050] = 1277,     --Chee Chee
    [126051] = 1275,     --Ella
    [126052] = 1282,     --Fish Fellreed
    [126053] = 1283,     --Farmer Fung
    [126054] = 1281,     --Gina Mudclaw
    [126055] = 1273,     --Jogu the Drunk
    [126056] = 1279,     --Haohan Mudclaw
    [126057] = 1276,     --Old Hillpaw
    [126058] = 1278,     --Sho
    [126059] = 1280,     --Tina Mudclaw
};

local GossipXCurrency = {
    --[gossipOptionID] = currencyID

    --Horrific Vision Revisited
    [132125] = 3149,    --Obtain Echo of N'zoth [500 Displaced Corrupted Mementos]
    [132158] = 3149,    --Obtain Echo of N'zoth [700 Displaced Corrupted Mementos]
    [132176] = 3149,    --Obtain Echo of N'zoth [800 Displaced Corrupted Mementos]
    [132177] = 3149,    --Obtain Echo of N'zoth [Requires 900 Displaced Corrupted Mementos]
    [132179] = 3149,    --Obtain Echo of N'Zoth [Requires 1000 Displaced Corrupted Mementos]
    [132185] = 3149,    --Obtain Echo of N'Zoth [Requires 1100 Displaced Corrupted Mementos]
    [132186] = 3149,    --Obtain Echo of N'Zoth [1100 Displaced Corrupted Mementos]
    [132189] = 3149,    --Obtain Echo of N'Zoth [Requires 1200 Displaced Corrupted Mementos]
};

local GossipXItem = {
    --[gossipOptionID] = itemID

    --Overcharged Delves
    [134233] = 244465,    --Obtain Titan Disc [Requires 100 Titan Disc Shards]
    [134234] = 244465,    --Obtain Titan Disc [100 Titan Disc Shards]
};

local GossipXSpell = {
    --[gossipOptionID] = spellID

    --Klaxxi
    [129585] = 127351,      --Master of Puppets
    [129589] = 127794,      --Children of the Grave
    [129463] = 123211,      --Painkiller
    [129465] = 123219,      --Battle Hymn
    [126276] = 123075,      --Angle of Death
    [126316] = 124529,      --Iron Mantid
    [129824] = 127382,      --Silent Lucidity
};

local DataSource = {};
do
    function DataSource:OnInteractWithNPC(creatureName, creatureID)

    end

    function DataSource:OnInteractStopped()

    end

    function DataSource:SetupTooltipByGossipOptionID(tooltip, gossipOptionID)
        if GossipXReputation[gossipOptionID] then
            return SetupTooltip_Reputation(tooltip, GossipXReputation[gossipOptionID]);
        elseif GossipXCurrency[gossipOptionID] then
            return SetupTooltip_Currency(tooltip, GossipXCurrency[gossipOptionID]);
        elseif GossipXItem[gossipOptionID] then
            return SetupTooltip_Item(tooltip, GossipXItem[gossipOptionID]);
        elseif GossipXSpell[gossipOptionID] then
            return SetupTooltip_Spell(tooltip, GossipXSpell[gossipOptionID]);
        end
    end
end

local GossipDataProvider = addon.GossipDataProvider;
GossipDataProvider:AddDataSource(DataSource);


local function RequestItemNames()
    for _, itemID in pairs(GossipXItem) do
        C_Item.RequestLoadItemDataByID(itemID);
    end
end
addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", RequestItemNames);