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
local LOOT_EVENT_LISTEN_WINDOW = 3;

local Def = {
    PopupOffsetX = 0,   --Popup's default Positon
    PopupOffsetY = 196,
};

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

function QuickSlotManager:ListenLootEvent(state)
    if state then
        self:RegisterEvent("CHAT_MSG_LOOT");
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_UnregisterEvents);
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

            if HasItem(self.pendingItemLink) then
                success = self:AddItemButtonByType(self.itemClassification, self.pendingItemLink);
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

function QuickSlotManager:OnUpdate_UnregisterEvents(elapsed)
    self.t = self.t + elapsed;
    if self.t >= LOOT_EVENT_LISTEN_WINDOW then   --debug Change to infinite so we can test it off vendors
        self:ListenLootEvent(false);
    end
end

function QuickSlotManager:WatchBagItem(itemLink, itemClassification)
    self:RegisterEvent("BAG_UPDATE_DELAYED");
    self.pendingItemLink = itemLink;
    self.itemClassification = itemClassification;
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

    if IsPlayingCutscene() then
        return
    end

    local itemClassification = GetItemClassification(itemLink);
    --print(itemClassification, itemLink);  --debug

    local shouldAddItem = itemClassification and SupportedItemTypes[itemClassification];
    if itemClassification == "equipment" then
        shouldAddItem = API.IsItemAnUpgrade_External(itemLink);
    end

    if shouldAddItem then
        if HasItem(itemLink) then
            self:AddItemButtonByType(itemClassification, itemLink);
        else
            self:WatchBagItem(itemLink, itemClassification);
        end
    end
end

function QuickSlotManager:AddAutoCloseItemButton(itemLink, setupMethod, isActionCompleteMethod)
    local countDownDuration = COUNTDOWN_IDLE;
    local disableButton;
    local allowPressKeyToUse = addon.GetDBBool("QuickSlotUseHotkey");

    local button = self:GetItemButton();
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

    ---@param isAutoComplete boolean `true` if the quest is auto-completed by DUIDialogBaseMixin:HandleQuestComplete()
    local function WatchQuestReward(isAutoComplete)
        -- For isAutoComplete quest, the reward items are first tracked by QuestFlyout.
        -- However, some reward data might not be ready right away, in such case...
        -- QuestFlyout will call this function to track loot events.
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
end


do  --QuestRewardItemButtonMixin
    local QuestRewardItemButtonMixin = {};
    QuestRewardItemButtonMixin.dbkeyPosition = "QuickSlotPosition";

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
            if UIParent:IsVisible() and UIParent:GetAlpha() > 0.9 then
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
        if button == "MiddleButton" then
            -- Reset Popup position
            QuickSlotManager:ResetItemButtonPosition();
        end
    end

    function QuestRewardItemButtonMixin:OnButtonHide()
        self.CloseButton:StopCountdown();
        self.UpgradeArrow:Hide();
    end

    function QuestRewardItemButtonMixin:OnCountdownFinished()
        self:FadeOut(0);
        self:UnregisterAllEvents();
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
            self:ClearButton();
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

    function QuestRewardItemButtonMixin:LoadPosition()
        local pos = addon.GetDBValue(self.dbkeyPosition);
        local x, y;
        local useCustomPosition;

        if pos then
            if type(pos[1]) == "number" and type(pos[2]) == "number" then
                useCustomPosition = true;
                x = pos[1];
                y = pos[2];
            end
        end

        self:ClearAllPoints();

        if useCustomPosition then
            self:SetPoint("CENTER", nil, "BOTTOMLEFT", x, y);
        else
            self:SetPoint("BOTTOM", nil, "BOTTOM", Def.PopupOffsetX, Def.PopupOffsetY);
        end
    end

    function QuestRewardItemButtonMixin:SavePosition()
        self.useCenterAsOrigin = true;
        WidgetManager.WidgetBaseMixin.SavePosition(self);
    end

    function QuestRewardItemButtonMixin:OnDragStart()
        -- Left empty to override original OnDragStart
    end

    function QuestRewardItemButtonMixin:OnDragStop()
        -- Left empty to override original OnDragStop
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
            RewardItemButton:LoadPosition();
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
                RewardItemButton:ClearButton();
            end
        end
    end

    function QuickSlotManager:ResetItemButtonPosition()
        addon.SetDBValue(QuestRewardItemButtonMixin.dbkeyPosition, nil);
        if RewardItemButton then
            RewardItemButton:LoadPosition();
        end
        addon.SettingsUI:RequestUpdate();
    end

    function QuickSlotManager:ToggleEditMode()
        local wasShown = RewardItemButton and RewardItemButton:IsShown();
        local button = self:GetItemButton();
        if wasShown and button.type == "editMode" then
            button:Hide();
        else
            button:SetEditMode();
            button:ShowButton();
            button:PlayFlyUpAnimation(true);
        end
    end

    function QuickSlotManager:IsUsingCustomPosition()
        return addon.GetDBValue(QuestRewardItemButtonMixin.dbkeyPosition) ~= nil;
    end
end


do  --debug
    --[[
    QuickSlotManager:RegisterEvent("PLAYER_ENTERING_WORLD");

    function QuickSlotManager:PLAYER_ENTERING_WORLD()
        if false then return end;

        local case = "equipment";   --equipment container cosmetic link

        C_Timer.After(3, function()
            local button = self:GetItemButton();
            local allowPressKeyToUse = true;
            if case == "equipment" then
                local itemID = 200318;    --172137 226734 6070
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