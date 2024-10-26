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

function Updater:Init()
    self.Init = nil;
    self.f = CreateFrame("Frame");
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
    if questID then
        local Quest = BtWQuestsDatabase:GetQuestItem(questID, BtWQuestsCharacters:GetPlayer());
        if Quest then
            if Quest.item and type(Quest.item) == "table" and Quest.item.type == "chain" then
                chainID = Quest.item.id;
            end
            link = Quest.GetLink and Quest:GetLink();
        end
    end

    if chainID then
        local Chain = BtWQuestsDatabase:GetChainByID(chainID);
        if Chain then
            local chainName = Chain:GetName();
            local onEnterFunc, onClickFunc;
            if link then
                function onEnterFunc(self)
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
                        local fromIndex;
                        local numEntries = 0;

                        for i = 1, numItems do
                            item = Chain:GetItem(i, character);
                            if item and item:GetType() == "quest" then
                                totalQuest = totalQuest + 1;
                                if item:GetID() == questID then
                                    fromIndex = i;
                                end
                            end
                        end
                        fromIndex = math.max(1, fromIndex - 1);

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