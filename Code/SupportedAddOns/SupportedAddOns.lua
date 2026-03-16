local _, addon = ...
local DoesGlobalObjectExist = addon.API.DoesGlobalObjectExist;

local List = {};

local function CheckSupportedAddOns()
    local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;
    local addonName, addonLoaded, requiredMethods;

    for _, data in ipairs(List) do
        addonName, addonLoaded, requiredMethods = data[1], data[2], data[3];
        if (addonName and IsAddOnLoaded(addonName)) or (not addonName) then
            local requirementMet = addonName and true;

            if requiredMethods then
                requirementMet = true;
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

    List = nil;
end


local function AddSupportedAddOn(addonName, onLoadedCallback, requiredMethods)
    --Allows nillable addonName
    table.insert(List, {addonName, onLoadedCallback, requiredMethods});
end
addon.AddSupportedAddOn = AddSupportedAddOn;


addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", CheckSupportedAddOns);
