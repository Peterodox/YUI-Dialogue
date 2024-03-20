local _, addon = ...
local TooltipFrame = addon.SharedTooltip;

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
    local npcName = UnitName("npc");
    if npcName then
        for i, source in ipairs(self.sources) do
            source:OnInteractWithNPC(npcName);
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
        hasTooltip = source:SetupTooltipByGossipOptionID(TooltipFrame, gossipOptionID);
        if hasTooltip then
            break
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


--[[
local DataSource = {};

function DataSource:OnInteractWithNPC(npcName)

end

function DataSource:OnInteractStopped()

end

function DataSource:SetupTooltipByGossipOptionID(gossipOptionID)

end

--]]