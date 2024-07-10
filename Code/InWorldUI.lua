--Unused

local _, addon = ...
local API = addon.API;

local EL = CreateFrame("Frame");

EL:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED");

function EL:OnEvent(event, ...)
    if event == "PLAYER_SOFT_INTERACT_CHANGED" then
        local oldTarget, newTarget = ...;   --GUID
        if newTarget ~= self.guid then
            self.guid = newTarget;
            print(newTarget)
            if newTarget then
                local fileID = API.GetInteractType("softinteract");
                print(fileID);
            end
        end
    end
end

EL:SetScript("OnEvent", EL.OnEvent);