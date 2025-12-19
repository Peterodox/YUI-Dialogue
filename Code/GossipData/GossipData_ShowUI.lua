-- Show UIParent immediately after clicking on this option
-- These options usually open other Blizzard Interface, which may not work correctly if the UIParent is hidden  

local _, addon = ...
local GossipDataProvider = addon.GossipDataProvider;
local GetInteractType = addon.API.GetInteractType;
--local IsTargetAdventureMap = addon.API.IsTargetAdventureMap;

local ShowUIGossip = {
    [64058]  = true,    --Iskaaran Fishing Gear
    [55556]  = true,    --Iskaara Renown
    [54514]  = true,    --Maruuk Renown
    [55557]  = true,    --Valdrakken Renown
    [54632]  = true,    --Dragonscale Renown
    [82449]  = true,    --Faerin, Dornagal Weekly
    [124652] = true,    --Kaydee Racketring, (Quest) I'm ready to sign a contract
    [125367] = true,    --Mobber, <Access D.R.I.V.E.>
    [124311] = true,    --(Lorewalking) What stories can you tell me?
    [131481] = true,    --Overcharged Titan Console, <View overcharged console discs.>
    [132979] = true,    --I want to empower my Reshii Wraps.
};

function GossipDataProvider:DoesOptionOpenUI(gossipOptionID)
    --if IsTargetAdventureMap() then
    --    return true
    --end

    return gossipOptionID and ShowUIGossip[gossipOptionID] == true
end

if PetStableFrame then
    --Classic: PetStableFrame and ClassTrainerFrame become unresponsive if then are brought up when IsVisible() == false
    local ShoUIInteractType = {
        ["Cursor Stablemaster"] = true,
        ["Cursor Trainer"] = true,
    };

    function GossipDataProvider:DoesOptionOpenUI(gossipOptionID)
        local interactType = GetInteractType("npc");
        if interactType and ShoUIInteractType[interactType] then
            return true
        end

        return gossipOptionID and ShowUIGossip[gossipOptionID] == true
    end
end