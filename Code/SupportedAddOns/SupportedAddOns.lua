local _, addon = ...

local f = CreateFrame("Frame");

f.list = {};

f:SetScript("OnEvent", function(self, event)
    self:SetScript("OnEvent", nil);
    self:UnregisterEvent(event);

    local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;

    for _, data in ipairs(f.list) do
        if IsAddOnLoaded(data[1]) then
            data[2]();
        end
    end

    f.list = nil;
end);

local function AddSupportedAddOn(addonName, onLoadedCallback)
    table.insert(f.list, {addonName, onLoadedCallback});
end
addon.AddSupportedAddOn = AddSupportedAddOn;

f:RegisterEvent("PLAYER_ENTERING_WORLD");