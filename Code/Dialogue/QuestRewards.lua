local _, addon = ...
local API = addon.API;

--User Settings:
local SIMPLIFY_CURRENCY_REWARD = false;

----------------

local GetQuestID = GetQuestID;
local GetQuestRewardSpells = C_QuestInfoSystem.GetQuestRewardSpells;
local GetQuestRewardSpellInfo = C_QuestInfoSystem.GetQuestRewardSpellInfo;
local GetNumQuestRewards = GetNumQuestRewards;
local GetNumQuestChoices = GetNumQuestChoices;
local GetNumRewardCurrencies = API.GetNumRewardCurrencies;
local GetRewardMoney = GetRewardMoney;
local GetRewardSkillPoints = API.GetRewardSkillPoints;
local GetRewardSkillLineID = GetRewardSkillLineID;
local GetRewardXP = GetRewardXP;
local GetRewardArtifactXP = API.GetRewardArtifactXP;
local GetRewardHonor = GetRewardHonor;
local GetRewardTitle = GetRewardTitle;
local QuestCanHaveWarModeBonus = API.QuestCanHaveWarModeBonus;
local QuestHasQuestSessionBonus = API.QuestHasQuestSessionBonus;
local GetQuestOfferMajorFactionReputationRewards = (C_QuestOffer and C_QuestOffer.GetQuestOfferMajorFactionReputationRewards) or API.AlwaysFalse;
local GetQuestItemInfoLootType = API.GetQuestItemInfoLootType;
local IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown;
local IsCharacterNewlyBoosted = IsCharacterNewlyBoosted;


local tinsert = table.insert;
local tsort = table.sort;
local ipairs = ipairs;

--MirageDialogBaseMixin Declared in SharedUITemplates.lua

local QuestCompleteSpellType = Enum.QuestCompleteSpellType;

local QUEST_INFO_SPELL_REWARD_ORDERING = {
	QuestCompleteSpellType.Follower,
	QuestCompleteSpellType.Companion,
	QuestCompleteSpellType.Tradeskill,
	QuestCompleteSpellType.Ability,
	QuestCompleteSpellType.Aura,
	QuestCompleteSpellType.Spell,
};

local QUEST_INFO_SPELL_REWARD_TO_HEADER = {};

do	--Retail
	local SpellTypes = {
		{"Unlock", "REWARD_UNLOCK"},
		{"QuestlineUnlock", "REWARD_QUESTLINE_UNLOCK"},
		{"QuestlineReward", "REWARD_QUESTLINE_REWARD"},
		{"QuestlineUnlockPart", "REWARD_QUESTLINE_UNLOCK_PART"},
	};

	for _, info in ipairs(SpellTypes) do
		local name = info[1];
		local v = QuestCompleteSpellType[name];
		if v then
			local header = info[2];
			table.insert(QUEST_INFO_SPELL_REWARD_ORDERING, v);
			QUEST_INFO_SPELL_REWARD_TO_HEADER[v] = _G[header] or header;
		end
	end

	SpellTypes = nil;
end

--[[
local QUEST_INFO_SPELL_REWARD_TO_HEADER = {
	[QuestCompleteSpellType.Follower] = REWARD_FOLLOWER,
	[QuestCompleteSpellType.Companion] = REWARD_COMPANION,
	[QuestCompleteSpellType.Tradeskill] = REWARD_TRADESKILL_SPELL,
	[QuestCompleteSpellType.Ability] = REWARD_ABILITY,
	[QuestCompleteSpellType.Aura] = REWARD_AURA,
	[QuestCompleteSpellType.Spell] = REWARD_SPELL,
	[QuestCompleteSpellType.Unlock] = REWARD_UNLOCK,
	[Enum.QuestCompleteSpellType.QuestlineUnlock] = REWARD_QUESTLINE_UNLOCK,
	[Enum.QuestCompleteSpellType.QuestlineReward] = REWARD_QUESTLINE_REWARD,
	[Enum.QuestCompleteSpellType.QuestlineUnlockPart] = REWARD_QUESTLINE_UNLOCK_PART,
};
--]]

local function GetRewardSpellBucketType(spellInfo)
	if spellInfo.type and spellInfo.type ~= QuestCompleteSpellType.LegacyBehavior then
		return spellInfo.type;
	elseif spellInfo.isTradeskillSpell then
		return QuestCompleteSpellType.Tradeskill;
	elseif spellInfo.isBoostSpell then
		return QuestCompleteSpellType.Ability;
	elseif spellInfo.garrFollowerID then
		local followerInfo = C_Garrison.GetFollowerInfo(spellInfo.garrFollowerID);
		if followerInfo and followerInfo.followerTypeID == Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower then
			return QuestCompleteSpellType.Companion;
		else
			return QuestCompleteSpellType.Follower;
		end
	elseif spellInfo.isSpellLearned then
		return QuestCompleteSpellType.Spell;
	elseif spellInfo.genericUnlock then
		return QuestCompleteSpellType.Unlock;
	end

	return QuestCompleteSpellType.Aura;
end

local function AddSpellToBucket(buckets, spellInfo)
	local subType = GetRewardSpellBucketType(spellInfo);

	if not buckets[subType] then
		buckets[subType] = {};
	end

	tinsert(buckets[subType], spellInfo);
end



local SORT_PRIORITY = {
	SetXP = 1,
	SetMoney = 2,
};

local function SortRewardList(a, b)
	if a.small ~= b.small then
		--small: true > false > nil 
		return b.small
	end

	--if a[1] ~= b[1] then
	--	local p1 = SORT_PRIORITY[a[1]];
	--	local p2 = SORT_PRIORITY[b[1]];
	--	if p1 and p2 then
	--		return p1 < p2
	--	elseif p1 then
	--		return true
	--	elseif p2 then
	--		return false
	--	end
	--end

	if a.order and b.order then
		return a.order < b.order
	elseif a.order then
		return true
	elseif b.order then
		return false
	end

	return a[2] < b[2]
end


local function BuildRewardList(questComplete)
    --Derivative of QuestInfo_ShowRewards in QuestInfo.lua
    local rewardList = {};

	local questID = GetQuestID();   --C_QuestLog.GetSelectedQuest

	local numQuestRewards = 0;
	local numQuestChoices = 0;
	local numQuestCurrencies = 0;
	local money = 0;
	local skillName;
	local skillPoints;
	local skillIcon;
	local xp = 0;
	local artifactXP = 0;
	local artifactCategory;
	local honor = 0;
	local playerTitle;
	local spellRewards = GetQuestRewardSpells(questID) or {};
	local spellRewardBuckets = {};
	local hasWarModeBonus = false;
	local majorFactionRepRewards;

    numQuestRewards = GetNumQuestRewards();
    numQuestChoices = GetNumQuestChoices();
    numQuestCurrencies = GetNumRewardCurrencies(questID);
    money = GetRewardMoney();
    skillName, skillIcon, skillPoints = GetRewardSkillPoints();
    xp = GetRewardXP();
    artifactXP, artifactCategory = GetRewardArtifactXP();
    honor = GetRewardHonor();
    playerTitle = GetRewardTitle();
    hasWarModeBonus = QuestCanHaveWarModeBonus(questID);
    majorFactionRepRewards = GetQuestOfferMajorFactionReputationRewards();

	for index, spellID in ipairs(spellRewards) do
		if spellID and spellID > 0 then
			local spellInfo = GetQuestRewardSpellInfo(questID, spellID);
			local knownSpell = IsSpellKnownOrOverridesKnown(spellID);

			-- only allow the spell reward if user can learn it
			if spellInfo and spellInfo.texture and not knownSpell and (not spellInfo.isBoostSpell or IsCharacterNewlyBoosted()) and (not spellInfo.garrFollowerID or not C_Garrison.IsFollowerCollected(spellInfo.garrFollowerID)) then
				spellInfo.spellID = spellID;
				AddSpellToBucket(spellRewardBuckets, spellInfo);
			end
		end
	end

	local totalRewards = numQuestRewards + numQuestChoices + numQuestCurrencies;
	if ( totalRewards == 0 and money == 0 and xp == 0 and not playerTitle and #spellRewards == 0 and artifactXP == 0 and honor == 0 and not majorFactionRepRewards ) then
		return nil;
	end


    if ( artifactXP > 0 ) then
		local artifactName, icon = C_ArtifactUI.GetArtifactXPRewardTargetInfo(artifactCategory);
	end

	local anyPreviousHeader = false;

	-- Setup spell rewards
	local spellIndex = 100;		--order_spell
	if #spellRewards > 0 then
		for orderIndex, spellBucketType in ipairs(QUEST_INFO_SPELL_REWARD_ORDERING) do
			local spellBucket = spellRewardBuckets[spellBucketType];
			if spellBucket then
				for i, spellInfo in ipairs(spellBucket) do
					local data;
					spellIndex = spellIndex + 1;

					if i == 1 then
						local header = QUEST_INFO_SPELL_REWARD_TO_HEADER[spellBucketType];
						if header then
							anyPreviousHeader = true;
						elseif anyPreviousHeader then
							anyPreviousHeader = false;
							header = REWARD_ITEMS;	--You will also receive
						end
						if header then
							tinsert(rewardList, {header = header, order = spellIndex});
							spellIndex = spellIndex + 1;
						end
					end

					if spellInfo.garrFollowerID then
						local followerInfo = C_Garrison.GetFollowerInfo(spellInfo.garrFollowerID);
						data = {"SetRewardFollower", spellInfo.garrFollowerID};
					else
						local spellIcon = spellInfo.texture;
						local spellName = spellInfo.name;
						local spellID = spellInfo.spellID;
						data = {"SetRewardspell", spellID, spellIcon, spellName, order = spellIndex};
					end

					tinsert(rewardList, data);
				end
			end
		end
	end

	if anyPreviousHeader then
		anyPreviousHeader = false;
		local header = REWARD_ITEMS;	--You will also receive
		if header and totalRewards > 0 then		--totalRewards don't include Spell rewards
			spellIndex = spellIndex + 1;
			tinsert(rewardList, {header = header, order = spellIndex});
		end
	end

	if playerTitle then
		tinsert(rewardList, {"SetRewardTitle", playerTitle, order = 200});
	end

	local hasChanceForQuestSessionBonusReward = QuestHasQuestSessionBonus(questID);  --Party Sync

	if ( numQuestRewards > 0 or numQuestCurrencies > 0 or money > 0 or xp > 0 or honor > 0 or majorFactionRepRewards or hasChanceForQuestSessionBonusReward ) then
		-- Money rewards
		if ( money > 0 ) then
			tinsert(rewardList, {"SetMoney", money, small = true, order = 2});
		end
		-- XP rewards
		if xp > 0 then
			tinsert(rewardList, {"SetXP", xp, small = true, order = 1});
		end
		-- Skill Point rewards
		if skillPoints then
			local skillLineID = GetRewardSkillLineID();
			local order_SkillPoints = 250;
			tinsert(rewardList, {"SetRewardSkill", skillIcon, skillPoints, skillName, skillLineID, order = order_SkillPoints});
		end


		-- Item rewards
		local order_Item = 300;
		for i = 1, numQuestRewards do
            tinsert(rewardList, {"SetRewardItem", i, order = order_Item + i});
		end

		-- currency
		local order_Currency = 400;
		for i = 1, numQuestCurrencies, 1 do
            tinsert(rewardList, {"SetRewardCurrency", i, small = SIMPLIFY_CURRENCY_REWARD, order = order_Currency + i});
		end

		-- Major Faction Reputation Rewards
		local order_Faction = 500;
		if majorFactionRepRewards then
			for i, rewardInfo in ipairs(majorFactionRepRewards) do
                tinsert(rewardList, {"SetMajorFactionReputation", rewardInfo, small = SIMPLIFY_CURRENCY_REWARD, order = order_Faction + i});
			end
		end

		-- warmode bonus
		local order_pvp = 500;
		if hasWarModeBonus and C_PvP.IsWarModeDesired() then
			local bonus = C_PvP.GetWarModeRewardBonus();
			if bonus and bonus > 0 then
				tinsert(rewardList, {"SetWarModeBonus", bonus, order = order_pvp});
			end
		end

        if honor > 0 then
			tinsert(rewardList, {"SetRewardHonor", honor, small = SIMPLIFY_CURRENCY_REWARD, order = order_pvp + 10});
        end

        -- Bonus reward chance for quest sessions
        if hasChanceForQuestSessionBonusReward then
            --QUEST_SESSION_BONUS_LOOT_REWARD_FRAME_TITLE   --"Completing this quest while in Party Sync may reward:"
			--questItem.type = "reward";
			--questItem.objectType = "questSessionBonusReward";

			local QUEST_SESSION_BONUS_REWARD_ITEM_ID = 171305;
			local QUEST_SESSION_BONUS_REWARD_ITEM_COUNT = 1;
        end
	end

	tsort(rewardList, SortRewardList);

	-- Setup choosable rewards
	local chooseItems;

	if numQuestChoices > 0 then
		local sourceType = "choice";
		local onlyChoice = numQuestChoices == 1;

		if onlyChoice then
			--REWARD_ITEMS_ONLY		--You will receive
			--Disaplay as normal rewards
			local lootType = GetQuestItemInfoLootType(sourceType, 1);

			if (lootType == 0) then -- LOOT_LIST_ITEM
				tinsert(rewardList, 1, {"SetRewardChoiceItem", 1, true});
			elseif (lootType == 1) then -- LOOT_LIST_CURRENCY
				tinsert(rewardList, 1, {"SetRewardChoiceCurrency", 1, true});
			end
		else
			local choiceGroup = {};
			choiceGroup.isRewardChoices = true;
			choiceGroup.chooseItems = questComplete;
			choiceGroup.numChoices = numQuestChoices;
			tinsert(rewardList, 1, choiceGroup);
			chooseItems = questComplete;
		end
	end

    return rewardList, chooseItems
end

addon.BuildRewardList = BuildRewardList;

do
    local function Settings_SimplifyCurrencyReward(dbValue)
        SIMPLIFY_CURRENCY_REWARD = dbValue == true or nil;
		addon.DialogueUI:OnSettingsChanged();
    end

    addon.CallbackRegistry:Register("SettingChanged.SimplifyCurrencyReward", Settings_SimplifyCurrencyReward);
end