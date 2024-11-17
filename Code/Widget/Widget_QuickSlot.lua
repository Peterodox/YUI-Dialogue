local _, addon = ...
local API = addon.API;
local L = addon.L;
local WidgetManager = addon.WidgetManager;

local IsPlayingCutscene = API.IsPlayingCutscene;
local GetItemClassification = API.GetItemClassification;
local GetItemCount = C_Item.GetItemCount;

local COUNTDOWN_IDLE = 4;               --When the user doesn't do anything
local COUNTDOWN_COMPLETE_AUTO = 2;      --When the item is auto equipped by game
local COUNTDOWN_COMPLETE_MANUAL = 1;    --When the item is equipped by clicks

local QuickSlotManager = CreateFrame("Frame");
WidgetManager:AddLootMessageProcessor(QuickSlotManager, "ItemLink");


local RewardItemButton;


function QuickSlotManager:ListenLootEvent(state)
    if state then
        self:RegisterEvent("CHAT_MSG_LOOT");
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpate_UnregisterEvents);
    else
        self.t = nil;
        self.pendingItemLink = nil;
        self.itemClassification = nil;
        self:SetScript("OnUpdate", nil);
        self:UnregisterEvent("CHAT_MSG_LOOT");
        self:UnregisterEvent("BAG_UPDATE_DELAYED");
    end
end

function QuickSlotManager:OnEvent(event, ...)
    if event == "CHAT_MSG_LOOT" then
        self:CHAT_MSG_LOOT(...);
    elseif event == "BAG_UPDATE_DELAYED" then
        if self.pendingItemLink and self.itemClassification then
            local success;

            if GetItemCount(self.pendingItemLink) > 0 then
                if self.itemClassification == "equipment" then
                    success = true;
                    self:AddEquipment(self.pendingItemLink);
                end
            end

            if success then
                self:UnregisterEvent(event);
                self.pendingItemLink = nil;
                self.itemClassification = nil;
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:PLAYER_ENTERING_WORLD(...);
    end
end
QuickSlotManager:SetScript("OnEvent", QuickSlotManager.OnEvent);

function QuickSlotManager:OnUpate_UnregisterEvents(elapsed)
    self.t = self.t + elapsed;
    if self.t >= 1.0 then
        self:ListenLootEvent(false);
    end
end

function QuickSlotManager:OnItemLooted(itemLink)
    --Fired after CHAT_MSG_LOOT, but the item may have not been pushed into the bags yet

    if IsPlayingCutscene() then
        return
    end

    local itemClassification = GetItemClassification(itemLink);
    print(itemClassification, itemLink);

    if itemClassification == "equipment" then
        if API.IsItemAnUpgrade_External(itemLink) then
            if GetItemCount(itemLink) > 0 then
                self:AddEquipment(itemLink);
            else
                self:RegisterEvent("BAG_UPDATE_DELAYED");
                self.pendingItemLink = itemLink;
                self.itemClassification = itemClassification;
            end
        end
    end
end

function QuickSlotManager:AddEquipment(itemLink)
    local countDownDuration = COUNTDOWN_IDLE;
    local allowPressKeyToUse = true;

    local button = self:GetItemButton();
    button:SetEquipItem(itemLink, allowPressKeyToUse);
    button:ShowButton();
    if button:IsItemEquipped() then
        countDownDuration = COUNTDOWN_COMPLETE_AUTO;
    end

    if button and button:IsShown() then
        button:SetCountdown(countDownDuration);
    end
end


do
    local MODULE_ENABLED = false;
    local CALLBACK_ADDED = false;

    local CallbackRegistry = addon.CallbackRegistry;

    local function WatchQuestReward(isAutoComplete)
        if MODULE_ENABLED and (not isAutoComplete) then
            QuickSlotManager:ListenLootEvent(true);
        end
    end

    local function Settings_QuickSlotQuestReward(state)
        if state then
            MODULE_ENABLED = true;
            if not CALLBACK_ADDED then
                CALLBACK_ADDED = true;
                CallbackRegistry:Register("TriggerQuestFinished", WatchQuestReward);
            end
        else
            if MODULE_ENABLED then
                MODULE_ENABLED = false;
                QuickSlotManager:ListenLootEvent(false);
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.QuickSlotQuestReward", Settings_QuickSlotQuestReward);
end


local QuestRewardItemButtonMixin = {};
do
    function QuestRewardItemButtonMixin:OnLoad()
        self.CloseButton = addon.WidgetManager:CreateAutoCloseButton(self);
        self.CloseButton:SetPoint("CENTER", self, "TOPRIGHT", -5, -5);
        self.CloseButton:SetInteractable(false);

        API.SetPlayCutsceneCallback(function()
            self:Hide();
        end);

        self.AnimIn = self:CreateAnimationGroup(nil, "DUIGenericPopupAnimationTemplate");

        --Temp Fix for TextureSlice changes
        self.AnimIn:SetScript("OnFinished", function()
            if self.HotkeyFrame then
                API.UpdateTextureSliceScale(self.HotkeyFrame.Background);
            end
        end);
        self.AnimIn:SetScript("OnPlay", function()
            if self.HotkeyFrame then
                self.HotkeyFrame.Background:SetScale(1);
            end
        end);

        self.UpgradeArrow = CreateFrame("Frame", nil, self, "DUIDialogIconFrameTemplate");
        self.UpgradeArrow:Hide();
        self.UpgradeArrow:SetPoint("CENTER", self.Icon, "TOPRIGHT", -4, -4);

        self:SetAllowRightClickToClose(true);
    end

    function QuestRewardItemButtonMixin:OnButtonEnter()
        if self.hyperlink then
            self:RegisterEvent("MODIFIER_STATE_CHANGED");
            local tooltip = GameTooltip;
            tooltip:SetOwner(self, "ANCHOR_NONE");
            tooltip:SetPoint("BOTTOMLEFT", self.Icon, "TOPRIGHT", 0, 0);
            tooltip:SetHyperlink(self.hyperlink);
            tooltip:Show();
        end
        self.CloseButton:PauseAutoCloseTimer(true);
    end

    function QuestRewardItemButtonMixin:OnButtonLeave()
        GameTooltip:Hide();
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self.CloseButton:PauseAutoCloseTimer(false);
    end

    function QuestRewardItemButtonMixin:OnButtonMouseDown(button)

    end

    function QuestRewardItemButtonMixin:OnButtonMouseUp(button)

    end

    function QuestRewardItemButtonMixin:OnCountdownFinished()
        self:FadeOut(0);
        self:UnregisterAllEvents();
    end

    function QuestRewardItemButtonMixin:SetCountdown(second, disableButton)
        self.CloseButton:SetCountdown(second);
        if disableButton then
            self:UnregisterAllEvents();
            self:SetButtonEnabled(false);
        end
    end

    function QuestRewardItemButtonMixin:OnEvent(event, ...)
        if event == "MODIFIER_STATE_CHANGED" then
            if self:IsFocused() then
                self:OnEnter();
            end
        end
    end

    function QuestRewardItemButtonMixin:PlayFlyUpAnimation(state)
        self.AnimIn:Stop();
        if state then
            self.AnimIn:Play();
        end
    end

    function QuestRewardItemButtonMixin:ShowUpgradeIcon(state)
        if state then
            local playAnimation = false;
            self.UpgradeArrow:SetItemIsUpgrade(playAnimation);
            self.UpgradeArrow:Show();
        else
            self.UpgradeArrow:Remove();
        end
    end

    function QuestRewardItemButtonMixin:OnItemEquipped()
        self:ShowUpgradeIcon(false);
        self:SetCountdown(COUNTDOWN_COMPLETE_MANUAL, true);
    end
end


do  --Debug
    --QuickSlotManager:RegisterEvent("PLAYER_ENTERING_WORLD");

    function QuickSlotManager:PLAYER_ENTERING_WORLD()
        C_Timer.After(0.5, function()
            ScriptErrorsFrame:Hide();
        end)

        if false then return end;

        C_Timer.After(2, function()
            local button = self:GetItemButton();
            local itemID = 6070;    --172137 226734 6070
            local itemLink = "item:"..itemID;
            button:SetCountdown(COUNTDOWN_IDLE);
            button:SetEquipItem(itemLink, true);
            button:ShowButton();
            button:PlayFlyUpAnimation(true);
        end)
    end

    function QuickSlotManager:GetItemButton()
        if not RewardItemButton then
            RewardItemButton = API.CreateItemActionButton(nil, QuestRewardItemButtonMixin);
            RewardItemButton:SetFrameStrata("FULLSCREEN_DIALOG");
            RewardItemButton:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 196);
            RewardItemButton:SetIgnoreParentScale(true);
            RewardItemButton:SetIgnoreParentAlpha(true);
        end
        return RewardItemButton
    end
end