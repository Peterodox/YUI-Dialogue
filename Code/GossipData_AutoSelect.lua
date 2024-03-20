--Required dbValue: AutoSelectGossip = true

local _, addon = ...

local AutoSelectGossip = {
    [48598] = true,         -- I'd like to check my mail.   [NPC: 132969] Katy Stampwhistle
    [109275] = true,        --Reporting to duty (Time Rift)
};

local function IsAutoSelectOption(gossipOptionID)
    return gossipOptionID and AutoSelectGossip[gossipOptionID] == true
end
addon.IsAutoSelectOption = IsAutoSelectOption;