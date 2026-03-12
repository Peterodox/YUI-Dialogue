local _, addon = ...
local L = addon.L;
local API = addon.API;
local ThemeUtil = addon.ThemeUtil;
local CallbackRegistry = addon.CallbackRegistry;
local Round = API.Round;

local type = type;
local CreateFrame = CreateFrame;
local GetItemCount = C_Item.GetItemCount;
local GetItemCooldown = C_Container.GetItemCooldown;
local GetItemIconByID = C_Item.GetItemIconByID;
local GetItemNameByID = C_Item.GetItemNameByID;
local GetItemQualityByID = C_Item.GetItemQualityByID;
local IsEquippedItem = C_Item.IsEquippedItem;
local PlayerHasTransmogByItemID = (C_TransmogCollection and C_TransmogCollection.PlayerHasTransmog) or API.AlwaysTrue;


local ITEM_TEXT_WIDTH = 192;

local ItemButtonPool = {};

local ItemButtonMixin = {};
do  --Quest Flyout ItemButton
    function ItemButtonMixin:OnEnter()
        if self.enabled then
            self:ShowHighlight(true);
        else
            self:ShowHighlight(false);
        end
        self:OnButtonEnter();
    end

    function ItemButtonMixin:OnLeave()
        self:ShowHighlight(false);
        self:OnButtonLeave();
    end

    function ItemButtonMixin:OnMouseDown(button)
        self:OnButtonMouseDown(button);
    end

    function ItemButtonMixin:OnMouseUp(button)
        self:OnButtonMouseUp(button);
    end

    function ItemButtonMixin:SetAllowRightClickToClose(state)
        self.allowRightClickToClose = state == true;
        if self:IsShown() then
            self:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end
    end

    function ItemButtonMixin:SetIcon(icon)
        self.Icon:SetTexture(icon);
    end

    function ItemButtonMixin:SetButtonText(text)
        self.ButtonText:SetWidth(ITEM_TEXT_WIDTH);
        self.ButtonText:SetText(text);
        self:Layout();
    end

    function ItemButtonMixin:Layout()
        local textPaddingV = 12;
        local textPaddingH = 12;
        local hotkeyFramePadding = 4;
        local buttonWidth = self.textLeftOffset + textPaddingH;

        if self.ButtonText:IsTruncated() then
            buttonWidth = buttonWidth + ITEM_TEXT_WIDTH;
        else
            buttonWidth = buttonWidth + self.ButtonText:GetWrappedWidth();
        end

        self.ButtonText:ClearAllPoints();
        if self.HotkeyFrame and self.HotkeyFrame:IsShown() then
            self.HotkeyFrame:ClearAllPoints();
            self.HotkeyFrame:SetPoint("LEFT", self.TextBackground, "LEFT", self.textLeftOffset, 0);
            self.ButtonText:SetPoint("LEFT", self.HotkeyFrame, "RIGHT", hotkeyFramePadding, 0);
            buttonWidth = buttonWidth + self.HotkeyFrame:GetWidth() + hotkeyFramePadding;
        else
            self.ButtonText:SetPoint("LEFT", self.TextBackground, "LEFT", self.textLeftOffset, 0);
        end

        local buttonHeight = Round(self.ButtonText:GetHeight() + 2 * textPaddingV);
        local minButtonWidth = 3 * buttonHeight;

        if buttonWidth < minButtonWidth then
            buttonWidth = minButtonWidth;
        end
        buttonWidth = Round(buttonWidth);

        local coordLeft = 1 - 0.125 * buttonWidth/buttonHeight;
        if coordLeft < 0 then
            coordLeft = 0;
        end

        self.TextBackground:SetSize(buttonWidth, buttonHeight);
        self.TextBackground:SetTexCoord(coordLeft, 1, (self.colorIndex - 1) * 0.125, self.colorIndex * 0.125);
        self.TextHighlight:SetTexCoord(coordLeft, 1, (self.colorIndex - 1) * 0.125, self.colorIndex * 0.125);

        self:SetWidth(Round(self.iconEffectiveWidth + buttonWidth));
    end

    function ItemButtonMixin:SetItemByID(itemID, name, overrideIcon)
        self.itemID = itemID;
        local icon = overrideIcon or GetItemIconByID(itemID);
        if (not name) or name == "" then
            name = GetItemNameByID(itemID);
            if (not name) or name == "" then
                local callback = function(id)
                    if id == itemID and self:IsShown() then
                        icon = overrideIcon or GetItemIconByID(itemID);
                        name = GetItemNameByID(itemID);
                        self:SetButtonText(name);
                        self:SetIcon(icon);
                    end
                end
                CallbackRegistry:LoadItem(itemID, callback);
            end
        end
        self:SetIcon(icon);
        self:SetButtonText(name);
    end

    function ItemButtonMixin:SetItem(item)
        local itemID;
        if type(item) == "number" then
            self.hyperlink = API.GetItemLinkInBag(item);
            itemID = item;
        else
            self.hyperlink = item;
            itemID = API.GetItemIDFromHyperlink(item);
        end
        local quality = GetItemQualityByID(self.hyperlink or item);
        self:SetColorByQuality(quality);
        self:SetItemByID(itemID);
        self:OnItemSet(itemID);
    end

    function ItemButtonMixin:SetColorIndex(colorIndex)
        --Grey, Green, Blue, Purple, Red, Teal
        --Need to be set before Layout (SetButtonText)
        colorIndex = colorIndex or 5;
        colorIndex = (colorIndex > 6 and 1) or colorIndex;
        self.colorIndex = colorIndex;
        ThemeUtil:SetFontColor(self.ButtonText, "DarkModeGold");
    end

    function ItemButtonMixin:SetColorByQuality(quality)
        local colorIndex;
        if quality == 0 or quality == 1 then
            colorIndex = 1;
        elseif quality == 2 then
            colorIndex = 2;
        elseif quality == 3 or quality == 7 then
            colorIndex = 3;
        elseif quality == 4 then
            colorIndex = 4;
        end
        self:SetColorIndex(colorIndex);
    end

    function ItemButtonMixin:ShowHighlight(state)
        if state then
            self.TextHighlight:Show();
            self.BorderHighlight:Show();
        else
            self.TextHighlight:Hide();
            self.BorderHighlight:Hide();
        end
    end

    function ItemButtonMixin:IsFocused()
        if self.enabled then
            return self:IsMouseMotionFocus() or (self.ActionButton and self.ActionButton:IsFocused())
        else
            return self:IsMouseOver()
        end
    end

    function ItemButtonMixin:SetButtonEnabled(isEnabled)
        self.enabled = isEnabled;
        local colorKey;

        if isEnabled then
            colorKey = "DarkModeGold";
            if self.ActionButton and self.ActionButton:IsFocused() then
                self:ShowHighlight(true);
            else
                self:ShowHighlight(false);
            end
            self.TextBackground:SetDesaturated(false);
            self.IconBorder:SetDesaturated(false);
            self.Icon:SetDesaturated(false);
            self.TextBackground:SetVertexColor(1, 1, 1);
            self.IconBorder:SetVertexColor(1, 1, 1);
            self.Icon:SetVertexColor(1, 1, 1);
            self:EnableMouse(true);
            self:EnableMouseMotion(true);
        else
            colorKey = "DarkModeGrey50";
            self:ShowHighlight(false);
            self.TextBackground:SetDesaturated(true);
            self.IconBorder:SetDesaturated(true);
            self.Icon:SetDesaturated(true);
            local g = 0.6;
            self.TextBackground:SetVertexColor(g, g, g);
            self.IconBorder:SetVertexColor(g, g, g);
            self.Icon:SetVertexColor(g, g, g);
            self:EnableMouse(false);
            self:EnableMouseMotion(false);

            self:ReleaseActionButton();
        end

        ThemeUtil:SetFontColor(self.ButtonText, colorKey);
    end

    function ItemButtonMixin:GetActionButton()
        local ActionButton = addon.AcquireSecureActionButton("QuestRewardItem");
        if ActionButton then
            self.ActionButton = ActionButton;
            ActionButton:SetScript("OnEnter", function()
                self:OnEnter();
            end);
            ActionButton:SetScript("OnLeave", function()
                self:OnLeave();
            end);
            ActionButton:SetPostClickCallback(function(f, button)
                self:OnMouseUp(button);
                if self.PostClick then
                    self:PostClick(button);
                end
            end);
            ActionButton:SetParent(self);
            ActionButton:SetFrameStrata(self:GetFrameStrata());
            ActionButton:SetFrameLevel(self:GetFrameLevel() + 5);
            ActionButton.onEnterCombatCallback = function()
                self:SetButtonEnabled(false);
                self:SetCombatNotice(true);
                if self.UpdatePauseState then
                    self:UpdatePauseState();
                end
            end;
            self:SetButtonEnabled(true);
            self:SetCombatNotice(false);
            return ActionButton
        else
            self:SetButtonEnabled(false);
            if InCombatLockdown() then
                self:SetCombatNotice(true);
            end
        end
    end

    function ItemButtonMixin:ReleaseActionButton()
        if self.ActionButton then
            self.ActionButton:Release();
        end
    end

    function ItemButtonMixin:SetInteractable(state)
        if state then
            self:EnableMouse(true);
            self:EnableMouseMotion(true);
        else
            self:EnableMouse(false);
            self:EnableMouseMotion(false);
            self:ReleaseActionButton();
        end
    end

    function ItemButtonMixin:ShowHotkey(state)
        if state then
            if not self.HotkeyFrame then
                local f = CreateFrame("Frame", nil, self, "DUIDialogHotkeyTemplate");
                self.HotkeyFrame = f;
                f:SetTheme(2);
            end
            self.HotkeyFrame:SetKeyByFunction("Action");
            self.HotkeyFrame:Show();
            self.HotkeyFrame:UseCompactMode();
        else
            if self.HotkeyFrame then
                self.HotkeyFrame:Hide();
            end
        end
    end

    function ItemButtonMixin:HasHotkey()
        return self.HotkeyFrame and self.HotkeyFrame:IsShown()
    end

    function ItemButtonMixin:UpdateItemCount()
        local count = GetItemCount(self.itemID);
        if count > 0 then
            self:SetButtonEnabled(true);
        else
            self:SetButtonEnabled(false);
        end
    end

    function ItemButtonMixin:OnShow()
        if self.allowRightClickToClose then
            self:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end
    end

    function ItemButtonMixin:ShowButton()
        self:SetAlpha(1);
        self:Show();
        self.alpha = 1;
        self.isFadingOut = nil;
        self:SetScript("OnUpdate", nil);
    end

    function ItemButtonMixin:ClearButton()
        self:Hide();
        self:StopAnimating();
        if self.hasData then
            self.hasData = nil;
            self.t = 0;
            self.isFadingOut = nil;
            self.itemID = nil;
            self.hyperlink = nil;
            self:SetScript("OnUpdate", nil);
            self:UnregisterAllEvents();
            self:ReleaseActionButton();
            self:SetCombatNotice(false);
            self:OnButtonHide();
        end
    end

    function ItemButtonMixin:OnUpdate_FadeOut(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0 then
            self.alpha = self.alpha - 4 * elapsed;
            if self.alpha <= 0 then
                self.alpha = 0;
                self:ClearButton();
            else
                self:SetAlpha(self.alpha);
            end
        end
    end

    function ItemButtonMixin:FadeOut(delay)
        delay = delay or 0;
        self.t = -delay;
        self.alpha = self:GetAlpha();
        self.isFadingOut = true;
        self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
    end

    function ItemButtonMixin:SetSuccessText(text)
        self.ButtonText:SetText(text);
        ThemeUtil:SetFontColor(self.ButtonText, "BrightGreen");
    end

    function ItemButtonMixin:SetFailedText(text)
        self.ButtonText:SetText(text);
        ThemeUtil:SetFontColor(self.ButtonText, "WarningRed");
    end

    function ItemButtonMixin:SetCombatNotice(show)
        if show then
            if not self.CombatNoticeText then
                local f = self:CreateFontString(nil, "OVERLAY");
                f:SetFontObject("DUIFont_Tooltip_Small");
                f:SetPoint("TOP", self, "BOTTOM", 0, -4);
                self.CombatNoticeText = f;
            end
            ThemeUtil:SetFontColor(self.CombatNoticeText, "WarningRed");
            self.CombatNoticeText:SetText(L["Popup Usable After Combat"]);
            self.CombatNoticeText:Show();
        elseif self.CombatNoticeText then
            self.CombatNoticeText:Hide();
        end
    end
end


do  --Event Handler, Lazy Update
    function ItemButtonMixin:LazyUpdate(onUpdateFunc, delay)
        if self.isFadingOut then
            return
        end
        delay = delay or 0.033;
        self.delay = delay;
        self.t = 0;
        self:SetScript("OnUpdate", onUpdateFunc);
    end


    --LazyUpdate Bag
    function ItemButtonMixin:UpdateItem()
        local allowPressKeyToUse = self:HasHotkey();
        if self.type == "use" then
            if self.itemID then
                self:SetUsableItem(self.itemID, allowPressKeyToUse);
            else
                self:SetButtonEnabled(false);
            end
        elseif self.type == "equip" then
            if self:IsItemEquipped() then
                self:SetSuccessText(L["Item Equipped"]);
                self:OnItemEquipped();
            else
                self:SetEquipItem(self.hyperlink, allowPressKeyToUse);
            end
        elseif self.type == "cosmetic" then
            if self:IsKnownCosmetic() then
                self:SetButtonEnabled(false);
                self:SetSuccessText(L["Collection Collected"]);
                self:OnItemKnown();
            else
                self:SetCosmeticItem(self.itemID, allowPressKeyToUse);
            end
        elseif self.type == "mount" then
            if self:IsKnownMount() then
                self:SetButtonEnabled(false);
                self:SetSuccessText(L["Collection Collected"]);
                self:OnItemKnown();
            else
                self:SetMountItem(self.itemID, allowPressKeyToUse);
            end
        elseif self.type == "pet" and self.itemID then
            self:SetPetItem(self.itemID, allowPressKeyToUse);
        elseif self.type == "toy" then
            if self:IsKnownToy() then
                self:SetButtonEnabled(false);
                self:SetSuccessText(L["Collection Collected"]);
                self:OnItemKnown();
            else
                self:SetToyItem(self.itemID, allowPressKeyToUse);
            end
        elseif self.type == "decor" then
            if self:IsKnownDecor() then
                self:SetButtonEnabled(false);
                self:SetSuccessText(L["Collection Collected"]);
                self:OnItemKnown();
            else
                self:SetDecorItem(self.itemID, allowPressKeyToUse);
            end
        end
    end

    function ItemButtonMixin:OnUpdate_BagUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > self.delay then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:UpdateItem();
        end
    end

    function ItemButtonMixin:RequestUpdateBag(delay)
        self:LazyUpdate(self.OnUpdate_BagUpdate, delay);
    end


    --Event
    --Events are register based on button type

    function ItemButtonMixin:OnEventBasic(event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            local allowPressKeyToUse = self:HasHotkey();
            if self.type == "use" and self.itemID then
                self:SetUsableItem(self.itemID, allowPressKeyToUse);
            elseif self.type == "equip" and self.hyperlink then
                self:SetEquipItem(self.hyperlink, allowPressKeyToUse);
            elseif self.type == "cosmetic" and self.itemID then
                self:SetCosmeticItem(self.itemID, allowPressKeyToUse);
            elseif self.type == "pet" and self.itemID then
                self:SetPetItem(self.itemID, allowPressKeyToUse);
            elseif self.type == "mount" and self.itemID then
                self:SetMountItem(self.itemID, allowPressKeyToUse);
            elseif self.type == "toy" and self.itemID then
                self:SetToyItem(self.itemID, allowPressKeyToUse);
            elseif self.type == "decor" and self.itemID then
                self:SetDecorItem(self.itemID, allowPressKeyToUse);
            end
            if self.UpdatePauseState then
                self:UpdatePauseState();
            end
        elseif event == "GLOBAL_MOUSE_DOWN" then
            if self.allowRightClickToClose then
                local button = ...
                if button == "RightButton" and self:IsFocused() then
                    self:Hide();
                end
            end
        elseif event == "BAG_UPDATE_DELAYED" then
            self:RequestUpdateBag();
        elseif event == "BAG_UPDATE_COOLDOWN" then
            if self.itemID then
                local startTime, duration, enable = GetItemCooldown(self.itemID);
                if enable == 1 and startTime and startTime > 0 and duration and duration > 0 then
                    self.Cooldown:SetCooldown(startTime, duration);
                    self.Cooldown:Show();
                end
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            local equipmentSlot, isEmpty = ...
            self:RequestUpdateBag();
        elseif event == "TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED" or event == "NEW_MOUNT_ADDED" or event == "NEW_PET_ADDED" or event == "NEW_TOY_ADDED" or event == "NEW_HOUSING_ITEM_ACQUIRED" then
            self:RequestUpdateBag();
        end

        self:OnEvent(event, ...);
    end
end


do  --Actions Types
    function ItemButtonMixin:SetUsableItem(item, allowPressKeyToUse)
        self.hasData = true;
        self.type = "use";

        local ActionButton = self:GetActionButton();
        local nameReady;

        self:ShowHotkey(allowPressKeyToUse);
        self:SetItem(item);

        if ActionButton then
            nameReady = ActionButton:SetUseItemByID(self.itemID, "LeftButton", allowPressKeyToUse);
            ActionButton:CoverObject(self, 4);
        end

        if not nameReady then
            self:RequestUpdateBag(0.2);
        end

        self:RegisterEvent("PLAYER_REGEN_ENABLED");
        self:RegisterEvent("BAG_UPDATE_DELAYED");
        self:RegisterEvent("BAG_UPDATE_COOLDOWN");
        self:SetScript("OnEvent", self.OnEventBasic);
        self:UpdateItemCount();
    end

    function ItemButtonMixin:SetEquipItem(item, allowPressKeyToUse)
        self.hasData = true;
        self.type = "equip";

        self:ShowHotkey(allowPressKeyToUse);
        self:SetItem(item);
        if not self.hyperlink then
            self.hyperlink = API.GetItemLinkInBag(self.itemID);
        end

        self:RegisterEvent("PLAYER_REGEN_ENABLED");
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
        self:RegisterEvent("BAG_UPDATE_DELAYED");
        self:SetScript("OnEvent", self.OnEventBasic);

        local ActionButton = self:GetActionButton();
        if ActionButton then
            ActionButton:SetEquipItem(item, "LeftButton", allowPressKeyToUse);
            ActionButton:CoverObject(self, 4);
        end

        self:UpdateItemCount();

        if self.enabled then
            if self:IsItemEquipped() then
                self:SetButtonEnabled(false);
                self:SetSuccessText(L["Item Equipped"]);
                self:OnItemEquipped();
            end
        end
    end

    function ItemButtonMixin:SetCosmeticItem(item, allowPressKeyToUse)
        self:SetUsableItem(item, allowPressKeyToUse);
        self.type = "cosmetic";
        if self:IsKnownCosmetic() then
            self:SetButtonEnabled(false);
            self:SetSuccessText(L["Collection Collected"]);
            self:OnItemKnown();
        else
            self:RegisterEvent("TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED");
        end
    end

    function ItemButtonMixin:SetMountItem(item, allowPressKeyToUse)
        self:SetUsableItem(item, allowPressKeyToUse);
        self.type = "mount";
        self.mountID = C_MountJournal.GetMountFromItem(self.itemID);
        if self:IsKnownMount() then
            self:SetButtonEnabled(false);
            self:SetSuccessText(L["Collection Collected"]);
            self:OnItemKnown();
        else
            self:RegisterEvent("NEW_MOUNT_ADDED");
        end
    end

    local PET_RARITY_COLORS = {
        [1] = "ff9d9d9d",  --Poor (gray)
        [2] = "ffffffff",  --Common (white)
        [3] = "ff1eff00",  --Uncommon (green)
        [4] = "ff0070dd",  --Rare (blue)
        [5] = "ffa335ee",  --Epic (purple)
        [6] = "ffff8000",  --Legendary (orange)
    };

    --Pet rarity from GetPetStats is 1-indexed; maps to item quality via rarity-1
    local PET_RARITY_TO_QUALITY = { [1] = 0, [2] = 1, [3] = 2, [4] = 3, [5] = 4, [6] = 5 };

    local function GetPetCollectionInfo(itemID)
        if not (C_PetJournal and C_PetJournal.GetPetInfoByItemID) then return end;

        local speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemID));
        if not speciesID or speciesID == 0 then return end;

        local owned, maxOwned = C_PetJournal.GetNumCollectedInfo(speciesID);
        if not owned then return end;

        local qualities = {};
        if owned > 0 then
            local numPets = C_PetJournal.GetNumPets();
            for i = 1, numPets do
                local petID, sid = C_PetJournal.GetPetInfoByIndex(i);
                if sid == speciesID and petID then
                    local _, _, _, _, rarity = C_PetJournal.GetPetStats(petID);
                    if rarity then
                        qualities[#qualities + 1] = rarity;
                    end
                end
            end
            table.sort(qualities);
        end

        return owned, maxOwned, qualities, speciesID;
    end

    local function BuildPetCollectionText(name, owned, maxOwned, qualities)
        local pips = "";
        -- Filled pips for owned qualities
        for _, rarity in ipairs(qualities) do
            local color = PET_RARITY_COLORS[rarity] or "ffffffff";
            pips = pips .. "|c" .. color .. "\226\128\162|r";  --• filled (U+2022)
        end
        -- Empty pips for remaining capacity
        for _ = 1, maxOwned - owned do
            pips = pips .. "|cff666666\226\128\162|r";  --• empty (U+2022)
        end
        if pips ~= "" then
            pips = pips .. " ";
        end
        return string.format("%s  %s%d/%d", name or "", pips, owned, maxOwned);
    end

    function ItemButtonMixin:SetPetItem(item, allowPressKeyToUse)
        self:SetUsableItem(item, allowPressKeyToUse);
        self.type = "pet";

        if self.itemID then
            local owned, maxOwned, qualities, speciesID = GetPetCollectionInfo(self.itemID);
            if owned and maxOwned then
                local name = GetItemNameByID(self.itemID) or "";
                if owned >= maxOwned then
                    --Maxed out on this species
                    self:SetButtonEnabled(false);
                    self:ReleaseActionButton();
                    self:SetButtonText(BuildPetCollectionText(name, owned, maxOwned, qualities));
                    ThemeUtil:SetFontColor(self.ButtonText, "WarningRed");

                    --Use the highest owned quality for the button color
                    local bestRarity = qualities[#qualities];
                    if bestRarity then
                        self:SetColorByQuality(PET_RARITY_TO_QUALITY[bestRarity] or 1);
                    end
                    return;
                elseif owned > 0 then
                    --Has some but not maxed
                    self:SetButtonText(BuildPetCollectionText(name, owned, maxOwned, qualities));

                    --Color the button border by the best owned quality
                    local bestRarity = qualities[#qualities];
                    if bestRarity then
                        self:SetColorByQuality(PET_RARITY_TO_QUALITY[bestRarity] or 1);
                    end
                end
            end
        end

        self:RegisterEvent("NEW_PET_ADDED");
    end

    function ItemButtonMixin:SetToyItem(item, allowPressKeyToUse)
        self:SetUsableItem(item, allowPressKeyToUse);
        self.type = "toy";
        if self:IsKnownToy() then
            self:SetButtonEnabled(false);
            self:SetSuccessText(L["Collection Collected"]);
            self:OnItemKnown();
        else
            self:RegisterEvent("NEW_TOY_ADDED");
        end
    end

    function ItemButtonMixin:SetDecorItem(item, allowPressKeyToUse)
        self:SetUsableItem(item, allowPressKeyToUse);
        self.type = "decor";
        if self:IsKnownToy() then
            self:SetButtonEnabled(false);
            self:SetSuccessText(L["Collection Collected"]);
            self:OnItemKnown();
        else
            self:RegisterEvent("NEW_HOUSING_ITEM_ACQUIRED");
        end
    end
end


do  --Determine if the item is learned/used
    function ItemButtonMixin:IsItemEquipped()
        if self.hyperlink then
            if IsEquippedItem(self.hyperlink) then
                return true
            else
                return false
            end
        end
        return false
    end

    function ItemButtonMixin:IsKnownCosmetic()
        if self.itemID then
            return PlayerHasTransmogByItemID(self.itemID)
        end
    end

    function ItemButtonMixin:IsKnownMount()
        if not self.mountID then
            return true
        end
        local isCollected = select(11, C_MountJournal.GetMountInfoByID(self.mountID));
        return isCollected
    end

    function ItemButtonMixin:IsKnownToy()
        if self.itemID then
            return PlayerHasToy(self.itemID)
        end
    end

    local AddedDecors = {};

    function ItemButtonMixin:IsKnownDecor()
        --Always false during the first inquery because you can collect multiple instances of the same decor
        if self.itemID then
            if AddedDecors[self.itemID] then
                return true
            else
                AddedDecors[self.itemID] = true;
                return false
            end
        end
    end
end


do  --Override
    function ItemButtonMixin:OnEvent(event, ...)
    end

    function ItemButtonMixin:OnButtonEnter()
    end

    function ItemButtonMixin:OnButtonLeave()
    end

    function ItemButtonMixin:OnButtonHide()
    end

    function ItemButtonMixin:OnButtonMouseDown(button)
    end

    function ItemButtonMixin:OnButtonMouseUp(button)
    end

    function ItemButtonMixin:OnItemSet(itemID)
    end

    function ItemButtonMixin:OnItemEquipped()
    end

    function ItemButtonMixin:OnItemKnown()
    end

    function ItemButtonMixin:PostClick(button)
        --We want to clear the override binding when the ActionButton is clicked
        --Instead of waiting for the response of its action like collecting transmog, pet
        if button == "LeftButton" then
            addon.SecureButtonContainer:ClearOverrideBinding();
            if self.HotkeyFrame and self.HotkeyFrame:IsShown() then
                self.HotkeyFrame:Hide();
                self:Layout();
            end
        end
    end
end


local function CreateItemActionButton(parent, additionalMixin)
    local f = CreateFrame("Frame", nil, parent, "DUIItemActionButtonTemplate");
    local texture = "Interface/AddOns/DialogueUI/Art/Theme_Shared/QuestFlyoutButton.png";

    local borderSize = 52;
    local iconSize = 64/96 * borderSize;
    f.iconEffectiveWidth = 64/96 * borderSize;
    f.textLeftOffset = 40/96 * borderSize;

    local textBgLeftOffset = 64/96 * borderSize;
    f.TextBackground:ClearAllPoints();
    f.TextBackground:SetPoint("LEFT", f, "LEFT", textBgLeftOffset, 0);

    f:SetHeight(72/96 * borderSize);

    f.TextBackground:SetTexture(texture);
    f.TextHighlight:SetTexture(texture);

    f.Icon:SetTexCoord(0.0625, 0.9275, 0.0625, 0.9275);
    f.Icon:SetSize(iconSize, iconSize);

    f.IconBorder:SetTexture(texture);
    f.IconBorder:SetTexCoord(416/512, 1, 416/512, 1);
    f.IconBorder:SetSize(borderSize, borderSize);
    f.BorderHighlight:SetTexture(texture);
    f.BorderHighlight:SetTexCoord(416/512, 1, 416/512, 1);
    f.BorderHighlight:SetSize(borderSize, borderSize);

    API.Mixin(f, ItemButtonMixin);
    f:SetScript("OnEnter", f.OnEnter);
    f:SetScript("OnLeave", f.OnLeave);
    f:SetScript("OnMouseDown", f.OnMouseDown);
    f:SetScript("OnMouseUp", f.OnMouseUp);
    f:SetScript("OnShow", f.OnShow);

    f:SetColorIndex(2);

    f:SetIcon(132940);

    if additionalMixin then
        API.Mixin(f, additionalMixin);
        if f.OnLoad then
            f:OnLoad();
        end
    end

    table.insert(ItemButtonPool, f);

    f:SetButtonText("Item Button");
    f:Layout();

    return f
end
API.CreateItemActionButton = CreateItemActionButton;


local function TextSpacingChanged(lineSpacing, paragraphSpacing, baseFontSize)
    --Triggered by DialogueUI.lua after FontSizeChange

    TEXT_SPACING = lineSpacing;
    PARAGRAPH_SPACING = paragraphSpacing;

    local fontSizeMultiplier = baseFontSize / 12;
    if fontSizeMultiplier < 1 then
        fontSizeMultiplier = 1;
    end

    ITEM_TEXT_WIDTH = Round(192 * fontSizeMultiplier);

    for _, object in ipairs(ItemButtonPool) do
        if object:IsShown() then
            object:Layout();
        end
    end
end
CallbackRegistry:Register("TextSpacingChanged", TextSpacingChanged);