--Required dbValue: AutoSelectGossip = true

local _, addon = ...

local AutoSelectGossip = {
    --[gossipOptionID] = true(always), 1(select when it's the only option)
    [48598] = true,         --I'd like to check my mail.   [NPC: 132969] Katy Stampwhistle
    [55193] = true,         --Mail [NPC: 191869] Child of Ohn'ahra
    [109275] = true,        --Reporting to duty (Time Rift)

    [107824] = 1,           --Trading Post
    [107827] = 1,           --Trading Post
    [107825] = 1,           --Trading Post
    [107826] = 1,           --Trading Post

    [123145] = 1,           --Scouting Map, Dornagal
    [123493] = 1,           --Delver's Guide, Dornagal
    [122660] = 1,           --Explorers' League Supplies, Dornagal
    [120910] = 1,           --Breem, Dornagal Flight Master
};

local function IsAutoSelectOption(gossipOptionID, onlyOption)
    if gossipOptionID then
        if onlyOption then
            return AutoSelectGossip[gossipOptionID] == 1
        else
            return AutoSelectGossip[gossipOptionID] == true
        end
    end
    return false
end
addon.IsAutoSelectOption = IsAutoSelectOption;