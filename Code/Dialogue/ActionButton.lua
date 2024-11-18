local _, addon = ...
local API = addon.API;
local DeviceUtil = addon.DeviceUtil;
local CallbackRegistry = addon.CallbackRegistry;

local CreateFrame = CreateFrame;
local InCombatLockdown = InCombatLockdown;
local SetOverrideBindingClick = SetOverrideBindingClick;
local SetOverrideBindingItem = SetOverrideBindingItem;
local SetOverrideBinding = SetOverrideBinding;
local ClearOverrideBindings = ClearOverrideBindings;
local GetItemNameByID = C_Item.GetItemNameByID;
local GetCVarBool = C_CVar.GetCVarBool;

local SecureButtons = {};               --All SecureButton that were created. Recycle/Share unused buttons unless it was specified not to
local PrivateSecureButtons = {};        --These are the buttons that are not shared with other modules


local function IsActionButtonUseKeyDown()
    return GetCVarBool("ActionButtonUseKeyDown");
end


local SecureButtonContainer = CreateFrame("Frame");
SecureButtonContainer:Hide();
addon.SecureButtonContainer = SecureButtonContainer;

function SecureButtonContainer:CollectButton(button)
    if not InCombatLockdown() then
        button:ClearAllPoints();
        button:Hide();
        button:SetParent(self);
        button:ClearActions();
        button:ClearScripts();
        button.isActive = false;
        if self.hasOverrideBinding and self.ownerActionButton == button then
            self:ClearOverrideBinding();
        end
    end
end

function SecureButtonContainer:ClearOverrideBinding()
    if InCombatLockdown() then
        return
    end

    if self.hasOverrideBinding then
        self.hasOverrideBinding = nil;
        ClearOverrideBindings(self);
    end
end

function SecureButtonContainer:SetPressToUseItem(key, item, ownerActionButton)
    --item: name or link

    if InCombatLockdown() then
        return
    end
    self:ClearOverrideBinding();

    if not item then return false end;

    key = key or DeviceUtil:GetActionKey();
    self.actionKey = key;
    if key then
        self.hasOverrideBinding = true;
        self.ownerActionButton = ownerActionButton;
        SetOverrideBindingItem(self, true, key, item);
    else
        return false
    end

    return true
end

function SecureButtonContainer:SetPressToCommand(key, command, ownerActionButton)
    if InCombatLockdown() then
        return
    end
    self:ClearOverrideBinding();

    key = key or DeviceUtil:GetActionKey();
    self.actionKey = key;
    if key then
        self.hasOverrideBinding = true;
        self.ownerActionButton = ownerActionButton;
        SetOverrideBinding(self, true, key, command);
    else
        return false
    end

    return true
end

function SecureButtonContainer:SetPressToClick(key, objectName, ownerActionButton)
    if InCombatLockdown() then
        return
    end
    self:ClearOverrideBinding();

    key = key or DeviceUtil:GetActionKey();
    self.actionKey = key;
    if key and objectName then
        self.hasOverrideBinding = true;
        self.ownerActionButton = ownerActionButton;
        SetOverrideBindingClick(self, true, key, objectName, "LeftButton");
    else
        return false
    end

    return true
end

SecureButtonContainer:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:ClearOverrideBinding();

        local anyActive = false;
        for i, button in ipairs(SecureButtons) do
            if button.isActive then
                button:Release(true);
                anyActive = true;
            end
        end

        if not anyActive then
            self:UnregisterEvent(event);
        end
    end
end);

function SecureButtonContainer:IsActionKey(key)
    return SecureButtonContainer.hasOverrideBinding and key == SecureButtonContainer.actionKey
end


local function SecureActionButton_OnShow(self)
    self:SetScript("PostClick", self.PostClick);
end

local function SecureActionButton_OnHide(self)
    if self.isActive then
        self:Release();
    end
    if self.onHideCallback then
        self.onHideCallback(self);
    end
end

local SecureButtonMixin = {};

function SecureButtonMixin:Release(dueToCombat)
    SecureButtonContainer:CollectButton(self);

    if dueToCombat and self.onEnterCombatCallback then
        self.onEnterCombatCallback(self);
    end
end

function SecureButtonMixin:ShowDebugHitRect(state)
    if state then
        if not self.debugBG then
            self.debugBG = self:CreateTexture(nil, "BACKGROUND");
            self.debugBG:SetAllPoints(true);
            self.debugBG:SetColorTexture(1, 0, 0, 0.5);
        end
    else
        if self.debugBG then
            self.debugBG:Hide();
        end
    end
end

function SecureButtonMixin:SetMacroText(macroText)
    self:SetAttribute("macrotext", macroText);
    self.macroText = macroText;
end

function SecureButtonMixin:SetTriggerMouseButton(mouseButton, attribute)
    local usedOn;
    if mouseButton == "LeftButton" then
        usedOn = "type1";
    elseif mouseButton == "RightButton" then
        usedOn = "type2";
    else
        usedOn = "type";
    end

    attribute = attribute or "macro";

    if IsActionButtonUseKeyDown() then
        self:RegisterForClicks("LeftButtonDown","RightButtonDown");
    else
        self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    end

    self:SetAttribute(usedOn, attribute);
end

function SecureButtonMixin:SetUseItemByName(itemName, mouseButton)
    if itemName then
        self:SetTriggerMouseButton(mouseButton);
        self:SetMacroText("/use "..itemName);
    end
end

local function IsNameValid(itemName)
    return itemName and itemName ~= ""
end

function SecureButtonMixin:SetUseItemByID(itemID, mouseButton, allowPressKeyToUse, itemName)
    self.itemID = itemID;
    if itemID then
        self:SetTriggerMouseButton(mouseButton);
        self:SetMacroText("/use item:"..itemID);
        if allowPressKeyToUse then
            --[[
            if not IsNameValid(itemName) then
                itemName = GetItemNameByID(itemID);
                if not IsNameValid(itemName) then
                    local callback = function(id)
                        if id == itemID and self:IsShown() and (not InCombatLockdown()) then
                            itemName = GetItemNameByID(itemID);
                            SecureButtonContainer:SetPressToUseItem(nil, itemName, self);
                        end
                    end
                    CallbackRegistry:LoadItem(itemID, callback);
                end
            end
            return SecureButtonContainer:SetPressToUseItem(nil, itemName, self);
            --]]

            return SecureButtonContainer:SetPressToClick(nil, self:GetName(), self);
        end
    end
end

function SecureButtonMixin:SetEquipItem(item, mouseButton, allowPressKeyToUse)
    local itemID;
    if type(item) == "number" then
        itemID = item;
        item = "item:"..itemID;
    else
        itemID = API.GetItemIDFromHyperlink(item);
        item = "item:"..itemID;
    end

    self.itemID = itemID;
    if not itemID then
        return
    end

    self:SetTriggerMouseButton(mouseButton);
    self:SetMacroText("/equip "..item);
    if allowPressKeyToUse then
        return SecureButtonContainer:SetPressToClick(nil, self:GetName(), self);
    end
end

function SecureButtonMixin:ClearActions()
    if self.macroText then
        self.macroText = nil;
        self:SetAttribute("type", nil);
        self:SetAttribute("type1", nil);
        self:SetAttribute("type2", nil);
        self:SetAttribute("macrotext", nil);
    end
    self.onEnterCombat = nil;
end

function SecureButtonMixin:ClearScripts()
    self:SetScript("OnEnter", nil);
    self:SetScript("OnLeave", nil);
    self:SetScript("PostClick", nil);
    self:SetScript("OnMouseDown", nil);
    self:SetScript("OnMouseUp", nil);
    self.PostClickCallback = nil;
end

function SecureButtonMixin:CoverObject(object, expand)
    if not InCombatLockdown() then
        expand = expand or 0;
        self:ClearAllPoints();
        self:SetPoint("TOPLEFT", object, "TOPLEFT", -expand, expand);
        self:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", expand, -expand);
    end
end

function SecureButtonMixin:IsFocused()
    return self:IsShown() and self:IsMouseMotionFocus()
end

function SecureButtonMixin:PostClick(button, down)
    if self.PostClickCallback then
        self:PostClickCallback(button);
    end
    --print(self:GetName(), button, down);  --debug
end

function SecureButtonMixin:SetPostClickCallback(callback)
    self.PostClickCallback = callback;
end

local function CreateSecureActionButton()
    if InCombatLockdown() then return end;

    local index = #SecureButtons + 1;
    local namePrefix = "DUISecureActionButton";

    local button = CreateFrame("Button", namePrefix..index, SecureButtonContainer, "InsecureActionButtonTemplate"); --Perform action outside of combat
    SecureButtons[index] = button;
    button.index = index;
    button.isActive = true;
    addon.API.Mixin(button, SecureButtonMixin);

    button:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp");
    button:SetScript("OnShow", SecureActionButton_OnShow);
    button:SetScript("OnHide", SecureActionButton_OnHide);

    SecureButtonContainer:RegisterEvent("PLAYER_REGEN_DISABLED");
    --SecureButtonContainer:RegisterEvent("PLAYER_REGEN_ENABLED");

    return button
end

local function AcquireSecureActionButton(privateKey)
    if InCombatLockdown() then return end;

    local button;

    if privateKey then
        button = PrivateSecureButtons[privateKey];
        if not button then
            button = CreateSecureActionButton();
            PrivateSecureButtons[privateKey] = button;
        end
    else
        for i, b in ipairs(SecureButtons) do
            if not b:IsShown() then
                b.isActive = true;
                button = b;
                break
            end
        end

        if not button then
            button = CreateSecureActionButton();
        end
    end

    if button then
        SecureButtonContainer:RegisterEvent("PLAYER_REGEN_DISABLED");
        button.isActive = true;
        button:Show();
        button:SetScript("PostClick", button.PostClick);
        return button
    end
end
addon.AcquireSecureActionButton = AcquireSecureActionButton;




--[[
if addon.IsToCVersionEqualOrNewerThan(110000) then
    --TWW: MacroText is banned
    --Update: Unbanned

    function SecureButtonMixin:SetUseItemByName(itemName, mouseButton)
        if itemName then
            self:SetTriggerMouseButton(mouseButton, "item");
            self:SetAttribute("item", itemName);
        end
    end

    function SecureButtonMixin:SetUseItemByID(itemID, mouseButton, itemName)
        if itemID then
            if (not itemName) or itemName == "" then
                itemName = GetItemNameByID(itemID);
            end
            self:SetUseItemByName(itemName, mouseButton);
        end
    end
end
--]]