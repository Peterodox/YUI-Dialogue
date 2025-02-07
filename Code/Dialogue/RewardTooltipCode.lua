local _, addon = ...
local API = addon.API;
local L = addon.L;
local TooltipFrame = addon.SharedTooltip;

local GetItemCount = C_Item.GetItemCount;
local IsQuestRequiredItem = API.IsQuestRequiredItem;

local RewardTooltipCode = {};
addon.RewardTooltipCode = RewardTooltipCode;

local UIParent = UIParent;

-- User Settings
local USE_BLIZZARD_TOOLTIP = false;
------------------

RewardTooltipCode.tooltipNames = {
    "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "GarrisonFollowerTooltip",
};

function RewardTooltipCode:RestoreBlizzardTooltip(tooltip)
    if tooltip then
        tooltip:Hide();
        tooltip:SetScale(1);
        tooltip:SetParent(UIParent);
        tooltip:SetFrameStrata("TOOLTIP");
    end
end

function RewardTooltipCode:ModifyBlizzardTooltip(tooltip)
    if tooltip then
        if not self.TopFrame then
            self.TopFrame = CreateFrame("Frame", nil);
            self.TopFrame:SetFrameStrata("TOOLTIP");
            self.TopFrame:SetFrameLevel(100);
            self.TopFrame:SetFixedFrameStrata(true);
        end
        local scale = UIParent:GetEffectiveScale();
        tooltip:SetScale(scale);
        tooltip:SetParent(self.TopFrame);
        tooltip:Show();
        tooltip:Hide();
    end
end

function RewardTooltipCode:TakeOutGameTooltip()
    if not self.gametooltipChanged then
        self.gametooltipChanged = true;
        local _G = _G;
        for _, name in ipairs(self.tooltipNames) do
            self:ModifyBlizzardTooltip(_G[name]);
        end
    end
end

function RewardTooltipCode:RestoreGameTooltip()
    if self.gametooltipChanged then
        self.gametooltipChanged = nil;
        local _G = _G;
        for _, name in ipairs(self.tooltipNames) do
            self:RestoreBlizzardTooltip(_G[name]);
        end
    end
end

local function AppendQuestRewardContextDescription(self, tooltip)
    --self: ItemButtonShared

    if not self.questRewardContextFlags then return end;

    local IsSet = FlagsUtil and FlagsUtil.IsSet;
    local enumFlags = Enum.QuestRewardContextFlags;
    if not (IsSet and enumFlags) then return end;

    local flag = self.questRewardContextFlags;
    local rewardContextLine;

	if self.objectType == "item" then
        if IsSet(flag, enumFlags.FirstCompletionBonus) then
            rewardContextLine = ACCOUNT_FIRST_TIME_QUEST_BONUS_TOOLTIP;
        elseif IsSet(flag, enumFlags.RepeatCompletionBonus) then
            rewardContextLine =  ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_BONUS_TOOLTIP;
        end
	elseif self.objectType == "currency" and self.currencyInfo then
        local currencyInfo = self.currencyInfo;
        local entireAmountIsBonus = currencyInfo.bonusRewardAmount == currencyInfo.totalRewardAmount;
        local isReputationReward = C_CurrencyInfo.GetFactionGrantedByCurrency(currencyInfo.currencyID) ~= nil;
        if IsSet(flag, enumFlags.FirstCompletionBonus) then
            if entireAmountIsBonus then
                rewardContextLine = ACCOUNT_FIRST_TIME_QUEST_BONUS_TOOLTIP;
            else
                local bonusString = isReputationReward and ACCOUNT_FIRST_TIME_QUEST_BONUS_REP_TOOLTIP or ACCOUNT_FIRST_TIME_QUEST_BONUS_CURRENCY_TOOLTIP;
                rewardContextLine = bonusString:format(currencyInfo.baseRewardAmount, currencyInfo.bonusRewardAmount);
            end
        end

        if IsSet(flag, enumFlags.RepeatCompletionBonus) then
            if entireAmountIsBonus then
                rewardContextLine = ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_BONUS_TOOLTIP;
            else
                local bonusString = isReputationReward and ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_REP_BONUS_TOOLTIP or ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_CURRENCY_BONUS_TOOLTIP;
                rewardContextLine = bonusString:format(currencyInfo.baseRewardAmount, currencyInfo.bonusRewardAmount);
            end
        end
	end

    if rewardContextLine then
        if tooltip.tooltip then
		    tooltip:AddBlankLine();
        else
            tooltip:AddLine(" ");
        end

        if tooltip.AddColoredLine then
		    tooltip:AddColoredLine(rewardContextLine, QUEST_REWARD_CONTEXT_FONT_COLOR);
        else
            GameTooltip_AddColoredLine(tooltip, rewardContextLine, QUEST_REWARD_CONTEXT_FONT_COLOR);
        end

        tooltip:Show();
	end
end

local function CustomTooltip_OnEnter(self)
    local tooltip = TooltipFrame;
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint("BOTTOMLEFT", self.Icon, "TOPRIGHT", 0, 2);
    tooltip.itemID = nil;

    if self.objectType == "item" then
        local showCollectionText = true;
        tooltip:SetQuestItem(self.type, self.index, showCollectionText);

        if self.type == "required" and self.itemID and (not IsQuestRequiredItem(self.itemID)) then
            local numInBags = GetItemCount(self.itemID);
            local numTotal = GetItemCount(self.itemID, true);
            if numInBags and numTotal then
                if numInBags == numTotal then
                    tooltip:AddLeftLine(L["Format You Have X"]:format(numTotal), 1, 0.82, 0);
                else
                    tooltip:AddLeftLine(L["Format You Have X And Y In Bank"]:format(numTotal, numTotal - numInBags), 1, 0.82, 0);
                end
                tooltip:Show();
            end
        end

        AppendQuestRewardContextDescription(self, tooltip);

    elseif self.objectType == "currency" then
        tooltip:SetQuestCurrency(self.type, self.index);
        if self.currencyID then
            AppendQuestRewardContextDescription(self, tooltip);

            local factionStatus = API.GetFactionStatusTextByCurrencyID(self.currencyID);
            if factionStatus then
                tooltip:AddLeftLine(factionStatus, 1, 0.82, 0);
                tooltip:Show();
            end
        end

    elseif self.objectType == "spell" then
        local isPet = nil;
        local showSubtext = true;
        tooltip:SetSpellByID(self.spellID, isPet, showSubtext);
    elseif self.objectType == "reputation" then
        tooltip:SetTitle(self.factionName, 1, 1, 1);
        tooltip:AddLeftLine(L["Format Reputation Reward Tooltip"]:format(self.rewardAmount, self.factionName), 1, 0.82, 0, true);
        if self.factionID then
            local factionStatus = API.GetFactionStatusText(self.factionID);
            if factionStatus then
                tooltip:AddLeftLine(factionStatus, 1, 0.82, 0);
            end
        end
        tooltip:Show();
    elseif self.objectType == "skill" then
        --C_TradeSkillUI.OpenTradeSkill(185) --Require Hardware Event
        local bonusPoint = self.Count:GetText();
        local skillName = self.Name:GetText();
        tooltip:SetTitle(bonusPoint.." "..skillName, 1, 1, 1);
        local info = self.skillLineID and C_TradeSkillUI.GetProfessionInfoBySkillLineID(self.skillLineID);
        if info then
            local currentLevel = info.skillLevel;
            local maxLevel = info.maxSkillLevel;
            if currentLevel and maxLevel and maxLevel ~= 0 then
                tooltip:AddLeftLine(L["Format Current Skill Level"]:format(currentLevel, maxLevel), 1, 0.82, 0);
            end
            tooltip:Show();
        end
    elseif self.objectType == "follower" then
        tooltip:SetFollowerByID(self.followerID);
    elseif self.objectType == "warmode" then
        tooltip:SetTitle(L["War Mode Bonus"], 1, 0.82, 0);
        tooltip:AddLeftLine(WAR_MODE_BONUS_QUEST, 1, 1, 1, true);
        tooltip:Show();
    elseif self.objectType == "honor" then
        tooltip:SetCurrencyByID(self.currencyID);
    else
        tooltip:Hide();
    end

    self.UpdateTooltip = nil;
end

local function GameTooltip_OnEnter(self)
    local tooltip = GameTooltip;
    tooltip:Hide();
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint("BOTTOMLEFT", self.Icon, "TOPRIGHT", 0, 2);

    if self.objectType == "item" then
        local showCollectionText = true;
        tooltip:SetQuestItem(self.type, self.index, showCollectionText);
        GameTooltip_ShowCompareItem(tooltip);
        AppendQuestRewardContextDescription(self, tooltip);

    elseif self.objectType == "currency" then
        tooltip:SetQuestCurrency(self.type, self.index);
        if self.currencyID then
            AppendQuestRewardContextDescription(self, tooltip);
        end

    elseif self.objectType == "spell" then
        local isPet = nil;
        local showSubtext = true;
        tooltip:SetSpellByID(self.spellID, isPet, showSubtext);

    elseif self.objectType == "reputation" then
        local wrapText = false;
        GameTooltip_SetTitle(tooltip, QUEST_REPUTATION_REWARD_TITLE:format(self.factionName), HIGHLIGHT_FONT_COLOR, wrapText);
        if API.IsAccountWideReputation(self.factionID) then
            GameTooltip_AddColoredLine(GameTooltip, REPUTATION_TOOLTIP_ACCOUNT_WIDE_LABEL, ACCOUNT_WIDE_FONT_COLOR);
        end
        GameTooltip_AddNormalLine(GameTooltip, QUEST_REPUTATION_REWARD_TOOLTIP:format(self.rewardAmount, self.factionName));
        tooltip:Show();

    elseif self.objectType == "skill" then
        local bonusPoint = self.Count:GetText();
        local skillName = self.Name:GetText();
        tooltip:SetText(bonusPoint.." "..skillName, 1, 1, 1);
        local info = self.skillLineID and C_TradeSkillUI.GetProfessionInfoBySkillLineID(self.skillLineID);
        if info then
            local currentLevel = info.skillLevel;
            local maxLevel = info.maxSkillLevel;
            if currentLevel and maxLevel and maxLevel ~= 0 then
                tooltip:AddLeftLine(L["Format Current Skill Level"]:format(currentLevel, maxLevel), 1, 0.82, 0);
            end
            tooltip:Show();
        end

    elseif self.objectType == "follower" then
        tooltip:Hide();
        GarrisonFollowerTooltip:ClearAllPoints();
        GarrisonFollowerTooltip:SetPoint("BOTTOMLEFT", self.Icon, "TOPRIGHT", 0, 2);
        local data = GarrisonFollowerTooltipTemplate_BuildDefaultDataForID(self.followerID);
        GarrisonFollowerTooltip_ShowWithData(data);

    elseif self.objectType == "warmode" then
        tooltip:SetText(L["War Mode Bonus"], 1, 0.82, 0);
        tooltip:AddLine(WAR_MODE_BONUS_QUEST, 1, 1, 1, true);
        tooltip:Show();

    elseif self.objectType == "honor" then
        tooltip:SetCurrencyByID(self.currencyID);

    else
        tooltip:Hide();
    end

    self.UpdateTooltip = GameTooltip_OnEnter;   --RAM usage doesn't look good
end

function RewardTooltipCode:OnEnter(itemButton)
    TooltipFrame:Hide();

    if USE_BLIZZARD_TOOLTIP then
        self:TakeOutGameTooltip();
        GameTooltip_OnEnter(itemButton);
    else
        CustomTooltip_OnEnter(itemButton);
    end
end

function RewardTooltipCode:OnLeave(itemButton)
    TooltipFrame:Hide();
    GameTooltip:Hide();
    self:RestoreGameTooltip();
end

function RewardTooltipCode:ShowHyperlink(itemButton, hyperlink)
    TooltipFrame:Hide();

    local tooltip;
    if USE_BLIZZARD_TOOLTIP then
        RewardTooltipCode:TakeOutGameTooltip();
        tooltip = GameTooltip;
    else
        tooltip = TooltipFrame;
    end
    tooltip:SetOwner(itemButton, "ANCHOR_NONE");

    local relativeTo = itemButton.Icon or itemButton;
    tooltip:SetPoint("BOTTOMLEFT", relativeTo, "TOPRIGHT", 0, 2);
    tooltip:SetHyperlink(hyperlink);
    tooltip:Show();
end

do
    local CallbackRegistry = addon.CallbackRegistry;

    CallbackRegistry:Register("SettingChanged.UseBlizzardTooltip", function(dbValue)
        if dbValue == true then
            USE_BLIZZARD_TOOLTIP = true;
        else
            USE_BLIZZARD_TOOLTIP = false;
            RewardTooltipCode:RestoreGameTooltip();
        end
    end);
end