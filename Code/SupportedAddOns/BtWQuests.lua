-- Show quest chain
-- View current quest in BtWQuest UI

local _, addon = ...
local L = addon.L;
local HeaderWidgetManger = addon.HeaderWidgetManger;
local TooltipFrame = addon.SharedTooltip;

--[[
    .database:
        LoadChain,
        chain,
        missionList,
        GetChainName,
        questList,
        IsChainActive,
        chainList,

    BtWQuestsFrame:SelectFromLink(link, scrollTo)
--]]

--[[
function _Test_OpenToQuest(questID)
    local item = BtWQuestsDatabase:GetQuestItem(questID, BtWQuestsCharacters:GetPlayer())
    if item then
        BtWQuestsFrame:SelectCharacter(UnitName("player"), GetRealmName())
        BtWQuestsFrame:SelectItem(item.item)
    end

    local quest = BtWQuestsDatabase:GetQuestByID(questID);
end
--]]

local Updater = {};

function Updater:ProcessChain(database, chainID)
    local Chain = database:GetChainByID(chainID);
    if Chain and Chain:GetName() ~= "Unnamed" then
        self.addedChains[chainID] = true;
        database:AddQuestItemsForChain(chainID, false); --arg2 replace
        if Chain.items then
            for _, v in ipairs(Chain.items) do
                if v.type == "chain" and v.embed and v.id then
                    self.addedChains[v.id] = true;
                    local embedChain = database:GetChainByID(v.id);
                    if embedChain and embedChain.items then
                        for _, q in ipairs(embedChain.items) do
                            if q.type == "quest" and q.id ~= nil then
                                self.questXChain[q.id] = chainID;
                                self.questXEmbedChain[q.id] = v.id;
                            end
                        end
                    end
                end
            end
        end
    end
end

function Updater:Init()
    self.Init = nil;
    self.f = CreateFrame("Frame");

    --Add quests from other BtW Modules (older expansions)
    --"You should be fine using AddQuestItemsForChain yourself" -- Breeni

    self.addedChains = {};
    self.questXChain = {};
    self.questXEmbedChain = {};

    hooksecurefunc(BtWQuestsDatabase, "AddChain", function(database, chainID, item)
        if chainID and not self.addedChains[chainID] then
            self:ProcessChain(database, chainID);
        end
    end);

    if BtWQuests.Constant.Chain then
        local type = type;
        local infoType, chainID;
        local database = BtWQuestsDatabase;
        for expansionName, expansionInfo in pairs(BtWQuests.Constant.Chain) do
            if expansionName ~= "TheWarWithin" and type(expansionInfo) == "table" then
                for name, chainInfo in pairs(expansionInfo) do
                    infoType = type(chainInfo);
                    if infoType == "table" then
                        for k, chainID in pairs(chainInfo) do
                            self:ProcessChain(database, chainID);
                        end
                    elseif infoType == "number" then
                        chainID = chainInfo;
                        self:ProcessChain(database, chainID);
                    end
                end
            end
        end
    end
end

local function OnUpdate_LoadQuest(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.0 then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        Updater:LoadQuest();
    end
end

function Updater:SetCurrentQuest(questID, method)
    self.questID = questID;
    self.f.t = 0;
    self.isLoading = true;
    self.f:SetScript("OnUpdate", OnUpdate_LoadQuest);
end

function Updater:LoadQuest()
    self.isLoading = nil;
    local questID = self.questID;
    local chainID, link;
    local isEmbed, embedChainID;

    if questID then
        chainID = self.questXChain[questID];
        if chainID ~= nil then
            isEmbed = true;
        end
        local Quest = BtWQuestsDatabase:GetQuestItem(questID, BtWQuestsCharacters:GetPlayer());
        if Quest then
            if Quest.item and type(Quest.item) == "table" and Quest.item.type == "chain" then
                if isEmbed then
                    embedChainID = Quest.item.id;
                else
                    chainID = Quest.item.id;
                end
            end
            link = Quest.GetLink and Quest:GetLink();
        end
    end

    if chainID then
        local Chain = BtWQuestsDatabase:GetChainByID(chainID);
        if Chain then
            if not link then
                link = Chain:GetLink();
            end
            local chainName = Chain:GetName();
            local onEnterFunc, onClickFunc;
            if not link then
                print("NO LINK")
            end
            if link then
                local embedChainID = self.questXEmbedChain[questID];
                function onEnterFunc(self)
                    if isEmbed then
                        Chain = BtWQuestsDatabase:GetChainByID(embedChainID);
                    end

                    local character = BtWQuestsCharacters:GetPlayer();
                    local item, text;
                    local totalQuest = 0;
                    local hideSpoilers = (BtWQuests_AccountSettings and BtWQuests_AccountSettings.hideSpoilers) or (BtWQuests_Settings and BtWQuests_Settings.hideSpoilers);
                    local numItems = Chain:GetNumItems() or 0;

                    TooltipFrame:SetOwner(self, "ANCHOR_NONE");
                    TooltipFrame:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);

                    if hideSpoilers then
                        local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted;
                        local numCompleted = 0;
                        local n = 0;
                        for i = 1, numItems do
                            item = Chain:GetItem(i, character);
                            if item and item:GetType() == "quest" then
                                n = n + 1;
                                if IsQuestFlaggedCompleted(item:GetID()) then
                                    numCompleted = numCompleted + 1;
                                end
                            end
                        end
                        TooltipFrame:AddLeftLine(chainName, 1, 1, 1, true, 0, 1);
                        TooltipFrame:AddLeftLine(L["Format Your Progress"]:format(numCompleted, n), 1, 0.82, 0, true);
                    else
                        local maxVisible = 10;
                        local fromIndex = 1;
                        local numEntries = 0;

                        for i = 1, numItems do
                            item = Chain:GetItem(i, character);
                            if item and item:GetType() == "quest" then
                                totalQuest = totalQuest + 1;
                                if item:GetID() == questID then
                                    fromIndex = i;
                                    break
                                end
                            end
                        end

                        if totalQuest > maxVisible then
                            fromIndex = math.max(1, fromIndex - 1);
                        else
                            fromIndex = 1;
                        end

                        local n = 0;
                        for i = fromIndex, numItems do
                            item = Chain:GetItem(i, character);
                            if item and item:GetType() == "quest" then
                                numEntries = numEntries + 1;
                                if numEntries > maxVisible then
                                    TooltipFrame:AddLeftLine(L["Format And More"]:format(totalQuest - n), 0.5, 0.5, 0.5, true);
                                    break
                                end
                                text = item:GetName();
                                if text then
                                    n = n + 1;
                                    text = n..". "..text;
                                    if item:GetID() == questID then
                                        TooltipFrame:AddLeftLine(text, 1.0, 1.0, 1.0, true);
                                    else
                                        TooltipFrame:AddLeftLine(text, 0.7, 0.7, 0.7, true);
                                    end
                                end
                            end
                        end
                    end

                    TooltipFrame:AddBlankLine();
                    TooltipFrame:AddLeftLine(L["Click To Open BtWQuests"], 1, 0.82, 0, true);
                    TooltipFrame:Show();
                end

                function onClickFunc()
                    addon.CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
                    BtWQuestsFrame:Show();
                    C_Timer.After(0, function()
                        local scrollTo = nil;   --require Number
                        BtWQuestsFrame:SelectFromLink(link, scrollTo);
                    end)
                end
            end
            HeaderWidgetManger:AddBtWQuestChain(chainName, onEnterFunc, onClickFunc);
            HeaderWidgetManger:LayoutWidgets();
        end
    end
end

local function Updater_StopLoading()
    if Updater.isLoading then
        Updater.isLoading = nil;
        Updater.f:SetScript("OnUpdate", nil);
        Updater.f.t = nil;
    end
end

do
    local ADDON_NAME = "BtWQuests";

    local requiredMethods = {
        "BtWQuestsDatabase.GetQuestItem";
        "BtWQuestsDatabase.GetChainByID",
        "BtWQuestsCharacters.GetPlayer",
        "BtWQuestsDatabase.AddChain",
        "BtWQuestsDatabase.AddQuestItemsForChain",
    };

    local function OnAddOnLoaded()
        local function OnViewingQuest(questID, method)
            Updater:SetCurrentQuest(questID, method);
        end

        Updater:Init();

        local cbr = addon.CallbackRegistry;
        cbr:Register("ViewingQuest", OnViewingQuest);
        cbr:Register("StopViewingQuest", Updater_StopLoading);
        cbr:Register("DialogueUI.Hide", Updater_StopLoading);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end