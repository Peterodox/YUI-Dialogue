local _, addon = ...

local function HideFallback(options)
    local panel = CuratorGossip;
    if not (panel and panel:IsShown()) then return end;

    -- Curator can open its fallback before Dialogue UI builds the same options.
    for _, option in ipairs(options) do
        if option.element.curator then
            panel:Hide();
            return
        end
    end
end

addon.AddSupportedAddOn("Curator", function()
    addon.CallbackRegistry:Register("DialogueUI.AddedGossipOptions", HideFallback);
end);
