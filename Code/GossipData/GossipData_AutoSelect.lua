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

    [45972] = true,         --A Draught of Hope. I've brought you some arcwine... drink up! (Suramar quest)
    [45846] = 1,            --I will take your Arcwine and share it with the needy.

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
    [131402] = 1,           --Nerubian Scout, I'll clear out these goblins.
    [131318] = 1,           --Madam Goya, I'll stop the Darkfuse and gather the Black Blood you need.
    [133907] = 1,           --Vaultwarden Falnora, I'll recover what I can.
    [132634] = 1,           --Engineer Fizzlepickle, I know some of those words.
    [131152] = 1,           --Exterminator Janx, I'll get the gadget and will help your friends.
    [134016] = 1,           --Vaultwarden Gandrus
    [134070] = 1,           --Xeronia, I will save them.
    [125513] = 1,           --Prospera Cogwail, (Delve)
    [134202] = 1,           --Spymaster Casnegosa, (Delve)
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