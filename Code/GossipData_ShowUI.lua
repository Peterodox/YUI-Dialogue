-- Show UIParent immediately after clicking on this option
-- These options usually open other Blizzard Interface, which may not work correctly if the UIParent is hidden  

local _, addon = ...

local ShowUIGossip = {
    [64058] = true,     --Iskaaran Fishing Gear
    [55556] = true,     --Iskaara Renown
    [54514] = true,     --Maruuk Renown
    [55557] = true,     --Valdrakken Renown
    [54632] = true,     --Dragonscale Renown   
};

local function DoesOptionOpenUI(gossipOptionID)
    return gossipOptionID and ShowUIGossip[gossipOptionID] == true
end
addon.DoesOptionOpenUI = DoesOptionOpenUI;