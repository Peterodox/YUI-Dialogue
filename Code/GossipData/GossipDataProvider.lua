local _, addon = ...
local TooltipFrame = addon.SharedTooltip;
local GetCurrentNPCInfo = addon.API.GetCurrentNPCInfo;

local ipairs = ipairs;
local UnitName = UnitName;

local DataProvider = {};
addon.GossipDataProvider = DataProvider;

DataProvider.sources = {};
DataProvider.alternativeNames = {}; --Change gossip option's name (e.g. LFR wing names)

function DataProvider:AddDataSource(dataSource)
    table.insert(self.sources, dataSource)
end

function DataProvider:OnInteractWithNPC()
    self:SetEnableGossipHotkey(true);

    local creatureName, creatureID = GetCurrentNPCInfo();
    if creatureName then
        for i, source in ipairs(self.sources) do
            source:OnInteractWithNPC(creatureName, creatureID);
        end
    end
end

function DataProvider:OnInteractStopped()
    for i, source in ipairs(self.sources) do
        source:OnInteractStopped();
    end
end

function DataProvider:SetupTooltipByGossipOptionID(gossipOptionID)
    local hasTooltip = false;

    for i, source in ipairs(self.sources) do
        if source.SetupTooltipByGossipOptionID then
            hasTooltip = source:SetupTooltipByGossipOptionID(TooltipFrame, gossipOptionID);
            if hasTooltip then
                break
            end
        end
    end

    return hasTooltip
end

function DataProvider:SetOverrideName(gossipOptionID, name)
    if name then
        self.alternativeNames[gossipOptionID] = name;
    end
end

function DataProvider:GetOverrideName(gossipOptionID)
    return self.alternativeNames[gossipOptionID]
end

function DataProvider:SetEnableGossipHotkey(state)
    self.enableGossipHotkey = state;
end

function DataProvider:IsGossipHotkeyEnabled()
    return self.enableGossipHotkey ~= false
end

--[[
local DataSource = {};

function DataSource:OnInteractWithNPC(creatureName, creatureID)

end

function DataSource:OnInteractStopped()

end

function DataSource:SetupTooltipByGossipOptionID(tooltip, gossipOptionID)

end
--]]