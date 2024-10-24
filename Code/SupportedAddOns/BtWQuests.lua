-- Show quest chain
-- View current quest in BtWQuest UI

local _, addon = ...
local HeaderWidgetManger = addon.HeaderWidgetManger;

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

function _Test_OpenToQuest(questID)
    local item = BtWQuestsDatabase:GetQuestItem(questID, BtWQuestsCharacters:GetPlayer())
    if item then
        BtWQuestsFrame:SelectCharacter(UnitName("player"), GetRealmName())
        BtWQuestsFrame:SelectItem(item.item)
    end

    local quest = BtWQuestsDatabase:GetQuestByID(questID);
    --[[


    --]]
end

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
    local chainID, link;
    if self.questID then
        local Quest = BtWQuestsDatabase:GetQuestItem(self.questID, BtWQuestsCharacters:GetPlayer());
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
            local name = Chain:GetName();
            local onEnterFunc, onClickFunc;
            if link then
                function onClickFunc()
                    addon.CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
                    BtWQuestsFrame:Show();
                    C_Timer.After(0, function()
                        local scrollTo = nil;   --require Number
                        BtWQuestsFrame:SelectFromLink(link, scrollTo);
                    end)
                end
            end
            HeaderWidgetManger:AddBtWQuestChain(name, onEnterFunc, onClickFunc);
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