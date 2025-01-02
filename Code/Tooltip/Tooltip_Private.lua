-- This tooltip is used within our UI

local _, addon = ...
local API = addon.API;
local L = addon.L;
local CallbackRegistry = addon.CallbackRegistry;
local GetItemQualityColor = API.GetItemQualityColor;
local IsItemValidForComparison = API.IsItemValidForComparison;
local GetTransmogItemInfo = API.GetTransmogItemInfo;
local IsEncounterComplete = C_RaidLocks and C_RaidLocks.IsEncounterComplete or API.AlwaysFalse;
local C_TooltipInfo = addon.TooltipAPI;
local C_TransmogCollection = C_TransmogCollection;
local IsDressableItemByID = C_Item.IsDressableItemByID;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;

local SharedTooltip = addon.CreateTooltipBase();
addon.SharedTooltip = SharedTooltip;


--local LINE_TYPE_PRICE = Enum.TooltipDataLineType.SellPrice or 11;
local SELL_PRICE_TEXT = (SELL_PRICE or "Sell Price").."  ";
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR;


local TOOLTIP_PADDING = 12;
local MODEL_WIDTH, MODEL_HEIGHT = 78, 104;

local HOTKEY_ALTERNATE_MODE = "Shift";

local unpack = unpack;
local pairs = pairs;
local format = string.format;


local DualModelMixin = {};
do
    local PI2 = math.floor(1000*math.pi*2)/1000;
    local Model_ApplyUICamera = Model_ApplyUICamera;

    local function PreviewModel_OnModelLoaded(self)
        if self.cameraID then
            Model_ApplyUICamera(self, self.cameraID);
        end
        self.parent:SyncAnimation();
    end

    local function PreviewModel_Turntable_OnUpdate(self, elapsed)
        self.yaw = self.yaw + elapsed * PI2 * 0.1;
        if self.yaw > PI2 then
            self.yaw = self.yaw - PI2;
        end
        self:SetFacing(self.yaw);
    end

    function DualModelMixin:Init(parent)
        local model = CreateFrame("DressUpModel", nil, parent);
        self.Model1 = model;
        model.parent = self;

        API.SetModelLight(model, true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);
        model:SetKeepModelOnHide(true);
        model:SetModelDrawLayer("ARTWORK");
        model:SetAutoDress(false);
        model:SetDoBlend(false);
        model:SetScript("OnModelLoaded", PreviewModel_OnModelLoaded);

        local modelShadow = CreateFrame("DressUpModel", nil, parent);
        self.Model2 = modelShadow;
        modelShadow.parent = self;

        API.SetModelLight(modelShadow, false);
        modelShadow:SetPoint("CENTER", model, "CENTER", 4, -4);
        modelShadow:SetKeepModelOnHide(true);
        modelShadow:SetModelDrawLayer("BORDER");
        modelShadow:SetAutoDress(false);
        modelShadow:SetDoBlend(false);
        modelShadow:SetScript("OnModelLoaded", PreviewModel_OnModelLoaded);

        local a = 0;
        modelShadow:SetFogColor(a, a, a);
        modelShadow:SetParticlesEnabled(false);

        --local inset = 12;
        --model:SetViewInsets(inset, inset, inset, inset);  --Push model farther
        --modelShadow:SetViewInsets(inset, inset, inset, inset);
    end

    function DualModelMixin:SetModelSize(width, height)
        self.width, self.height = width, height;
        self.Model1:SetSize(width, height);
        self.Model2:SetSize(width, height);
    end

    function DualModelMixin:GetWidth()
        return self.width
    end

    function DualModelMixin:SetAnimation(animID)
        self.animID = animID;
        self:SyncAnimation();
    end

    function DualModelMixin:SyncAnimation()
        if self.animID then
            self.Model1:SetAnimation(self.animID, 0);
            self.Model2:SetAnimation(self.animID, 0);
        end
    end

    function DualModelMixin:UseModelCenterToTransform(state)
        self.Model1:UseModelCenterToTransform(state);
        self.Model2:UseModelCenterToTransform(state);
    end

    function DualModelMixin:SetPoint(point, relativeTo, relativePoint, x, y)
        self.point = point;
        self.relativeTo = relativeTo;
        self.relativePoint = relativePoint;
        self.x = x;
        self.y = y;
        self.Model1:SetPoint(point, relativeTo, relativePoint, x, y);
    end

    function DualModelMixin:SetOffsetY(ratio)
        local y = self.height * ratio;
        self.y = y;
        self:SetPoint(self.point, self.relativeTo, self.relativePoint, self.x, y);
    end

    function DualModelMixin:ClearModel()
        if self.hasModel then
            self.hasModel = false;
            self.Model1:ClearModel();
            self.Model2:ClearModel();
        end
    end

    function DualModelMixin:SetCameraID(cameraID)
        self.Model1.cameraID = cameraID;
        self.Model2.cameraID = cameraID;
    end

    function DualModelMixin:ResetPosition()
        self.Model1:SetPosition(0, 0, 0);
        self.Model1:SetPitch(0);
        self.Model1:SetRoll(0);
        self.Model2:SetPosition(0, 0, 0);
        self.Model2:SetPitch(0);
        self.Model2:SetRoll(0);
    end

    function DualModelMixin:SetYaw(yaw)
        self.Model1:SetFacing(yaw);
        self.Model2:SetFacing(yaw);
    end

    function DualModelMixin:SetDisplayInfo(creatureDisplayID)
        self.Model1:SetDisplayInfo(creatureDisplayID);
        self.Model2:SetDisplayInfo(creatureDisplayID);
    end

    function DualModelMixin:SetModelByUnit(unit)
        API.SetModelByUnit(self.Model1, unit);
        API.SetModelByUnit(self.Model2, unit);
    end

    function DualModelMixin:SetItem(item)
        self.Model1:SetItem(item);
        self.Model2:SetItem(item);
    end

    function DualModelMixin:FreezeAnimation(animID, variation, frame)
        self.Model1:FreezeAnimation(animID, variation, frame);
        self.Model2:FreezeAnimation(animID, variation, frame);
    end

    function DualModelMixin:TryOn(item)
        self.Model1:TryOn(item);
        self.Model2:TryOn(item);
    end

    function DualModelMixin:SetUseTransmogChoices(state)
        self.Model1:SetUseTransmogChoices(state);
        self.Model2:SetUseTransmogChoices(state);

        self.Model1:SetUseTransmogSkin(state);
        self.Model2:SetUseTransmogSkin(state);
    end

    function DualModelMixin:SetUseTurntable(useTurntable)
        if useTurntable then
            self.Model1.yaw = -0.78;
            self.Model1:SetScript("OnUpdate", PreviewModel_Turntable_OnUpdate);
            self.Model2.yaw = -0.78;
            self.Model2:SetScript("OnUpdate", PreviewModel_Turntable_OnUpdate);
        else
            self.Model1:SetScript("OnUpdate", nil);
            self.Model2:SetScript("OnUpdate", nil);
            self.Model1.yaw = 0;
            self.Model2.yaw = 0;
        end
    end

    function DualModelMixin:SetModelAlpha(alpha)
        self.Model1:SetModelAlpha(alpha);
        self.Model2:SetModelAlpha(0.8 * alpha);
    end

    function DualModelMixin:SetUseParentLevel(parent, containerFrame)
        local level = parent:GetFrameLevel();
        local strata = parent:GetFrameStrata();

        if containerFrame then
            containerFrame:SetFrameStrata(strata);
            containerFrame:SetFrameLevel(level);
        end

        self.Model1:SetFrameStrata(strata);
        self.Model1:SetFrameLevel(level);
        self.Model2:SetFrameStrata(strata);
        self.Model2:SetFrameLevel(level);
    end
end

function SharedTooltip:Init()
    if not self.PreviewFrame then
        self.PreviewFrame = CreateFrame("Frame", nil, self);
        self.PreviewFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", -TOOLTIP_PADDING, -TOOLTIP_PADDING);
        self.PreviewFrame:Hide();

        self.modelWidth, self.modelHeight = MODEL_WIDTH, MODEL_HEIGHT;
        self.PreviewFrame:SetSize(MODEL_WIDTH, MODEL_HEIGHT);

        self.DualModel = API.CreateFromMixins(DualModelMixin);
        self.DualModel:Init(self.PreviewFrame);
        self.DualModel:SetModelSize(MODEL_WIDTH, MODEL_HEIGHT);
        self.DualModel:SetPoint("TOPRIGHT", self, "TOPRIGHT", -TOOLTIP_PADDING, 0.33*MODEL_HEIGHT);

        self.DualModel:SetUseParentLevel(self, self.PreviewFrame);
    end

    self:InitFrame();
    self.Init = nil;
    self.InitFrame = nil;
end

function SharedTooltip:GetHyperlink()
    return self.hyperlink
end

function SharedTooltip:GetItemID()
    if self.hyperlink then
        return GetItemInfoInstant(self.hyperlink)
    end
end

do
    function SharedTooltip:DisplayModel()
        local itemID = self:GetItemID();
        local usePreview;

        if itemID then
            local DualModel = self.DualModel;
            local useTurntable;

            if IsDressableItemByID(itemID) then
                usePreview = true;

                local appearanceID, sourceID = GetTransmogItemInfo(itemID);

                if appearanceID then
                    if API.IsHoldableItem(itemID) then  --Weapons
                        local cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(sourceID);

                        DualModel:SetCameraID(cameraID);
                        DualModel:SetItem(itemID, sourceID);
                    else    --Armor
                        local cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(sourceID);

                        local useTransmogSkin, setupGear = API.GetTransmogSetup(itemID);
                        DualModel:SetUseTransmogChoices(useTransmogSkin);
                        DualModel:SetCameraID(cameraID);
                        DualModel:SetModelByUnit("player");
                        DualModel:FreezeAnimation(0, 0, 0);
                        DualModel:TryOn(sourceID);

                        if setupGear then
                            for _, v in ipairs(setupGear) do
                                DualModel:TryOn(v);
                            end
                        end
                    end
                else    --Transmog Set
                    useTurntable = true;
                    local detailsCameraID, vendorCameraID = C_TransmogSets.GetCameraIDs()

                    DualModel:SetCameraID(vendorCameraID);
                    DualModel:SetModelByUnit("player");
                    DualModel:FreezeAnimation(0, 0, 0);
                    DualModel:TryOn("item:"..itemID);
                end
                DualModel:SetModelSize(MODEL_WIDTH, MODEL_HEIGHT);
                DualModel:SetOffsetY(0.33);
            else
                local mountID = C_MountJournal.GetMountFromItem(itemID);
                local displayID;

                if mountID then
                    usePreview = true;
                    local creatureDisplayID, description, _, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID);
                    displayID = creatureDisplayID;
                    if isSelfMount then
                        DualModel:SetAnimation(618);
                    else
                        DualModel:SetAnimation(0);
                    end
                else
                    local _, _, _, creatureID, _, description, _, _, _, _, _, creatureDisplayID, speciesID = C_PetJournal.GetPetInfoByItemID(itemID);
                    if creatureDisplayID then
                        displayID = creatureDisplayID;
                        usePreview = true;
                        DualModel:SetAnimation(0);

                    else

                    end
                end

                if displayID then
                    useTurntable = true;
                    DualModel:ClearModel();
                    DualModel:SetCameraID(nil);
                    DualModel:UseModelCenterToTransform(false);
                    DualModel:SetModelSize(MODEL_HEIGHT, MODEL_HEIGHT); --Square
                    DualModel:ResetPosition();
                    DualModel:SetDisplayInfo(displayID);
                    DualModel:SetOffsetY(0.5);
                    --DualModel:SetYaw(0.44);
                end
            end

            DualModel:SetUseTurntable(useTurntable);
        end

        if usePreview then
            self.usePreviewModel = true;
            self.PreviewFrame:Show();
        else
            self.usePreviewModel = false;
            self.PreviewFrame:Hide();
        end
    end

    if not (IsDressableItemByID and C_PetJournal and C_PetJournal.GetPetInfoByItemID) then
        function SharedTooltip:DisplayModel()
        end
    end
end

function SharedTooltip:ShowHotkey(key, description, callback)
    if not self.HotkeyFrame then
        self.HotkeyFrame = CreateFrame("Frame", nil, self, "DUIDialogHotkeyTemplate");
    end

    local success = self.HotkeyFrame:SetKey(key);
    if success then
        self:AddBlankLine();
        local gap = 4;
        local width = self.HotkeyFrame:GetWidth();
        local fontString = self:AddLeftLine(description, 0.5, 0.5, 0.5, true, nil, 2, width + gap);
        self.HotkeyFrame:ClearAllPoints();
        self.HotkeyFrame:SetPoint("RIGHT", fontString, "LEFT", -gap, 0);
        self.HotkeyFrame:Show();
        self.hasHotkey = true;
        self:RegisterEvent("MODIFIER_STATE_CHANGED");
    else
        self.hasHotkey = false;
    end

    self.onHotkeyPressedCallback = callback;
end

function SharedTooltip:ToggleAlternateInfo()
    if self.onHotkeyPressedCallback then
        self.onHotkeyPressedCallback(self);
    end
end

function SharedTooltip:ProcessItemExternal(item)
    --for Pawn
end

local function AlternateModeCallback_ItemComparison(self)
    DialogueUI_DB.TooltipShowItemComparison = not DialogueUI_DB.TooltipShowItemComparison;

    SharedTooltip:ReprocessInfo();
end

do
    function SharedTooltip:AddDeltaToItemLevel(rewardItem)
        local maxDelta, isReady = API.GetMaxEquippedItemLevelDelta(rewardItem);
        if maxDelta and isReady then
            if maxDelta >= -13 then
                local lineText = self:GetLeftLineText(2);
                if string.find(lineText, L["Item Level"]) then
                    local deltaText;
                    if maxDelta > 0 then
                        deltaText = "|cff808080(|r|cff19ff19+"..maxDelta.."|r|cff808080)|r";   --(+1)
                    else
                        if maxDelta == 0 then
                            maxDelta = "";
                        else
                            maxDelta = -maxDelta;
                        end
                        deltaText = "|cff808080(-"..maxDelta..")|r";   --(-1)
                    end
                    self:OverwriteLeftLineText(2, lineText.."  "..deltaText);
                end
            end
        end
    end

    if C_TooltipComparison and C_TooltipComparison.GetItemComparisonInfo and TooltipComparisonManager then
        function SharedTooltip:AddComparisonItems(shouldShowComparison, comparisonItem, rewardItem, equippedItem)
            --Item = { guid = "" }
            if equippedItem and equippedItem.guid then
                local delta = C_TooltipComparison.GetItemComparisonDelta(comparisonItem, equippedItem);
                local itemGUID = equippedItem.guid;
                if delta and itemGUID then
                    if not shouldShowComparison then
                        return true
                    end
                    self:AddBlankLine();

                    local equippedItemLink =  C_Item.GetItemLinkByGUID(itemGUID);
                    if equippedItemLink then
                        self:AddLeftLine(L["Format Replace Item"]:format(equippedItemLink), 1, 0.82, 0, true);
                    else
                        self:AddLeftLine(ITEM_DELTA_DESCRIPTION, 1, 0.82, 0, true);
                    end

                    local itemLevelDelta = API.GetItemLevelDelta(rewardItem, equippedItemLink, true);
                    if itemLevelDelta then
                        self:AddLeftLine(itemLevelDelta, 1, 1, 1, false, nil, 2, TOOLTIP_PADDING);
                    end

                    if #delta > 0 then
                        for i, deltaLine in ipairs(delta) do
                            self:AddLeftLine(deltaLine, 1, 1, 1, false, nil, 2, TOOLTIP_PADDING);
                        end
                    else
                        self:AddLeftLine(L["Identical Stats"], 1, 0.82, 0, false, nil, 2, TOOLTIP_PADDING);
                    end

                    local effectText, cached = API.GetItemEffect(equippedItemLink);
                    if not cached then
                        C_Timer.After(0.25, function()
                            self:ReTriggerOnEnter();
                        end);
                    end
                    if effectText then
                        local offset = nil; --TOOLTIP_PADDING
                        self:AddLeftLine(effectText, 0, 1, 0, false, nil, 2, offset);
                    end

                    return true
                end
            end

            return false
        end

        function SharedTooltip:ShowItemComparison()
            local rewardItem = self:GetHyperlink();
            if not IsItemValidForComparison(rewardItem) then return end;

            local shouldShowComparison = DialogueUI_DB.TooltipShowItemComparison == true;
            local canCompare = false;

            local comparisonItem = TooltipComparisonManager:CreateComparisonItem(self.tooltipData);                 --Mouse-over item: Quest Reward
            local compairsonInfo = comparisonItem and C_TooltipComparison.GetItemComparisonInfo(comparisonItem);

            if compairsonInfo then
                local method = compairsonInfo.method;
                local isPairedItem = method == 2 or method == 3; --.WithBagMainHandItem or comparisonMethod == Enum.TooltipComparisonMethod.WithBagOffHandItem;
                canCompare = self:AddComparisonItems(shouldShowComparison, comparisonItem, rewardItem, compairsonInfo.item);
                if (not isPairedItem) and compairsonInfo.additionalItems and #compairsonInfo.additionalItems >= 1 then
                    self:AddComparisonItems(shouldShowComparison, comparisonItem, rewardItem, compairsonInfo.additionalItems[1]);
                end
            end

            self:ProcessItemExternal(rewardItem);

            if not shouldShowComparison then
                self:AddDeltaToItemLevel(rewardItem);
            end

            if canCompare then
                local description = shouldShowComparison and L["Hide Comparison"] or L["Show Comparison"];
                self:ShowHotkey(HOTKEY_ALTERNATE_MODE, description, AlternateModeCallback_ItemComparison);
                self:Show();
            end
        end
    else    --Classic
        function SharedTooltip:ShowItemComparison()
            local rewardItem = self:GetHyperlink();
            if not IsItemValidForComparison(rewardItem) then return end;

            local shouldShowComparison = DialogueUI_DB.TooltipShowItemComparison == true;
            local canCompare = false;

            local compairsonInfo, areItemsSameType = API.GetItemComparisonInfo(rewardItem);

            if compairsonInfo then
                canCompare = true;
                if shouldShowComparison then
                    local requery = false;
                    for _, info in ipairs(compairsonInfo) do
                        self:AddBlankLine();
                        self:AddLeftLine(L["Format Replace Item"]:format(info.equippedItemLink), 1, 0.82, 0, true);

                        if not areItemsSameType then
                            self:AddLeftLine(L["Different Item Types Alert"], 1.000, 0.125, 0.125, true);   --TODO: this red on the Dark theme doesn't look comforting.
                        end

                        if #info.deltaStats > 0 then
                            for i, deltaLine in ipairs(info.deltaStats) do
                                self:AddLeftLine(deltaLine, 1, 1, 1, false, nil, 2, TOOLTIP_PADDING);
                            end
                        else
                            self:AddLeftLine(L["Identical Stats"], 1, 0.82, 0, false, nil, 2, TOOLTIP_PADDING);
                        end

                        local effectText, cached = API.GetItemEffect(info.equippedItemLink);
                        if not cached then
                            if not requery then
                                requery = true;
                                C_Timer.After(0.25, function()
                                    self:ReTriggerOnEnter();
                                end);
                            end
                        end
                        if effectText then
                            local offset = nil; --TOOLTIP_PADDING
                            self:AddLeftLine(effectText, 0, 1, 0, false, nil, 2, offset);
                        end
                    end
                end
            end

            self:ProcessItemExternal(rewardItem);

            if not shouldShowComparison then
                self:AddDeltaToItemLevel(rewardItem);
            end

            if canCompare then
                local description = shouldShowComparison and L["Hide Comparison"] or L["Show Comparison"];
                self:ShowHotkey(HOTKEY_ALTERNATE_MODE, description, AlternateModeCallback_ItemComparison);
                self:Show();
            end
        end
    end
end

function SharedTooltip:ProcessInfo(info)
    self.tooltipInfo = info;
    self.getterName = info.getterName;

    if not info then
		return false
	end

    local tooltipData;
    if info.getterArgs then
        tooltipData = C_TooltipInfo[info.getterName](unpack(info.getterArgs));
    else
        tooltipData = C_TooltipInfo[info.getterName]();
    end

    self:ClearLines();
    self:SetScript("OnUpdate", nil);

    if tooltipData then
        tooltipData.isItem = info.isItem;
        tooltipData.isSpell = info.isSpell;
    end

    local success = self:ProcessTooltipData(tooltipData);

    if success then
        self:Show();
    else
        self:Hide();
    end
end

function SharedTooltip:ReprocessInfo()
    if self.tooltipData then
        self:ClearLines();
        self:ProcessTooltipData(self.tooltipData);
        self:Show();
    end
end

local OVERRIDE_COLORS = {
    ["ffa335ee"] = 4,
    ["ff0070dd"] = 3,
};

function SharedTooltip:ProcessTooltipDataLines(tooltipDataLines, startingIndex)
    local leftText, leftColor, wrapText, rightText, rightColor;
    local r, g, b;
    startingIndex = startingIndex or self:NumLines() or 1;

    for i, lineData in ipairs(tooltipDataLines) do
        leftText = lineData.leftText;
        leftColor = lineData.leftColor or NORMAL_FONT_COLOR;
        rightText = lineData.rightText;
        wrapText = lineData.wrapText or false;

        if leftText then
            if leftText == " "then
                --A whole blank line is too tall, so we change its height
                self:AddBlankLine();
            else
                if i == startingIndex then
                    local hex = leftColor:GenerateHexColor();
                    if OVERRIDE_COLORS[hex] then
                        leftColor = GetItemQualityColor( OVERRIDE_COLORS[hex] );
                    end
                end

                if lineData.price and lineData.price > 0 then
                    local colorized = true;
                    local cointText = API.GenerateMoneyText(lineData.price, colorized);
                    if cointText then
                        leftText = SELL_PRICE_TEXT .. cointText;
                        --self:AddBlankLine();
                        self:AddLeftLine(leftText, 1, 1, 1, false, nil, 2);
                    end
                else    --lineData.type ~= LINE_TYPE_PRICE
                    r, g, b = leftColor:GetRGB();
                    self:AddLeftLine(leftText, r, g, b, wrapText, nil, (i == 1 and i == startingIndex and 1) or 2);
                end

                if rightText then
                    rightColor = lineData.rightColor or NORMAL_FONT_COLOR;
                    r, g, b = rightColor:GetRGB();
                    self:AddRightLine(rightText, r, g, b, wrapText, nil, 2);
                end
            end
        end
	end
end

function SharedTooltip:ProcessTooltipData(tooltipData)
    if not (tooltipData and tooltipData.lines) then
        self.tooltipData = nil;
        return false
    end

    self.tooltipData = tooltipData;
    self.dataInstanceID = tooltipData.dataInstanceID;
    self.hyperlink = tooltipData.hyperlink;

    self:RegisterEvent("TOOLTIP_DATA_UPDATE");
    self:ProcessTooltipDataLines(tooltipData.lines, 1);

    if tooltipData.isItem then
        self:ShowItemComparison();
        CallbackRegistry:TriggerOnNextUpdate("SharedTooltip.SetItem", self, self:GetItemID(), self:GetHyperlink());
    elseif tooltipData.isSpell then
        CallbackRegistry:TriggerOnNextUpdate("SharedTooltip.SetSpell", self, self.tooltipData and self.tooltipData.id or nil);
    end

    return true
end

function SharedTooltip:OnEvent(event, ...)
	if event == "TOOLTIP_DATA_UPDATE" then
		local dataInstanceID = ...
		if dataInstanceID and dataInstanceID == self.dataInstanceID then
            self.triggeredByEvent = true;
			self:ProcessInfo(self.tooltipInfo);
		end
    elseif event == "MODIFIER_STATE_CHANGED" then
        local key, down = ...
        if key == "LSHIFT" and down == 1 then
            self:ToggleAlternateInfo();
        end
    elseif event == "UPDATE_INSTANCE_INFO" then
        if self.customMethod == "DisplayRaidLocks" and self.customArgs then
            self:DisplayRaidLocks(self.customArgs, true);
        end
	end
end

SharedTooltip:SetScript("OnEvent", SharedTooltip.OnEvent);

SharedTooltip:SetScript("OnHide", function(self)
    self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    self:UnregisterEvent("UPDATE_INSTANCE_INFO");
    self.tooltipInfo = nil;
    self.tooltipData = nil;
    self.getterName = nil;
    self.customMethod = nil;
    self.customArgs = nil;
end);


do
    --Emulate the default GameTooltip
    --Code from Interface/SharedXML/Tooltip/TooltipDataHandler.lua

    local function AddTooltipDataAccessor(handler, accessor, getterName)
        local isItem = string.find(getterName, "Item");
        local isSpell = getterName == "GetSpellByID" or nil;
        handler[accessor] = function(self, ...)
            local tooltipInfo = {
                getterName = getterName,
                getterArgs = { ... };
                isItem = (isItem ~= nil) or nil,
                isSpell = isSpell,
            };
            return self:ProcessInfo(tooltipInfo);
        end
    end


    local accessors = {
        SetItemByID = "GetItemByID",
        SetCurrencyByID = "GetCurrencyByID",
        SetQuestItem = "GetQuestItem",
        SetQuestCurrency = "GetQuestCurrency",
		SetSpellByID = "GetSpellByID",
        SetItemByGUID = "GetItemByGUID",
        SetHyperlink = "GetHyperlink",
    };

    local handler = SharedTooltip;
    for accessor, getterName in pairs(accessors) do
		AddTooltipDataAccessor(handler, accessor, getterName);
	end
end


do
    local C_Garrison = C_Garrison;
    local NUM_ABILITIES = 4;

    local function AddFollowerAbility(self, getterName, followerID, title)
        local getterFunc = C_Garrison[getterName];
        if not getterFunc then return end;

        local titleAdded;

        for index = 1, NUM_ABILITIES do
            local abilityID = getterFunc(followerID, index);
            if (not abilityID) or (abilityID == 0) then
                break
            end
            if not titleAdded then
                titleAdded = true;
                self:AddLeftLine(title, 1, 0.82, 0);
            end

            local ability = C_Garrison.GetFollowerAbilityInfo(abilityID);
            local abilityName = ability.name;
            if ability.icon then
                abilityName = self:FormatIconText(ability.icon, abilityName);
            end

            local sizeIndex = 1;
            self:AddLeftLine(abilityName, 1, 0.82, 0, false, nil, sizeIndex);

            if ability.description then
                local descriptionOffset = 16;
                self:AddLeftLine(ability.description, 1, 1, 1, true, nil, 2, descriptionOffset);
            end
        end
    end

    function SharedTooltip:SetFollowerByID(followerID)
        local info = C_Garrison.GetFollowerInfo(followerID);

        if not info then
            return false
        end

        self:ClearLines();
        self:SetScript("OnUpdate", nil);

        local name = info.name;
        self:SetTitle(name, 1, 0.82, 0);

        if info.level and info.className then
            local title = format(L["Format Follower Level Class"], info.level, info.className);
            self:AddLeftLine(title, 1, 1, 1);
        end

        local abilities = C_Garrison.GetFollowerAbilities(followerID)

        if abilities and #abilities > 0 then
            AddFollowerAbility(self, "GetFollowerAbilityAtIndexByID", followerID, L["Abilities"])
            AddFollowerAbility(self, "GetFollowerTraitAtIndexByID", followerID, L["Traits"])
        end

        --print(followerID);

        self:Show();
        return true
    end
end

do
    --Emulate for Classic
    local function TOOLTIP_DATA_UPDATE(dataInstanceID)
        if SharedTooltip:IsVisible() then
            if dataInstanceID and dataInstanceID == SharedTooltip.dataInstanceID and SharedTooltip.tooltipInfo and SharedTooltip.tooltipData then
                SharedTooltip.triggeredByEvent = true;
                local oldData = SharedTooltip.tooltipData;
                local newData;
                local info = SharedTooltip.tooltipInfo;
                if info.getterArgs then
                    newData = C_TooltipInfo[info.getterName](unpack(info.getterArgs));
                else
                    newData = C_TooltipInfo[info.getterName]();
                end
                if newData and oldData.lines and newData.lines and (#oldData.lines ~= #newData.lines) then
                    SharedTooltip:ClearLines();
                    SharedTooltip:SetScript("OnUpdate", nil);

                    newData.isItem = oldData.isItem;

                    local success = SharedTooltip:ProcessTooltipData(newData);

                    if success then
                        SharedTooltip:Show();
                    else
                        SharedTooltip:Hide();
                    end
                end
            end
        end
    end

    CallbackRegistry:Register("SharedTooltip.TOOLTIP_DATA_UPDATE", TOOLTIP_DATA_UPDATE);
end

do  --Used by UI widgets
    function SharedTooltip.ShowWidgetTooltip(widget)
        if widget.tooltipText then
            SharedTooltip:Hide();
            SharedTooltip:SetOwner(widget, "TOPRIGHT");
            SharedTooltip:AddLeftLine(widget.tooltipText, 1, 1, 1);
            SharedTooltip:Show();
            SharedTooltip:Raise();
        end
    end

    function SharedTooltip.HideTooltip()
        SharedTooltip:Hide();
    end
end

do  --Showing boss locks
    function SharedTooltip:DisplayRaidLocks(info, fromRequest)
        self.dataInstanceID = nil;
        self:ClearLines();

        if info.dungeonName then
            self:SetTitle(info.dungeonName, 1, 0.82, 0);
        end

        local dead = BOSS_DEAD or "Defeated";
        local alive = BOSS_ALIVE or "Available";

        for _, v in ipairs(info.encounters) do
            local hasDefeated = IsEncounterComplete(v.mapID, v.encounterID, v.difficultyID);
            if hasDefeated then
                self:AddDoubleLine(v.bossName, dead, 1, 1, 1, 1, 0.125, 0.125);
            else
                self:AddDoubleLine(v.bossName, alive,  1, 1, 1, 0.1, 1, 0.1);
            end
        end

        self:UnregisterEvent("UPDATE_INSTANCE_INFO");

        if (not fromRequest) and RequestRaidInfo then
            self.customMethod = "DisplayRaidLocks";
            self.customArgs = info;
            self:RegisterEvent("UPDATE_INSTANCE_INFO");
            RequestRaidInfo();
        end

        local instant = true;
        self:Show(instant);
    end
end