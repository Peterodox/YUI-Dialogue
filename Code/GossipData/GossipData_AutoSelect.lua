--Required dbValue: AutoSelectGossip = true

local _, addon = ...

local AutoSelectGossip = {
    --[gossipOptionID] = true(always), 1(select when it's the only option)
    [48598] = true,         --I'd like to check my mail.   [NPC: 132969] Katy Stampwhistle
    [55193] = true,         --Mail [NPC: 191869] Child of Ohn'ahra
    [109275] = true,        --Reporting to duty (Time Rift)
    [120733] = true,        --Theater Troupe
    [132128] = true,        --Queue Horrific Visions (Stormwind)
    [132129] = true,        --Queue Horrific Visions (Orgrimmar)
    [132100] = true,        --Show Visions Upgrades (Horrific Visions Revisited)
    [49742] = true,         --Horrific Visions, Garona

    [107824] = 1,           --Trading Post
    [107827] = 1,           --Trading Post
    [107825] = 1,           --Trading Post
    [107826] = 1,           --Trading Post
    [121665] = 1,           --Trading Post (Dornagal)
    [121672] = 1,           --Trading Post (Dornagal)

    [123145] = 1,           --Scouting Map, Dornagal
    [123493] = 1,           --Delver's Guide, Dornagal
    [122660] = 1,           --Explorers' League Supplies, Dornagal
    [120910] = 1,           --Breem, Dornagal Flight Master

    [125367] = 1,           --DRIVE, Mobber

    --Delves Start
    [111366] = 1,           --Fungal Folly, Stoneguard Benston
    [120018] = 1,           --Waterworks, Foreman Bruknar
    [121502] = 1,           --Underkeep, Weaver's Instructions
    [121408] = 1,           --Skittering Breach, Lamplighter Havrik Chayvn
    [120540] = 1,           --Earthcrawl Mines, Lamplighter Rathling
    [120541] = 1,           --Earthcrawl Mines, 2nd Phase, Lamplighter Rathling
    [121526] = 1,           --The Dread Pit, Vanathia
    [121508] = 1,           --The Dread Pit, Vant
    [120767] = 1,           --Nightfall Sanctum, Great Kyron
    [125516] = 1,           --Nightfall Sanctum,Nimsi Loosefire
    [131474] = 1,           --Tak-Rethan, Pamsy
    [121566] = 1,           --The Spiral Weave, Weaver's Instructions
};

local function IsAutoSelectOption(gossipOptionID, onlyOption)
    if gossipOptionID then
        if AutoSelectGossip[gossipOptionID] == true then
            return true
        end
        if onlyOption then
            return AutoSelectGossip[gossipOptionID] == 1
        end
    end
    return false
end
addon.IsAutoSelectOption = IsAutoSelectOption;