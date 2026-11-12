---- Implementation Guide ----

--[[
    local addonName = "Name";

    local function isItemUpgrade(itemLink)
        local isUpgrade = true;
        local isDataReady = true;  -- If false, DUI Tooltip will requery again
        return isUpgrade, isDataReady;
    end

    local function tooltipWritter(tooltipCapture, itemLink)
        local anyChanges = false;  -- Change it to true if any changes were made so our tooltip can process the added lines.
        if isItemUpgrade(itemLink) then
            anyChanges = true;
            tooltipCapture:AddLine(tooltipText, r, g, b, wrapText);
            tooltipCapture:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB);
        end
        return anyChanges;
    end

    DialogueUIAPI.AddItemUpgradeEvaluator(addonName, isItemUpgrade, tooltipWritter);
--]]




local _, addon = ...
local API = addon.API;


local ExternalEvaluatorName;


---@param addonName string Your addon's name. Preferably in English to avoid font issue.
---@param isItemUpgrade function A function that accepts an itemLink then return true/false.
---@param tooltipWritter function? [Optional] tooltipWritter(tooltipCapture, itemLink) return true. Add stuff to DUI's item tooltip; must return true if you add anything. See "Code/Tooltip/Tooltip_Capture.lua" for supported methods.
local function AddItemUpgradeEvaluator(addonName, isItemUpgrade, tooltipWritter)
    local success = true;

    if type(addonName) ~= "string" then
        success = false;
        API.PrintMessage("ItemUpgradeEvaluator: Missing Name");
        return;
    end

    if type(isItemUpgrade) ~= "function" then
        success = false;
        API.PrintMessage("ItemUpgradeEvaluator: Missing \"isItemUpgrade\" Function");
    end

    if tooltipWritter and type(tooltipWritter) ~= "function" then
        success = false;
        API.PrintMessage("ItemUpgradeEvaluator: \"tooltipWritter\" Must Be A Function");
    end

    if not success then return; end

    if ExternalEvaluatorName then
        API.PrintMessage("Another ItemUpgradeEvaluator already exists: "..ExternalEvaluatorName);
        return;
    end

    isItemUpgrade("item:2092"); -- Verify if the function will error

    ExternalEvaluatorName = addonName;

    API.IsItemAnUpgrade_External = function(itemLink)
        local isUpgrade, isDataReady = isItemUpgrade(itemLink);
        if isDataReady == nil then
            return isUpgrade, isUpgrade ~= nil;
        else
            return isUpgrade, isDataReady;
        end
    end

    if tooltipWritter then
        local tooltip = addon.SharedTooltip;
        local TooltipCapture = addon.TooltipCapture;

        function tooltip:ProcessItemExternal(itemLink)
            TooltipCapture:ClearLines();
            if tooltipWritter(TooltipCapture, itemLink) then
                tooltip:AddBlankLine();
                TooltipCapture:SendToProcess(self);
            end
        end
    end
end
DialogueUIAPI.AddItemUpgradeEvaluator = AddItemUpgradeEvaluator;
addon.AddItemUpgradeEvaluator = AddItemUpgradeEvaluator;
