local _, addon = ...
local Skimmer = addon.Skimmer;
local QuestDataProvider = Skimmer.QuestDataProvider;

local C_TooltipInfo = addon.TooltipAPI;


local DataInstanceIDToButton = {};


DUISkimmerOptionMixin = {};

function DUISkimmerOptionMixin:SetQuest(questInfo, getObjectiveFromTooltip)
    local questID = questInfo.questID;
    self.questID = questID;
    self.Title:SetText(questInfo.title);

    getObjectiveFromTooltip = true;

    --[[
    if getObjectiveFromTooltip then
        self:UpdateQuestObjectives();
    else
        local objectiveText;
        if QuestDataProvider:IsQuestDetailCached(questID) then
            objectiveText = QuestDataProvider:GetQuestObjective(questID);
        else
            QuestDataProvider:RequestQuestDetail(questID);
            objectiveText = "...";
        end
        self.Desc:SetText(objectiveText);
    end
    --]]

    self:UpdateQuestObjectives();
    self:UpdateQuestData();

    local function OnQuestLoaded(id)
        if self.questID == id and self:IsShown() then
            self:UpdateQuestData();
        end
    end
    addon.CallbackRegistry:LoadQuest(self.questID, OnQuestLoaded);
end

local function JoinText(a, b)
    if a then
        if b then
            return a.." |cff808080·|r "..b
        else
            return a
        end
    else
        return b
    end
end

function DUISkimmerOptionMixin:UpdateQuestData()
    local questID = self.questID;
    print(questID)
    local output;
    local iconSize = 16;

    local totalXp, baseXp = GetQuestLogRewardXP(questID);
    if totalXp and totalXp > 0 then
        totalXp = "XP "..totalXp;
        output = JoinText(output, totalXp);
    end

    local money = GetQuestLogRewardMoney(questID);
    if money and money > 0 then
        local height = nil;
        local coinText = C_CurrencyInfo.GetCoinTextureString(money, height);
        output = JoinText(output, coinText);
    end

    local numRewards = GetNumQuestLogRewards(questID);
    if numRewards and numRewards > 0 then
        local icons;
        for index = 1, numRewards do
            local name, texture, count, quality, isUsable, itemID, itemLevel = GetQuestLogRewardInfo(index, questID);
            if texture then
                texture = string.format("|T%s:%s:%s|t", texture, iconSize, iconSize);
                if icons then
                    icons = icons.." "..texture;
                else
                    icons = texture;
                end
            end

            --[[
            local itemLink = GetQuestItemLink("reward", index, questID);    --Unreliable: missing/wrong info    --Use C_TooltipInfo.GetQuestLogItem(type, itemIndex, questID, allowCollectionText) C_TooltipInfo.GetQuestLogCurrency(type, currencyIndex, questID)
            print("itemLink", itemLink)
            --]]
        end
        output = JoinText(output, icons);
    end

    local reputationRewards = C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID);
    if reputationRewards then
        for _, info in ipairs(reputationRewards) do
            local factionID, rewardAmount = info.factionID, info.rewardAmount;
            local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID);
            local factionName = majorFactionData.name;
            output = JoinText(output, string.format("+%s %s", rewardAmount, factionName));
        end
    end

    if C_QuestInfoSystem.HasQuestRewardCurrencies(questID) then
        local questRewardCurrencyInfo = C_QuestInfoSystem.GetQuestRewardCurrencies(questID);
        if questRewardCurrencyInfo then
            local icons;
            for _, info in ipairs(questRewardCurrencyInfo) do
                local texture = info.texture;
                if texture then
                    texture = string.format("|T%s:%s:%s|t", texture, iconSize, iconSize);
                    if icons then
                        icons = icons.." "..texture;
                    else
                        icons = texture;
                    end
                end
            end
            output = JoinText(output, icons);
        end
    end

    if C_QuestInfoSystem.HasQuestRewardSpells(questID) then
        local spellIDs = C_QuestInfoSystem.GetQuestRewardSpells(questID);
        if spellIDs then
            for _, spellID in ipairs(spellIDs) do
                local info = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID);
                if info then
                    
                end
            end
        end
    end
    --GetNumQuestLogChoices(questID [, includeCurrencies])
    --GetQuestLogChoiceInfo

    if output then
        output = strtrim(output);
    end

    self.TestRewardDisplay:SetText(output);
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
                        break
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

    function Skimmer:UpdateDisplayedQuests()
        local function AddItemText(optionButton)
            if optionButton.questID then
                optionButton:UpdateQuestData();
            end
        end
        self.optionButtonPool:ProcessActiveObjects(AddItemText);
    end
end