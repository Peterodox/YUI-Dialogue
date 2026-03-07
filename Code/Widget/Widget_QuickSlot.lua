local _, addon = ...
local API = addon.API;
local L = addon.L;
local WidgetManager = addon.WidgetManager;

local IsPlayingCutscene = API.IsPlayingCutscene;
local GetItemClassification = API.GetItemClassification;
local GetItemCount = C_Item.GetItemCount;
local GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo;

local COUNTDOWN_IDLE = 4;               --When the user doesn't do anything
local COUNTDOWN_COMPLETE_AUTO = 2;      --When the item is auto equipped by game
local COUNTDOWN_COMPLETE_MANUAL = 1;    --When the item is equipped by clicks

local DUPLICATE_SUPPRESS_SECONDS = 5;
local DISMISSED_COOLDOWN_SECONDS = 30;
local DEFERRED_RETRY_INTERVAL = 0.5;
local DEFERRED_MAX_RETRIES = 3;

local DEBUG_QUICKSLOT = false;

local function DebugLog(...)
    if DEBUG_QUICKSLOT then
        print("|cfffe6100[QuickSlot]|r", ...);
    end
end

local QuickSlotManager = CreateFrame("Frame");
addon.QuickSlotManager = QuickSlotManager;
WidgetManager:AddLootMessageProcessor(QuickSlotManager, "ItemLink");


local RewardItemButton;

local function HasItem(item)
    return GetItemCount(item) > 0
end

local SupportedItemTypes = {
    equipment = true,
    container = true,
    cosmetic = true,
    mount = true,
    pet = true,
    toy =  true,
    decor = true,
};

local CandidateFilter = {};
do
    local recent_loot = {};     -- [itemLink] = lastSeenTime
    local recently_handled = {}; -- [itemLink] = lastDismissedOrEquippedTime

    function CandidateFilter:IsRecentLoot(itemLink)
        local lastSeen = recent_loot[itemLink];
        if lastSeen and (GetTime() - lastSeen < DUPLICATE_SUPPRESS_SECONDS) then
            DebugLog("Rejected duplicate:", itemLink);
            return true
        end
        return false
    end

    function CandidateFilter:IsRecentlyHandled(itemLink)
        local lastHandled = recently_handled[itemLink];
        if lastHandled and (GetTime() - lastHandled < DISMISSED_COOLDOWN_SECONDS) then
            DebugLog("Rejected recently handled:", itemLink);
            return true
        end
        return false
    end

    function CandidateFilter:RecordLoot(itemLink)
        recent_loot[itemLink] = GetTime();
    end

    function CandidateFilter:RecordHandled(itemLink)
        recently_handled[itemLink] = GetTime();
    end

    -- Prune stale entries periodically to avoid unbounded growth.
    function CandidateFilter:Prune()
        local now = GetTime();
        for link, t in pairs(recent_loot) do
            if now - t > DUPLICATE_SUPPRESS_SECONDS then
                recent_loot[link] = nil;
            end
        end
        for link, t in pairs(recently_handled) do
            if now - t > DISMISSED_COOLDOWN_SECONDS then
                recently_handled[link] = nil;
            end
        end
    end
end

local HIGH_PRIORITY_TYPES = {
    equipment = true,
    container = true,
};

local COLLECTIBLE_TYPES = {
    toy = true,
    pet = true,
    decor = true,
};

local function IsHighPriority(classification)
    if HIGH_PRIORITY_TYPES[classification] then
        return true
    end
    if COLLECTIBLE_TYPES[classification] and addon.GetDBBool("QuickSlotCollectibleHighPriority") then
        return true
    end
    return false
end

local QueueManager = {};
do
    local highQueue = {};   -- equipment upgrades, containers (+ optionally toys, pets, decor)
    local lowQueue = {};    -- cosmetics, mounts, pets, toys, decor
    local isProcessing = false;

    function QueueManager:Enqueue(itemLink, classification)
        local entry = {
            itemLink = itemLink,
            classification = classification,
            enqueueTime = GetTime(),
        };

        if IsHighPriority(classification) then
            table.insert(highQueue, entry);
            DebugLog("Enqueued HIGH:", classification, itemLink);
        else
            table.insert(lowQueue, entry);
            DebugLog("Enqueued LOW:", classification, itemLink);
        end

        if not isProcessing then
            self:ProcessNext();
        end
    end

    function QueueManager:Peek()
        return highQueue[1] or lowQueue[1]
    end

    function QueueManager:Dequeue()
        if #highQueue > 0 then
            return table.remove(highQueue, 1)
        elseif #lowQueue > 0 then
            return table.remove(lowQueue, 1)
        end
    end

    function QueueManager:IsEmpty()
        return #highQueue == 0 and #lowQueue == 0
    end

    function QueueManager:Clear()
        wipe(highQueue);
        wipe(lowQueue);
        isProcessing = false;
    end

    -- Revalidate: item still in bags, still an upgrade (for equipment), still usable.
    function QueueManager:IsStillEligible(entry)
        if not HasItem(entry.itemLink) then
            DebugLog("Revalidation failed (not in bags):", entry.itemLink);
            return false
        end
        if entry.classification == "equipment" then
            local isUpgrade = API.IsItemAnUpgrade_External(entry.itemLink);
            if not isUpgrade then
                DebugLog("Revalidation failed (no longer upgrade):", entry.itemLink);
                return false
            end
        end
        return true
    end

    function QueueManager:ProcessNext()
        while not self:IsEmpty() do
            local entry = self:Dequeue();
            if entry and self:IsStillEligible(entry) then
                isProcessing = true;
                DebugLog("Showing popup:", entry.classification, entry.itemLink);
                QuickSlotManager:AddItemButtonByType(entry.classification, entry.itemLink);
                return
            else
                DebugLog("Skipped on revalidation:", entry and entry.itemLink or "nil");
            end
        end
        isProcessing = false;
        DebugLog("Queue drained");
    end

    function QueueManager:OnPopupDismissed(itemLink)
        isProcessing = false;
        if itemLink then
            CandidateFilter:RecordHandled(itemLink);
        end
        CandidateFilter:Prune();
        self:ProcessNext();
    end

    function QueueManager:SetProcessing(state)
        isProcessing = state;
    end
end

local DeferredResolver = {};
do
    local pending = {}; -- { itemLink, retryCount, classification }

    function DeferredResolver:Add(itemLink)
        table.insert(pending, {
            itemLink = itemLink,
            retryCount = 0,
            classification = nil,
        });
        DebugLog("Deferred:", itemLink);
        self:EnsureTimer();
    end

    function DeferredResolver:EnsureTimer()
        if not self.timer then
            self.timer = C_Timer.NewTicker(DEFERRED_RETRY_INTERVAL, function()
                self:Resolve();
            end);
        end
    end

    function DeferredResolver:StopTimer()
        if self.timer then
            self.timer:Cancel();
            self.timer = nil;
        end
    end

    function DeferredResolver:Resolve()
        local stillPending = {};

        for _, entry in ipairs(pending) do
            entry.retryCount = entry.retryCount + 1;
            local itemClassification = GetItemClassification(entry.itemLink);
            local shouldAdd = itemClassification and SupportedItemTypes[itemClassification];

            if itemClassification == "equipment" then
                local isUpgrade, isReady = API.IsItemAnUpgrade_External(entry.itemLink);
                if not isReady then
                    shouldAdd = nil; -- still not ready
                else
                    shouldAdd = isUpgrade;
                end
            end

            if shouldAdd then
                local priorityOnly = addon.GetDBBool("QuickSlotPriorityOnly");
                if (not priorityOnly) or IsHighPriority(itemClassification) then
                    DebugLog("Deferred resolved:", itemClassification, entry.itemLink);
                    QueueManager:Enqueue(entry.itemLink, itemClassification);
                end
            elseif entry.retryCount < DEFERRED_MAX_RETRIES and not itemClassification then
                -- Still no classification data; keep retrying
                table.insert(stillPending, entry);
            else
                DebugLog("Deferred dropped after", entry.retryCount, "retries:", entry.itemLink);
            end
        end

        pending = stillPending;
        if #pending == 0 then
            self:StopTimer();
        end
    end

    function DeferredResolver:Clear()
        wipe(pending);
        self:StopTimer();
    end
end

function QuickSlotManager:ListenLootEvent(state)
    if state then
        self:RegisterEvent("CHAT_MSG_LOOT");
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_UnregisterEvents);
    else
        self.t = nil;
        self.pendingItemLink = nil;
        self.pendingClassification = nil;
        self:SetScript("OnUpdate", nil);
        -- Don't unregister CHAT_MSG_LOOT if always-on mode is active
        if not addon.GetDBBool("QuickSlotAlwaysOn") then
            self:UnregisterEvent("CHAT_MSG_LOOT");
        end
        self:UnregisterEvent("BAG_UPDATE_DELAYED");
    end
end

function QuickSlotManager:OnEvent(event, ...)
    if event == "CHAT_MSG_LOOT" then
        self:CHAT_MSG_LOOT(...);
    elseif event == "BAG_UPDATE_DELAYED" then
        if self.pendingItemLink then
            if HasItem(self.pendingItemLink) then
                self:UnregisterEvent(event);

                if self.pendingClassification then
                    QueueManager:Enqueue(self.pendingItemLink, self.pendingClassification);
                else
                    -- Classification was unknown at loot time; try deferred resolution
                    DeferredResolver:Add(self.pendingItemLink);
                end

                self.pendingItemLink = nil;
                self.pendingClassification = nil;
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        if addon.GetDBBool("QuickSlotQuestReward") and addon.GetDBBool("QuickSlotAlwaysOn") then
            self:RegisterEvent("CHAT_MSG_LOOT");
            DebugLog("Always-on loot listener initialized");
        end
    end
end
QuickSlotManager:SetScript("OnEvent", QuickSlotManager.OnEvent);

function QuickSlotManager:OnUpdate_UnregisterEvents(elapsed)
    self.t = self.t + elapsed;
    if self.t >= 1.0 then   --debug Change to infinite so we can test it off vendors
        self:ListenLootEvent(false);
    end
end

function QuickSlotManager:WatchBagItem(itemLink, itemClassification)
    self:RegisterEvent("BAG_UPDATE_DELAYED");
    self.pendingItemLink = itemLink;
    self.pendingClassification = itemClassification;
    if self.t then
        --Extend unregister countdown in case of lags
        self.t = self.t - 1;
    end
end

function QuickSlotManager:AddItemButtonByType(itemClassification, itemLink)
    local success;
    if itemClassification == "equipment" then
        success = true;
        self:AddEquipment(itemLink);
    elseif itemClassification == "cosmetic" then
        success = true;
        self:AddCosmetic(itemLink);
    elseif itemClassification == "container" then
        success = true;
        self:AddContainer(itemLink);
    elseif itemClassification == "mount" then
        success = true;
        self:AddMount(itemLink);
    elseif itemClassification == "pet" then
        success = true;
        self:AddPet(itemLink);
    elseif itemClassification == "toy" then
        success = true;
        self:AddToy(itemLink);
    elseif itemClassification == "decor" then
        success = true;
        self:AddDecor(itemLink);
    end
    return success
end

function QuickSlotManager:OnItemLooted(itemLink)
    --Fired after CHAT_MSG_LOOT, but the item may have not been pushed into the bags yet

    if IsPlayingCutscene() then return end;

    -- Duplicate/cooldown suppression
    if CandidateFilter:IsRecentLoot(itemLink) then return end;
    if CandidateFilter:IsRecentlyHandled(itemLink) then return end;
    CandidateFilter:RecordLoot(itemLink);

    local itemClassification = GetItemClassification(itemLink);
    local shouldAdd = itemClassification and SupportedItemTypes[itemClassification];

    if itemClassification == "equipment" then
        local isUpgrade, isReady = API.IsItemAnUpgrade_External(itemLink);
        if not isReady then
            -- Item data not cached yet; defer evaluation
            if HasItem(itemLink) then
                DeferredResolver:Add(itemLink);
            else
                self:WatchBagItem(itemLink, nil); -- watch for bag arrival, then defer
            end
            return
        end
        shouldAdd = isUpgrade;
    end

    if not shouldAdd then
        DebugLog("Rejected (not eligible):", itemClassification, itemLink);
        return
    end

    -- Priority filtering
    local priorityOnly = addon.GetDBBool("QuickSlotPriorityOnly");
    if priorityOnly and not IsHighPriority(itemClassification) then
        DebugLog("Rejected (low priority suppressed):", itemClassification, itemLink);
        return
    end

    if HasItem(itemLink) then
        QueueManager:Enqueue(itemLink, itemClassification);
    else
        self:WatchBagItem(itemLink, itemClassification);
    end
end

function QuickSlotManager:AddAutoCloseItemButton(itemLink, setupMethod, isActionCompleteMethod)
    local countDownDuration = COUNTDOWN_IDLE;
    local disableButton;
    local allowPressKeyToUse = addon.GetDBBool("QuickSlotUseHotkey");

    local button = self:GetItemButton();
    button.currentItemLink = itemLink;
    button[setupMethod](button, itemLink, allowPressKeyToUse);
    button:ShowButton();
    button.CloseButton:SetInteractable(false);

    if isActionCompleteMethod ~= nil and button[isActionCompleteMethod](button) then
        countDownDuration = COUNTDOWN_COMPLETE_AUTO;
    end

    if button and button:IsShown() then
        button:SetCountdown(countDownDuration, disableButton);
        if disableButton then
            button:PlayFlyUpAnimation(false);
        else
            button:PlayFlyUpAnimation(true);
        end
    end
end

function QuickSlotManager:AddItemButton(itemLink, setupMethod, isActionCompleteMethod)
    local allowPressKeyToUse = addon.GetDBBool("QuickSlotUseHotkey");

    local button = self:GetItemButton();
    button[setupMethod](button, itemLink, allowPressKeyToUse);
    button:ShowButton();
    button.CloseButton:Hide();

    if button and button:IsShown() then
        button.CloseButton:StopCountdown();
        if false then
            button:PlayFlyUpAnimation(false);
        else
            button:PlayFlyUpAnimation(true);
        end
    end
end


do  --Add Button Method
    function QuickSlotManager:AddEquipment(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetEquipItem", "IsItemEquipped");
    end

    function QuickSlotManager:AddContainer(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetUsableItem");
    end

    function QuickSlotManager:AddCosmetic(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetCosmeticItem", "IsKnownCosmetic");
    end

    function QuickSlotManager:AddMount(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetMountItem", "IsKnownMount");
    end

    function QuickSlotManager:AddPet(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetPetItem", "IsKnownPet");
    end

    function QuickSlotManager:AddToy(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetToyItem", "IsKnownToy");
    end

    function QuickSlotManager:AddDecor(itemLink)
        self:AddAutoCloseItemButton(itemLink, "SetDecorItem", "IsKnownDecor");
    end

    function QuickSlotManager:AddUsableItemByID(itemID)
        local itemLink = "|Hitem:"..itemID.."|h";
        self:AddAutoCloseItemButton(itemLink, "SetUsableItem");
    end

    function QuickSlotManager:AddQuestLogSpecialItem(questID)
        local index = API.GetLogIndexForQuestID(questID);
        if index then
            local itemLink, icon, charges = GetQuestLogSpecialItemInfo(index);
            if itemLink then
                self:AddItemButton(itemLink, "SetUsableItem");
                return true
            end
        end
        return false
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
                if RewardItemButton then
                    RewardItemButton:ClearButton();
                end
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.QuickSlotQuestReward", Settings_QuickSlotQuestReward);

    local ALWAYS_ON_ENABLED = false;

    local function Settings_QuickSlotAlwaysOn(state)
        if state and addon.GetDBBool("QuickSlotQuestReward") then
            if not ALWAYS_ON_ENABLED then
                ALWAYS_ON_ENABLED = true;
                QuickSlotManager:RegisterEvent("CHAT_MSG_LOOT");
                DebugLog("Always-on loot listener enabled");
            end
        else
            if ALWAYS_ON_ENABLED then
                ALWAYS_ON_ENABLED = false;
                -- Only unregister if the quest-completion listener isn't active
                if not QuickSlotManager.t then
                    QuickSlotManager:UnregisterEvent("CHAT_MSG_LOOT");
                end
                QueueManager:Clear();
                DeferredResolver:Clear();
                DebugLog("Always-on loot listener disabled");
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.QuickSlotAlwaysOn", Settings_QuickSlotAlwaysOn);

    -- Also re-evaluate when the parent setting changes
    CallbackRegistry:Register("SettingChanged.QuickSlotQuestReward", function(state)
        Settings_QuickSlotAlwaysOn(addon.GetDBBool("QuickSlotAlwaysOn"));
    end);

    -- Initialize on login
    QuickSlotManager:RegisterEvent("PLAYER_ENTERING_WORLD");
end


do  --QuestRewardItemButtonMixin
    local QuestRewardItemButtonMixin = {};

    function QuestRewardItemButtonMixin:OnLoad()
        self.CloseButton = addon.WidgetManager:CreateAutoCloseButton(self);
        self.CloseButton:SetPoint("CENTER", self, "TOPRIGHT", -5, -5);
        self.CloseButton:SetInteractable(false);

        API.SetPlayCutsceneCallback(function()
            self:ClearButton();
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
            local tooltip;
            if UIParent:IsVisible() then
                tooltip = GameTooltip;
                tooltip:SetOwner(self, "ANCHOR_NONE");
                tooltip:SetPoint("BOTTOMLEFT", self.Icon, "TOPRIGHT", 0, 2);
                tooltip:SetHyperlink(self.hyperlink);
                tooltip:Show();
            elseif addon.DialogueUI:IsVisible() then
                addon.RewardTooltipCode:ShowHyperlink(self, self.hyperlink)
            end
        end
        self.CloseButton:PauseAutoCloseTimer(true);
    end

    function QuestRewardItemButtonMixin:OnButtonLeave()
        addon.RewardTooltipCode:OnLeave();
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self.CloseButton:PauseAutoCloseTimer(false);
    end

    function QuestRewardItemButtonMixin:OnButtonMouseDown(button)

    end

    function QuestRewardItemButtonMixin:OnButtonMouseUp(button)

    end

    function QuestRewardItemButtonMixin:OnButtonHide()
        self.CloseButton:StopCountdown();
        self.UpgradeArrow:Hide();
    end

    function QuestRewardItemButtonMixin:OnCountdownFinished()
        local itemLink = self.currentItemLink;
        self.currentItemLink = nil;
        self:FadeOut(0);
        self:UnregisterAllEvents();
        QueueManager:OnPopupDismissed(itemLink);
    end

    function QuestRewardItemButtonMixin:SetCountdown(second, disableButton)
        local hideDirectly;

        if disableButton then
            self:UnregisterAllEvents();
            self:SetButtonEnabled(false);
            if (self.type == "cosmetic" or self.type == "mount" or self.type == "pet" or self.type == "toy" or self.type == "decor") and (UIParent:IsShown()) then
                --No Countdown because WoW has AlertFrame for them
                hideDirectly = true;
            else
                hideDirectly = false;
            end
        else
            hideDirectly = false;
        end

        if hideDirectly then
            local itemLink = self.currentItemLink;
            self.currentItemLink = nil;
            self:ClearButton();
            QueueManager:OnPopupDismissed(itemLink);
            return
        else
            self.CloseButton:SetCountdown(second);
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

    function QuestRewardItemButtonMixin:OnItemKnown()
        self:SetCountdown(COUNTDOWN_COMPLETE_MANUAL, true);
    end


    function QuickSlotManager:GetItemButton()
        if RewardItemButton then
            self:HideItemButton();
        else
            RewardItemButton = API.CreateItemActionButton(nil, QuestRewardItemButtonMixin);
            RewardItemButton:Hide();
            RewardItemButton:SetFrameStrata("FULLSCREEN_DIALOG");
            RewardItemButton:SetPoint("BOTTOM", nil, "BOTTOM", 0, 196);
            RewardItemButton:SetIgnoreParentScale(true);
            RewardItemButton:SetIgnoreParentAlpha(true);
        end
        return RewardItemButton
    end

    function QuickSlotManager:HideItemButton(fadeOut)
        if RewardItemButton then
            if fadeOut then
                RewardItemButton:OnCountdownFinished();
                RewardItemButton:SetInteractable(false);
            else
                local itemLink = RewardItemButton.currentItemLink;
                RewardItemButton.currentItemLink = nil;
                RewardItemButton:ClearButton();
                QueueManager:OnPopupDismissed(itemLink);
            end
        end
    end
end


do  --debug
    --[[
    QuickSlotManager:RegisterEvent("PLAYER_ENTERING_WORLD");

    function QuickSlotManager:PLAYER_ENTERING_WORLD()
        if false then return end;

        local case = "link";   --equipment container cosmetic link

        C_Timer.After(3, function()
            local button = self:GetItemButton();
            local allowPressKeyToUse = true;
            if case == "equipment" then
                local itemID = 6070;    --172137 226734 6070
                local itemLink = "item:"..itemID;
                button:SetCountdown(COUNTDOWN_IDLE);
                button:SetEquipItem(itemLink, allowPressKeyToUse);
            elseif case == "container" then
                local itemID = 227450;
                if GetItemClassification(itemID) == case then
                    button:SetUsableItem(itemID, allowPressKeyToUse);
                else
                    button:ClearButton();
                    return
                end
            elseif case == "cosmetic" then
                local itemID = 209976;
                if GetItemClassification(itemID) == case then
                    button:SetCosmeticItem(itemID, allowPressKeyToUse);
                else
                    button:ClearButton();
                    return
                end

            elseif case == "link" then
                QuickSlotManager:ListenLootEvent(true);
                button:ClearButton();
                button = nil;
                local itemID = 25473;  --213190
                QuickSlotManager:OnItemLooted(string.format("|Hitem:%d|h", itemID));
            end

            if button then
                button:ShowButton();
                button:PlayFlyUpAnimation(true);
            end
        end)
    end
    --]]
end