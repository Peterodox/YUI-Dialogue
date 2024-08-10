local _, addon = ...
local DoesGlobalObjectExist = addon.API.DoesGlobalObjectExist;

local f = CreateFrame("Frame");

f.list = {};

f:SetScript("OnEvent", function(self, event)
    self:SetScript("OnEvent", nil);
    self:UnregisterEvent(event);

    local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;
    local addonName, addonLoaded, requiredMethods;

    for _, data in ipairs(f.list) do
        addonName, addonLoaded, requiredMethods = data[1], data[2], data[3];
        if IsAddOnLoaded(addonName) then
            local requirementMet = true;
            if requiredMethods then
                for _, method in ipairs(requiredMethods) do
                    if not DoesGlobalObjectExist(method) then
                        requirementMet = false;
                        break
                    end
                end
            end

            if requirementMet then
                addonLoaded();
            end
        end
    end

    f.list = nil;
end);

local function AddSupportedAddOn(addonName, onLoadedCallback)
    table.insert(f.list, {addonName, onLoadedCallback});
end
addon.AddSupportedAddOn = AddSupportedAddOn;

f:RegisterEvent("PLAYER_ENTERING_WORLD");