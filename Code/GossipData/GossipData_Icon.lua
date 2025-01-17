local _, addon = ...
local GossipDataProvider = addon.GossipDataProvider;
local L = addon.L;

local ICON_PATH = "Interface/AddOns/DialogueUI/Art/Icons/";

local GossipIcon = {
    --[gossipOptionID/name] = icon
    ["Gossip Red"] = ICON_PATH.."Gossip-Red.png",       --<Skip Chaptor>
    ["Gossip Quest"] = ICON_PATH.."Gossip-Quest.png",   --(Quest) flags == 1
    [132053] = ICON_PATH.."Gossip.png",
    [132058] = ICON_PATH.."Trainer.png",                --Trainer
    [132060] = ICON_PATH.."Buy.png",                    --Merchant
    [1019848] = ICON_PATH.."Gossip.png",                --Tavio in Iskaara (likely meant to use Fishing icon)
    [1673939] = "interface/minimap/tracking/transmogrifier.blp",
    [1130518] = "interface/cursor/crosshair/workorders.blp",                            --Work Orders (Class Hall)
    [132050] = "interface/minimap/tracking/banker.blp",


    --Ask guard for directions
    ["Inn"] = ICON_PATH.."Innkeeper.png",
    [L["Pin Inn"]] = ICON_PATH.."Innkeeper.png",
    [L["Pin Profession Trainer"]] = ICON_PATH.."Mine.png",
    [L["Pin Class Trainer"]] = ICON_PATH.."Trainer.png",
    [L["Pin Stable Master"]] = ICON_PATH.."Stablemaster.png",
    [L["Pin Trading Post"]] = ICON_PATH.."TradingPost.png",
    [L["Pin Battle Pet Trainer"]] = ICON_PATH.."BattlePet.png",
    [L["Pin Transmogrification"]] = "interface/minimap/tracking/transmogrifier.blp",
    [L["Pin Transmogrifier"]] = "interface/minimap/tracking/transmogrifier.blp",
    [L["Pin Void Storage"]] = "interface/cursor/crosshair/voidstorage.blp",
    [L["Pin Auction House"]] = "interface/minimap/tracking/auctioneer.blp",
    [L["Pin Bank"]] = "interface/minimap/tracking/banker.blp",
    [L["Pin Barber"]] = "interface/minimap/tracking/barbershop.blp",
    [L["Pin Flight Master"]] = "interface/minimap/tracking/flightmaster.blp",
    [L["Pin Mailbox"]] = "interface/minimap/tracking/mailbox.blp",
    [L["Pin Vendor"]] = "interface/cursor/crosshair/buy.blp",
    --["Points of Interest"] = "",
    --["Other Continents"] = "Interface/AddOns/DialogueUI/Art/Icons/Continent.png",


    --Queue Dungeon Finder
    ["LFG"] = ICON_PATH.."LFG.png",
};
GossipIcon[132052] = GossipIcon["Inn"];


local GossipOptionIDXIcon = {};
do
    local ids = {
        122968,     --Count me in! <Queue for The Codex of Chromie.>
        124977,     --Send me into the Blackrock Depths. (Heroic Raid)
        124978,     --Send me into the Blackrock Depths. (Normal Raid)
    };
    for _, id in ipairs(ids) do
        GossipOptionIDXIcon[id] = GossipIcon["LFG"];
    end
    ids = nil;
end

function GossipDataProvider:GetGossipIcon(oldIconFile, name, gossipOptionID)
    if name and GossipIcon[name] then
        return GossipIcon[name]
    end

    if gossipOptionID and GossipOptionIDXIcon[gossipOptionID] then
        return GossipOptionIDXIcon[gossipOptionID]
    end

    if not oldIconFile then
        oldIconFile = 132053;
    end

    if GossipIcon[oldIconFile] then
        return GossipIcon[oldIconFile]
    end

    return oldIconFile
end