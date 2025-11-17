-- Some addons resize WorldFrame thus affect our frame size calculation
-- 

local _, addon = ...
local API = addon.API;


local DEFAULT_WIDTH, DEFAULT_HEIGHT = WorldFrame:GetSize();


do
    local ADDON_NAME = "SunnArt";

    local function OnAddOnLoaded()
        --Override our API
        function API.GetBestViewportSize()
            local viewportWidth = math.min(DEFAULT_WIDTH, DEFAULT_HEIGHT * 16/9);
            return viewportWidth, DEFAULT_HEIGHT
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end