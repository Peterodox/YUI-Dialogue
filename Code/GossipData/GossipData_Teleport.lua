-- Disable hotkey control when detecting teleportation gossips
-- (teleport to another continent where returning isn't as easy)
-- We use the NPC's ID to determine if teleport is available

local _, addon = ...
local L = addon.L;
local API = addon.API;
local GossipDataProvider = addon.GossipDataProvider;

local IsTeleportNPC = {
    --[creatureID] = true,

    [231541] = true,        --Sky-Captain Cableclamp (Siren Isle to Dornogal)
    [475936] = true,        --Mole Machine Transport (Siren Isle to Gundargaz)
    [125433] = true,        --Carli Joyride, <Board the drill to the Ringing Deeps.>

    --Wormhole
    [35646] = true,         --Northrend
    [81205] = true,         --Draenor
    [101462] = true,        --Reaves
    [169501] = true,        --Shadowlands Wormhole
    [195667] = true,        --Wyrmhole
    [223342] = true,        --Khaz Algar Wormhole

    --LFR
    [111246] = true,        --Archmage Timear
    [205959] = true,        --Shadowlands
    [177208] = true,        --BFA
    [177193] = true,        --BFA
    [94870] = true,         --WoD
    [80633] = true,         --MoP
    [78709] = true,         --MoP Scenario
    [78777] = true,         --MoP Scenario
    [80675] = true,         --CTM

    [143925] = true,        --[Vehicle] Dark Iron Mole Machine
    [151566] = true,        --Oculus of Transportation (Silas's Stone of Transportation)

    [105490] = true,        --Vethir
    [90907] = true,         --Vethir
    [108685] = true,        --Vethir

    [121602] = true,        --Manapoof
    [147666] = true,        --Manapoof
    [147642] = true,        --Manapoof

    [135681] = true,        --Grand Admiral Jes-Tereth
    [135690] = true,        --Dread-Admiral Tattersail

    [172925] = true,        --Animaflow Teleporter
    [177246] = true,        --Animaflow Teleporter
    [178085] = true,        --Animaflow Teleporter
    [178119] = true,        --Animaflow Teleporter
    [178823] = true,        --Animaflow Teleporter
    [179129] = true,        --Animaflow Teleporter

    [116662] = true,        --Suramar Portal (Nighthold)
    [116667] = true,        --Suramar Portal (Nighthold)
    [116670] = true,        --Suramar Portal (Nighthold)
    [116819] = true,        --Suramar Portal (Nighthold)
    [116820] = true,        --Suramar Portal (Nighthold)

    [125720] = true,        --Lightforged Beacon (Antorus) First
    [128303] = true,        --Lightforged Beacon (Antorus) Exhaust (Moved to Kin'garoth after defeat)
    [128304] = true,        --Lightforged Beacon (Antorus) Burning Throne Entrance (Can move to Argus)
    [129876] = true,        --Grand Artificer Romuul (Antorus) After Argus

    [194569] = true,        --Ulduar Teleporter
};

do
    local DataSource = {};

    function DataSource:OnInteractWithNPC(npcName, creatureID)
        if IsTeleportNPC[creatureID] then
            GossipDataProvider:SetEnableGossipHotkey(false);
            --addon.KeyboardControl:DisableGossipHotkeys();
        end
    end

    function DataSource:OnInteractStopped()

    end

    GossipDataProvider:AddDataSource(DataSource);
end


--[[
do  --Unused
    local IsTeleportGossip = {};

    local TeleportGossip = {
        ---- TWW ----
        122358,     --Azj-Kahet
        122359,     --Hallowfall
        122360,     --Ringing Deeps
        122361,     --Isle of Dorn
        122362,     --Carelessly leap into the portal, you daredevil

        ---- DF ----
        63907,      --Carelessly leap into the portal, you daredevil

        ---- SL ----
        51934,      --Oribos, The Eternal City
        51935,      --Bastion, Home of the Kyrian
        51936,      --Maldraxxus, Citadel of the Necrolords
        51937,      --Ardenweald, Forest of the Night Fae
        51938,      --Revendreth, Court of the Venthyr
        51939,      --The Maw, Wasteland of the Damned
        51941,      --Korthia, City of Secrets
        51942,      --Zereth Mortis, Enlightened Haven

        ---- BFA ----
        -- War Campaign
        48169,      --Vol'dun
        48170,      --Nazmir
        48171,      --Zuldazar
        48348,      --Drustvar
        48349,      --Stormsong Valley
        48350,      --Tiragarde Sound

        ---- LEG ----
        46325,      --Azsuna
        46326,      --Val'sharah
        46327,      --Highmountain
        46328,      --Stormheim
        46329,      --Suramar

        ---- Wrath ----
        38054,      --Borean Tundra
        38055,      --Howling Fjord
        38056,      --Sholozar Basin
        38057,      --Icecrown
        38058,      --Storm Peaks
        38059,      --Underground
    };


    do
        local DraenorWormhole = {
            --[gossipOptionID] = areaID
            [42586] = 6722,     --"A jagged landscape" Spires of Arak
            [42587] = 6662,     --"A reddish-orange forest" Talador
            [42588] = 6719,     --"Shadows..." Shadowmoon Valley
            [42589] = 6755,     --"Grassy plains" Nagrand
            [42590] = 6721,     --"Primal forest" Gorgrond
            [42591] = 6720,     --"Lava and snow" Frostfire Ridge
        };

        local Wyrmhole = {
            [63908] = 13647,    --Thaldraszus
            [63909] = 13646,    --Azure Span
            [63910] = 13645,    --Ohn'ahran Plains
            [63911] = 13644,    --Waking Shores
            [108016] = 14433,   --Forbidden Reach
            [109715] = 14022,   --Zaralek Cavern
            [114080] = 14529,   --Emerald Dream
        };

        local function ConvertData(zoneTable)
            for gossipOptionID, areaID in pairs(zoneTable) do
                IsTeleportGossip[gossipOptionID] = true;
                GossipDataProvider:SetOverrideName(gossipOptionID, API.GetZoneName(areaID));
            end
        end

        ConvertData(DraenorWormhole);
        ConvertData(Wyrmhole);

        DraenorWormhole = nil;
        Wyrmhole = nil;
    end

    do
        for _, gossipOptionID in ipairs(TeleportGossip) do
            IsTeleportGossip[gossipOptionID] = true;
        end

        TeleportGossip = nil;
    end
end
--]]