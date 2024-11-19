local _, addon = ...
local Skimmer = addon.Skimmer;

local C_TooltipInfo = addon.TooltipAPI;


local DataInstanceIDToButton = {};


DUISkimmerOptionMixin = {};

function DUISkimmerOptionMixin:SetQuest(questInfo)
    local questID = questInfo.questID;
    self.questID = questID;
    self.Title:SetText(questInfo.title);
    self:UpdateQuestObjectives();
end

function DUISkimmerOptionMixin:Layout()

end

function DUISkimmerOptionMixin:UpdateQuestObjectives()
    if not self.questID then return end;
    local tooltipData = C_TooltipInfo.GetHyperlink("quest:"..self.questID);
    local tooltipText;
    if tooltipData then
        Skimmer:RegisterEvent("TOOLTIP_DATA_UPDATE");
        self.dataInstanceID = tooltipData.dataInstanceID;
        DataInstanceIDToButton[self.dataInstanceID] = self;
        for i, line in ipairs(tooltipData.lines) do
            if i == 1 then

            else
                --print(i, line.leftText)
                if line.leftText then
                    if line.leftText ~= " " or tooltipText ~= nil then
                        tooltipText = line.leftText;
                    end
                end
            end
        end
    else
        tooltipText = "...";
        self.dataInstanceID = nil;
    end
    self.Desc:SetText(tooltipText);
end


do
    function Skimmer:HandleTooltipDataUpdate(dataInstanceID)
        if dataInstanceID and DataInstanceIDToButton[dataInstanceID] then
            DataInstanceIDToButton[dataInstanceID]:UpdateQuestObjectives();
        end
    end

    function Skimmer:ClearTooltipDataWatchList()
        DataInstanceIDToButton = {};
        self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    end
end