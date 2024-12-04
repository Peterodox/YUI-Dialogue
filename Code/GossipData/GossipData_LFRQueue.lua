if not (C_RaidLocks and C_LFGInfo and EJ_GetEncounterInfo) then return end;

local _, addon = ...
if not addon.IsToCVersionEqualOrNewerThan(100000) then return end;

local IsEncounterComplete = C_RaidLocks.IsEncounterComplete;        --RequestRaidInfo(), UPDATE_INSTANCE_INFO
local GetDungeonInfo = C_LFGInfo.GetDungeonInfo;
local EJ_GetEncounterInfo = EJ_GetEncounterInfo;
local GetDungeonDifficultyID = GetDungeonDifficultyID;
local GetRaidDifficultyID = GetRaidDifficultyID;

local LFRGossipOptions = {};
local InstanceTeleporterOptions = {};
local DataSource = {};

local Locale = {};
Locale.BOSS_DEAD = BOSS_DEAD;
Locale.BOSS_ALIVE = BOSS_ALIVE;
Locale.Red = RED_FONT_COLOR;
Locale.Green = GREEN_FONT_COLOR;

function DataSource:OnInteractWithNPC(npcName)

end

function DataSource:OnInteractStopped()

end

function DataSource:IsSupportedOption(gossipOptionID)
    return gossipOptionID and LFRGossipOptions[gossipOptionID] ~= nil
end

function DataSource:SetupTooltipByGossipOptionID(tooltip, gossipOptionID)
    local data = LFRGossipOptions[gossipOptionID];
    if data then
        tooltip:Hide();
        tooltip:SetOwner(nil, "ANCHOR_NONE");

        local dungeonID = data[1];
        local mapID = data[2];
        local difficultyID = data[3];
        local journalEncounteID, encounterID, bossName;
        local dungeonInfo = GetDungeonInfo(dungeonID);
        local dungeonName = dungeonInfo and dungeonInfo.name;

        if not dungeonName then
            return false
        end

        local info = {};
        local index = 0;
        info.dungeonName = dungeonName;
        info.encounters = {};

        for i = 4, #data do
            index = index + 1;
            journalEncounteID = data[i][1];
            encounterID = data[i][2];
            bossName = EJ_GetEncounterInfo(journalEncounteID);
            info.encounters[index] = {
                bossName = bossName,
                mapID = mapID,
                encounterID = encounterID,
                difficultyID = difficultyID,
            };
        end

        local noRequestFromServer = false;
        tooltip:DisplayRaidLocks(info, noRequestFromServer);

        return true
    end

    data = InstanceTeleporterOptions[gossipOptionID];
    if data then
        tooltip:Hide();
        tooltip:SetOwner(nil, "ANCHOR_NONE");

        local bossName, journalEncounteID, mapID, encounterID;
        local difficultyID = GetRaidDifficultyID();

        local info = {};
        info.encounters = {};

        for i, v in ipairs(data) do
            mapID = v[1];
            journalEncounteID = v[2];
            encounterID = v[3];
            bossName = EJ_GetEncounterInfo(journalEncounteID);
            info.encounters[i] = {
                bossName = bossName,
                mapID = mapID,
                encounterID = encounterID,
                difficultyID = difficultyID,
            };
        end

        tooltip:DisplayRaidLocks(info);

        return true
    end
end


do  --Legacy Raid (LFR) show boss name and status in this wing
    --See https://wago.tools/db2/LFGDungeons
    --C_LFGInfo.GetDungeonInfo: icon, name, JournalLink
    --C_RaidLocks.IsEncounterComplete(mapID, dungeonEncounterID, difficultyID)

    local DIFFICULTY_LFR = 17;  --difficultyID of old raids is different  EJ_GetDifficulty


    LFRGossipOptions = {
        --[gossipOptionID] = {dungeonID, mapID, difficultyID, {journalEncounteID1, dungeonEncounterID1}, {journalEncounteID2, dungeonEncounterID2}, ...}

        --Shadowlands (npc: 205959)
        [110020] = {2090, 2296, DIFFICULTY_LFR, {2429, 2418}, {2428, 2383}, {2420, 2406}},      --The Leeching Vaults
        [110037] = {2091, 2296, DIFFICULTY_LFR, {2422, 2402}, {2418, 2405}, {2426, 2412}},      --Reliquary of Opulence
        [110036] = {2092, 2296, DIFFICULTY_LFR, {2393, 2398}, {2394, 2399}, {2425, 2417}},      --Blood from Stone
        [110035] = {2096, 2296, DIFFICULTY_LFR, {2424, 2407}},      --An Audience with Arrogance

        [110034] = {2221, 2450, DIFFICULTY_LFR, {2435, 2423}, {2442, 2433}, {2439, 2429}},      --The Jailer's Vanguard
        [110033] = {2222, 2450, DIFFICULTY_LFR, {2445, 2434}, {2444, 2432}, {2443, 2430}},      --The Dark Bastille
        [110032] = {2223, 2450, DIFFICULTY_LFR, {2446, 2436}, {2447, 2431}, {2440, 2422}},      --Shackles of Fate
        [110031] = {2224, 2450, DIFFICULTY_LFR, {2441, 2435}},      --The Reckoning

        [110030] = {2291, 2481, DIFFICULTY_LFR, {2459, 2540}, {2460, 2544}, {2461, 2539}},      --Cornerstone of Creation
        [110029] = {2292, 2481, DIFFICULTY_LFR, {2458, 2512}, {2465, 2542}, {2470, 2553}, {2463, 2529}},    --Ephemeral Plains
        [110028] = {2293, 2481, DIFFICULTY_LFR, {2469, 2546}, {2457, 2543}, {2467, 2549}},      --Domination's Grasp
        [110027] = {2294, 2481, DIFFICULTY_LFR, {2464, 2537}},      --The Grand Design

        --BFA (npc: 177208(Horde))
        [52303] = {1731, 1861, DIFFICULTY_LFR, {2168, 2144}, {2167, 2141}, {2169, 2136}},     --Halls of Containment
        [52304] = {1732, 1861, DIFFICULTY_LFR, {2146, 2128}, {2166, 2134}, {2195, 2145}},     --Crimson Descent
        [52305] = {1733, 1861, DIFFICULTY_LFR, {2194, 2135}, {2147, 2122}},                   --Heart of Corruption

        --Battle of Dazar'alor name varies based on player faction
        [52306] = {1948, 2070, DIFFICULTY_LFR, {2333, 2265}, {2325, 2263}, {2323, 2285}};     --Defense of Dazar'alor
        [52307] = {1949, 2070, DIFFICULTY_LFR, {2342, 2271}, {2330, 2268}, {2335, 2272}};     --Death's Bargain
        [52308] = {1950, 2070, DIFFICULTY_LFR, {2334, 2276}, {2337, 2280}, {2343, 2281}};     --Victory or Death

        [52309] = {1945, 2070, DIFFICULTY_LFR, {2344, 2265}, {2341, 2266}, {2340, 2284}},     --Siege of Dazar'alor
        [52310] = {1946, 2070, DIFFICULTY_LFR, {2342, 2271}, {2330, 2268}, {2335, 2272}},     --Empire's Fall
        [52311] = {1947, 2070, DIFFICULTY_LFR, {2334, 2276}, {2337, 2280}, {2343, 2281}},     --Might of the Alliance

        [52312] = {1951, 2096, DIFFICULTY_LFR, {2328, 2269}, {2332, 2273}},                   --Crucible of Storms

        [52313] = {2009, 2164, DIFFICULTY_LFR, {2352, 2298}, {2347, 2289}, {2353, 2305}},     --The Grand Reception
        [52314] = {2010, 2164, DIFFICULTY_LFR, {2354, 2304}, {2351, 2303}, {2359, 2311}},     --Depths of the Devoted
        [52315] = {2011, 2164, DIFFICULTY_LFR, {2349, 2293}, {2361, 2299}},                   --The Circle of Stars

        [52316] = {2036, 2217, DIFFICULTY_LFR, {2368, 2329}, {2365, 2327}, {2369, 2334}},     --Vision of Destiny
        [52317] = {2037, 2217, DIFFICULTY_LFR, {2377, 2328}, {2370, 2336}, {2372, 2333}, {2364, 2331}},     --Halls of Devotion
        [52318] = {2038, 2217, DIFFICULTY_LFR, {2367, 2335}, {2373, 2343}, {2374, 2345}},     --Gift of Flesh
        [52319] = {2039, 2217, DIFFICULTY_LFR, {2366, 2337}, {2375, 2344}},                   --The Waking Dream (Requires Cloack)


        --Legion
        [37110] = {1287, 1520, DIFFICULTY_LFR, {1703, 1853}, {1744, 1876}, {1738, 1873}},     --Darkbough
        [37111] = {1288, 1520, DIFFICULTY_LFR, {1667, 1841}, {1704, 1854}, {1750, 1877}},     --Tormented Guardians
        [37112] = {1289, 1520, DIFFICULTY_LFR, {1726, 1864}},                                 --Rift of Aln

        [37113] = {1290, 1530, DIFFICULTY_LFR, {1706, 1849}, {1725, 1865}, {1731, 1867}},     --Arcing Aqueducts
        [37114] = {1291, 1530, DIFFICULTY_LFR, {1751, 1871}, {1732, 1863}, {1761, 1886}},     --Royal Athenaeum
        [37115] = {1292, 1530, DIFFICULTY_LFR, {1713, 1842}, {1762, 1862}, {1743, 1872}},     --Nightspire
        [37116] = {1293, 1530, DIFFICULTY_LFR, {1737, 1866}},                                 --Gul'dan

        [37117] = {1411, 1648, DIFFICULTY_LFR, {1819, 1958}, {1830, 1962}, {1829, 2008}},     --Trial of Valor

        [37118] = {1494, 1676, DIFFICULTY_LFR, {1862, 2032}, {1856, 2036}, {1861, 2037}},     --The Gates of Hell
        [37119] = {1495, 1676, DIFFICULTY_LFR, {1867, 2048}, {1903, 2050}, {1896, 2054}},     --Wailing Halls
        [37120] = {1496, 1676, DIFFICULTY_LFR, {1897, 2052}, {1873, 2038}},                   --Chamber of the Avatar
        [37121] = {1497, 1676, DIFFICULTY_LFR, {1898, 2051}},                                 --Deceiver's Fall

        [37122] = {1610, 1712, DIFFICULTY_LFR, {1992, 2076}, {1987, 2074}, {1997, 2070}},     --Light's Breach
        [37123] = {1611, 1712, DIFFICULTY_LFR, {1985, 2064}, {2025, 2075}, {2009, 2082}},     --Forbidden Descent
        [37124] = {1612, 1712, DIFFICULTY_LFR, {2004, 2088}, {1983, 2069}, {1986, 2073}},     --Hope's End
        [37125] = {1613, 1712, DIFFICULTY_LFR, {1984, 2063}, {2031, 2092}},                   --Seat of the Pantheon


        --Wod (npc: 94870)
        [44390] = {849, 1228, DIFFICULTY_LFR, {1128, 1721}, {971, 1706}, {1196, 1720}},       --Walled City
        [44391] = {850, 1228, DIFFICULTY_LFR, {1195, 1722}, {1148, 1719}, {1153, 1723}},      --Arcane Sanctum
        [44392] = {851, 1228, DIFFICULTY_LFR, {1197, 1705}},     --Imperator's Rise

        [44393] = {847, 1205, DIFFICULTY_LFR, {1161, 1691}, {1202, 1696}, {1154, 1690}},      --Slagworks
        [44394] = {846, 1205, DIFFICULTY_LFR, {1155, 1693}, {1123, 1689}, {1162, 1713}},      --The Black Forge
        [44395] = {848, 1205, DIFFICULTY_LFR, {1122, 1694}, {1147, 1692}, {1203, 1695}},      --Iron Assembly
        [44396] = {823, 1205, DIFFICULTY_LFR, {959, 1704}},      --Blackhand's Crucible

        [44397] = {982, 1448, DIFFICULTY_LFR, {1426, 1778}, {1425, 1785}, {1392, 1787}},      --Hellbreach
        [44398] = {983, 1448, DIFFICULTY_LFR, {1396, 1786}, {1432, 1798}, {1372, 1783}},      --Halls of Blood
        [44399] = {984, 1448, DIFFICULTY_LFR, {1433, 1788}, {1427, 1794}, {1394, 1784}},      --Bastion of Shadows
        [44400] = {985, 1448, DIFFICULTY_LFR, {1391, 1777}, {1447, 1800}, {1395, 1795}},      --Destructor's Rise
        [44401] = {986, 1448, DIFFICULTY_LFR, {1438, 1799}},      --The Black Gate


        --MoP (npc: 80633)
        [42620] = {527, 1008, 7, {679, 1395}, {689, 1390}, {682, 1434}},     --Guardians of Mogu'shan
        [42621] = {528, 1008, 7, {687, 1436}, {726, 1500}, {677, 1407}},     --The Vault of Mysteries

        [42622] = {529, 1009, 7, {745, 1507}, {744, 1504}, {713, 1463}},     --The Dread Approach
        [42623] = {530, 1009, 7, {741, 1498}, {737, 1499}, {743, 1501}},     --Nightmare of Shek'zeer

        [42624] = {526, 996, 7, {683, 1409}, {742, 1505}, {729, 1506}, {709, 1431}},    --Terrace of Endless Spring

        [42625] = {610, 1098, 7, {827, 1577}, {819, 1575}, {816, 1570}},     --Last Stand of the Zandalari
        [42626] = {611, 1098, 7, {825, 1565}, {821, 1578}, {828, 1573}},     --Forgotten Depths
        [42627] = {612, 1098, 7, {818, 1572}, {820, 1574}, {824, 1576}},     --Halls of Flesh-Shaping
        [42628] = {613, 1098, 7, {817, 1559}, {829, 1560}, {832, 1579}},     --Pinnacle of Storms

        [42629] = {716, 1136, DIFFICULTY_LFR, {852, 1602}, {849, 1598}, {866, 1624}, {867, 1604}},     --Vale of Eternal Sorrows
        [42630] = {717, 1136, DIFFICULTY_LFR, {868, 1622}, {864, 1600}, {856, 1606}, {850, 1603}},     --Gates of Retribution
        [42631] = {724, 1136, DIFFICULTY_LFR, {846, 1595}, {870, 1594}, {851, 1599}},     --The Underhold
        [42632] = {725, 1136, DIFFICULTY_LFR, {865, 1601}, {853, 1593}, {869, 1623}},     --Downfall


        --CTM (npc: 80675, Caverns of Time)
        [42612] = {416, 967, 7, {311, 1292}, {324, 1294}, {325, 1295}, {317, 1296}},     --The Siege of Wyrmrest Temple
        [42613] = {417, 967, 7, {331, 1297}, {332, 1298}, {318, 1291}, {333, 1299}},     --Fall of Deathwing
    };


    local GossipDataProvider = addon.GossipDataProvider;
    GossipDataProvider:AddDataSource(DataSource);

    local dungeonInfo, dungeonName;

    for gossipOptionID, data in pairs(LFRGossipOptions) do
        dungeonInfo = GetDungeonInfo(data[1]);
        dungeonName = dungeonInfo and dungeonInfo.name;
        GossipDataProvider:SetOverrideName(gossipOptionID, dungeonName);
    end
end


do  --Instance Teleporter Option Tooltip
    local Data = {
        -- (d)ata  = { {mapID, journalEncounteID, dungeonEncounterID}, }
        -- (o)nwer = { gossipOptionID1, gossipOptionID2, ... }
    };

    Data.Nighthold = {
        {
            d = {{1530, 1743, 1872}},   --Nightspire
            o = {47106, 47119, 47124},
        },
        {
            d = {{1530, 1737, 1866}},   --Font Of Night
            o = {47121, 47126, 47108, 47113},
        },
    };

    Data.Antorus = {
        {
            d = {{1712, 2009, 2082}, {1712, 2004, 2088}},     --Exhaust
            o = {47848, 47868},
        },
        {
            d = {{1712, 1983, 2069}, {1712, 1986, 2073}, {1712, 1984, 2063}},     --Burning Throne
            o = {47865, },
        },
    };

    Data.Ulduar = {
        {
            d = {{603, 1637, 1132}},     --Formation Grounds
            o = {37961},
        },
        {
            d = {{603, 1638, 1136}, {603, 1639, 1139}, {603, 1640, 1142}},     --Colossal Forge
            o = {37962},
        },
        {
            d = {{603, 1640, 1142}},     --Scrapyard
            o = {37963},
        },
        {
            d = {{603, 1641, 1140}, {603, 1642, 1137}, {603, 1650, 1130}},     --Antechamber of Ulduar
            o = {37964},
        },
        {
            d = {{603, 1642, 1137}, {603, 1643, 1131}, {603, 1644, 1135}, {603, 1645, 1141}},     --Shattered Walkway
            o = {37965},
        },
        {
            d = {{603, 1646, 1133}, {603, 1644, 1135}, {603, 1645, 1141}},     --Conservatory of Life
            o = {37967},
        },
        {
            d = {{603, 1647, 1138}},     --Spark of Imagination
            o = {37969},
        },
        {
            d = {{603, 1649, 1143}},     --Prison of Yogg-Saron
            o = {37971},
        },
    };

    for raid, m in pairs(Data) do
        for _, n in ipairs(m) do
            for _, gossipOptionID in ipairs(n.o) do
                InstanceTeleporterOptions[gossipOptionID] = n.d;
            end
        end
    end
end