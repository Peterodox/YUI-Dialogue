local _, addon = ...
local API = addon.API;
local PixelUtil = addon.PixelUtil;
local L = addon.L;
local Round = API.Round;
local GetItemQualityColor = API.GetItemQualityColor;
local IsItemValidForComparison = API.IsItemValidForComparison;
local GetTransmogItemInfo = API.GetTransmogItemInfo;
local C_TooltipInfo = addon.TooltipAPI;
local C_TransmogCollection = C_TransmogCollection;
local IsDressableItemByID = C_Item.IsDressableItemByID;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;

local SharedTooltip = CreateFrame("Frame");
addon.SharedTooltip = SharedTooltip;

SharedTooltip:Hide();
SharedTooltip:SetSize(16, 16);
SharedTooltip:SetIgnoreParentScale(true);
SharedTooltip:SetIgnoreParentAlpha(true);
SharedTooltip:SetFrameStrata("TOOLTIP");
SharedTooltip:SetFixedFrameStrata(true);
SharedTooltip:SetClampedToScreen(true);
SharedTooltip:SetClampRectInsets(-4, 4, 4, -4);

SharedTooltip.ShowFrame = SharedTooltip.Show;
SharedTooltip.HideFrame = SharedTooltip.Hide;

local LINE_TYPE_PRICE = Enum.TooltipDataLineType.SellPrice or 11;

local FONT_LARGE = "DUIFont_Tooltip_Large";
local FONT_MEDIUM = "DUIFont_Tooltip_Medium";
local FONT_SMALL = "DUIFont_Tooltip_Small";
local FONT_HEIGHT_MEDIUM = 12;
local FONTSTRING_MIN_GAP = 24;  --Betweeb the left and the right text of the same line
local SELL_PRICE_TEXT = (SELL_PRICE or "Sell Price").."  ";
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR;


local SPACING_NEW_LINE = 4;     --Between paragraphs
local SPACING_INTERNAL = 2;     --Within the same paragraph
local TOOLTIP_PADDING = 12;
local TOOLTIP_MAX_WIDTH = 256;
local FONTSTRING_MAX_WIDTH = TOOLTIP_MAX_WIDTH - 2*TOOLTIP_PADDING;
local FONTSTRING_SHRINK_IF_MODEL = 36;
local MODEL_WIDTH, MODEL_HEIGHT = 78, 104;
local FORMAT_ICON_TEXT = "|T%s:0:0:0:-"..SPACING_NEW_LINE.."|t %s";

local HOTKEY_ALTERNATE_MODE = "Shift";

local unpack = unpack;
local pairs = pairs;
local max = math.max;
local PI2 = math.floor(1000*math.pi*2)/1000;
local format = string.format;


local function PreviewModel_Turntable_OnUpdate(self, elapsed)
    self.yaw = self.yaw + elapsed * PI2 * 0.1;
    if self.yaw > PI2 then
        self.yaw = self.yaw - PI2;
    end
    self:SetFacing(self.yaw);
end

local Model_ApplyUICamera = Model_ApplyUICamera;
local function PreviewModel_OnModelLoaded(self)
    if self.cameraID then
        Model_ApplyUICamera(self, self.cameraID);
    end

    self.parent:SyncAnimation();
end

local DualModelMixin = {};

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


function SharedTooltip:UpdatePixel(scale)
    if not self.Background then return end;

    if not scale then
        scale = self:GetEffectiveScale();
    end

    local pixelOffset = 16.0;
    local offset = API.GetPixelForScale(scale, pixelOffset);
    offset = 0;     --Temp Fix Debug
    self.Background:ClearAllPoints();
    self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset);
    self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset);

    API.UpdateTextureSliceScale(self.Background);
end

function SharedTooltip:Init()
    if not self.Background then
        local texture = self:CreateTexture(nil, "BACKGROUND", nil, -1);
        local corner = 32;
        self.Background = texture;
        texture:SetTextureSliceMargins(corner, corner, corner, corner);
        texture:SetTextureSliceMode(1);
        texture:SetTexture(addon.ThemeUtil:GetTextureFile("TooltipBackground-Temp.png"));

        PixelUtil:AddPixelPerfectObject(self);
    end

    if not self.Content then
        self.Content = CreateFrame("Frame", nil, self);
        self.Content:SetWidth(8);   --Temp
        self.Content:SetPoint("TOPLEFT", self, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING);
        self.Content:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", TOOLTIP_PADDING, TOOLTIP_PADDING);
        --self.Content:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -TOOLTIP_PADDING, TOOLTIP_PADDING);
    end

    if not self.fontStrings then
        self.fontStrings = {};
    end

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


    if not self.iconPool then
        local function CreateIcon()
            local icon = self.Content:CreateTexture(nil, "OVERLAY");
            return icon
        end

        local function RemoveIcon(icon)
            icon:ClearAllPoints();
            icon:Hide();
            icon:SetTexture(nil);
        end

        self.iconPool = API.CreateObjectPool(CreateIcon, RemoveIcon);
    end

    self:UpdatePixel();
    self.Init = nil;
end

function SharedTooltip:ClearLines()
    if self.numLines == 0 then return end;

    self.numLines = 0;
    self.numCols = 1;
    self.numFontStrings = 0;
    self.dataInstanceID = nil;
    self.hyperlink = nil;
    self.fontChanged = false;
    self.grid = {};
    self.useGridLayout = false;

    if self.triggeredByEvent then
        self.triggeredByEvent = nil;
    else
        self.itemID = nil;
    end

    if self.fontStrings then
        for _, fontString in pairs(self.fontStrings) do
            fontString:Hide();
            fontString:SetText(nil);
            fontString.icon = nil;
        end
    end

    if self.usePreviewModel then
        self.usePreviewModel = false;
        self.DualModel:ClearModel();
    end

    if self.PreviewFrame then
        self.PreviewFrame:Hide();
    end

    if self.iconPool then
        self.iconPool:Release();
    end

    self:HideHotkey();
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

function SharedTooltip:HideHotkey()
    if self.hasHotkey then
        self.HotkeyFrame:Hide();
        self.HotkeyFrame:ClearAllPoints();
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self.onHotkeyPressedCallback = nil;
    end
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

                    local equippedItemLink =  C_Item.GetItemLinkByGUID(itemGUID); --API.GetEquippedItemLink(rewardItem);
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

            if canCompare then
                local description = shouldShowComparison and L["Hide Comparison"] or L["Show Comparison"];
                self:ShowHotkey(HOTKEY_ALTERNATE_MODE, description, AlternateModeCallback_ItemComparison);
                self:Show();
            end
        end
    end
end


function SharedTooltip:SetOwner(owner, anchor, offsetX, offsetY)
    if self.Init then
        self:Init();
    end

    self.owner = owner;
    anchor = anchor or "ANCHOR_BOTTOM";
    offsetX = offsetX or 0;
    offsetY = offsetY or 0;

    self:ClearAllPoints();

    if anchor == "ANCHOR_NONE" then
        return
    else
        self:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", offsetX, offsetY);
    end
end

function SharedTooltip:ReTriggerOnEnter()
    if self:IsVisible() and self.owner and self.owner.OnEnter and self.owner:IsShown() and self.owner:IsMouseOver() then
        self.owner:OnEnter();
    end
end

function SharedTooltip:SetLineFont(fontString, sizeIndex)
    if fontString.sizeIndex ~= sizeIndex then
        fontString.sizeIndex = sizeIndex;
        if sizeIndex == 1 then
            fontString:SetFontObject(FONT_LARGE);
        elseif sizeIndex == 2 then
            fontString:SetFontObject(FONT_MEDIUM);
        elseif sizeIndex == 3 then
            fontString:SetFontObject(FONT_SMALL);
        end
        return true
    end
end

function SharedTooltip:SetLineAlignment(fontString, alignIndex)
    fontString.alignIndex = alignIndex;
    if alignIndex == 1 then
        fontString:SetJustifyH("LEFT");
    elseif alignIndex == 2 then
        fontString:SetJustifyH("CENTER");
    elseif alignIndex == 3 then
        fontString:SetJustifyH("RIGHT");
    end
    return true
end

function SharedTooltip:AcquireFontString()
    local n = self.numFontStrings + 1;
    self.numFontStrings = n;

    if not self.fontStrings[n] then
        self.fontStrings[n] = self.Content:CreateFontString(nil, "OVERLAY", FONT_MEDIUM);
        self.fontStrings[n]:SetSpacing(SPACING_INTERNAL);
        self.fontStrings[n].sizeIndex = 2;
        self.fontStrings[n].alignIndex = 1;
        self.fontStrings[n]:SetJustifyV("MIDDLE");
    end

    self.fontStrings[n].horizontalOffset = 0;

    return self.fontStrings[n]
end

function SharedTooltip:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex, horizontalOffset)
    r = r or 1;
    g = g or 1;
    b = b or 1;
    wrapText = (wrapText == true) or false;
    offsetY = offsetY or -SPACING_NEW_LINE;
    sizeIndex = sizeIndex or 2;
    alignIndex = alignIndex or 1;
    horizontalOffset = horizontalOffset or 0;

    local fs = self:AcquireFontString();

    local fontChanged = self:SetLineFont(fs, sizeIndex);
    if fontChanged then
        self.fontChanged = true;
    end
    self:SetLineAlignment(fs, alignIndex);

    fs:ClearAllPoints();
    fs:SetPoint("TOPLEFT", self.Content, "TOPLEFT", 0, 0);

    fs:SetWidth(FONTSTRING_MAX_WIDTH);
    fs:SetText(text);
    fs:SetTextColor(r, g, b, 1);
    fs:Show();
    fs.inGrid = nil;
    fs.horizontalOffset = horizontalOffset;

    return fs
end

function SharedTooltip:SetGridLine(row, col, text, r, g, b, sizeIndex, alignIndex)
    if not text then return end

    if self.grid[row] and self.grid[row][col] then
        self.grid[row][col]:SetText("(Occupied)")
        return
    end

    local fs = self:AddText(text, r, g, b, nil, nil, sizeIndex, alignIndex);
    fs.inGrid = true;

    if not self.grid[row] then
        self.grid[row] = {};
    end
    self.grid[row][col] = fs;

    if row > self.numLines then
        self.numLines = row;
    end

    if col > self.numCols then
        self.numCols = col;
    end

    self.useGridLayout = true;
end

function SharedTooltip:AddIcon(file, width, height, layer, sublevel)
    local f = self.iconPool:Acquire();
    f:ClearAllPoints();
    f:SetPoint("TOPLEFT", self.Content, "TOPLEFT", 0, 0);
    f:SetSize(width, height or width);
    f:SetDrawLayer(layer or "OVERLAY", sublevel or 0);
    f:SetTexture(file);
    return f
end

function SharedTooltip:AddLeftLine(text, r, g, b, wrapText, offsetY, sizeIndex, horizontalOffset)
    --This will start a new line

    if (not text) or (text == "") then return end
    local n = self.numLines + 1;
    self.numLines = n;

    local alignIndex = 1;
    local fs = self:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex, horizontalOffset);

    if not self.grid[n] then
        self.grid[n] = {};
    end
    self.grid[n][1] = fs;

    return fs
end

function SharedTooltip:AddCenterLine(text, r, g, b, wrapText, offsetY, sizeIndex)
    --This will also start a new line
    --Align to the center

    if not text then return end
    local n = self.numLines + 1;
    self.numLines = n;

    local alignIndex = 2;
    local fs = self:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex);

    if not self.grid[n] then
        self.grid[n] = {};
    end
    self.grid[n][1] = fs;

    return fs
end

function SharedTooltip:SetTitle(text, r, g, b)
    self:AddLeftLine(text, r, g, b, true, nil, 1);
end

function SharedTooltip:AddRightLine(text, r, g, b, wrapText, offsetY, sizeIndex)
    --Right line must come in pairs with a LeftLine
    --This will NOT start a new line

    if not text then return end
    local alignIndex = 3;
    local fs = self:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex);
    local n = self.numLines;

    if not self.grid[n] then
        self.grid[n] = {};
    end
    self.grid[n][2] = fs;

    self.numCols = 2;

    return fs
end

function SharedTooltip:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
    self:AddLeftLine(leftText, leftR, leftG, leftB);
    self:AddRightLine(rightText, rightR, rightG, rightB);
end

function SharedTooltip:AddBlankLine()
    local n = self.numLines + 1;
    self.numLines = n;
    self.grid[n] = {
        gap = SPACING_NEW_LINE,
    };
end

function SharedTooltip:AddColoredLine(text, colorGlobal)
    local r, g, b;
    if colorGlobal and colorGlobal.GetRGB then
        r, g, b = colorGlobal:GetRGB();
    else
        r, g, b = 1, 1, 1;
    end
    self:AddLeftLine(text, r, g, b, true);
end

function SharedTooltip:ProcessInfo(info)
    self.tooltipInfo = info;

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

function SharedTooltip:ProcessTooltipData(tooltipData)
    if not (tooltipData and tooltipData.lines) then
        self.tooltipData = nil;
        return false
    end

    self.tooltipData = tooltipData;
    self.dataInstanceID = tooltipData.dataInstanceID;
    self.hyperlink = tooltipData.hyperlink;

    self:RegisterEvent("TOOLTIP_DATA_UPDATE");

    local leftText, leftColor, wrapText, rightText, rightColor, leftOffset;
    local r, g, b;

    for i, lineData in ipairs(tooltipData.lines) do
        leftText = lineData.leftText;
        leftColor = lineData.leftColor or NORMAL_FONT_COLOR;
        rightText = lineData.rightText;
        wrapText = lineData.wrapText or false;
        leftOffset = lineData.leftOffset;

        if leftText then
            if leftText == " "then
                --A whole blank line is too tall, so we change its height
                self:AddBlankLine();
            else
                if i == 1 then
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
                    self:AddLeftLine(leftText, r, g, b, wrapText, nil, (i == 1 and 1) or 2);
                end

                if rightText then
                    rightColor = lineData.rightColor or NORMAL_FONT_COLOR;
                    r, g, b = rightColor:GetRGB();
                    self:AddRightLine(rightText, r, g, b, wrapText, nil, 2);
                end
            end
        end
	end

    if tooltipData.isItem then
        self:ShowItemComparison();
    end

    return true
end

local TOPLINE_MAX_ROW = 2;

function SharedTooltip:Layout()
    local textWidth, textHeight, lineWidth;
    local topLinesWidth;
    local totalHeight = 0;
    local maxLineWidth = 0;
    local maxLineHeight = 0;
    local grid = self.grid;
    local fs;
    local ref = self.Content;
    local usePreviewModel = self.usePreviewModel;

    local colMaxWidths, rowOffsetYs;
    local numCols = self.numCols;
    local useGridLayout = self.useGridLayout;
    if useGridLayout then
        colMaxWidths = {};
        rowOffsetYs = {};
        for i = 1, numCols do
            colMaxWidths[i] = 0;
        end
    end

    for row = 1, self.numLines do
        if grid[row] then
            lineWidth = 0;
            maxLineHeight = 0;
            if grid[row].gap then
                --Positive value increase the distance between lines
                totalHeight = totalHeight + grid[row].gap;
            end
            for col = 1, numCols do
                fs = grid[row][col];
                if fs then
                    if usePreviewModel and col == 1 and row <= 3 then
                        fs:SetWidth(FONTSTRING_MAX_WIDTH - FONTSTRING_SHRINK_IF_MODEL);
                    end

                    textWidth = fs:GetWrappedWidth() + fs.horizontalOffset;
                    textHeight = fs:GetHeight();

                    if fs.icon then
                        textWidth = textWidth + fs.icon:GetWidth() + (fs.icon.iconGap or 0);
                        textHeight = max(textHeight, fs.icon:GetHeight());
                    end

                    if col == 1 then
                        lineWidth = textWidth;
                    else
                        lineWidth = lineWidth + FONTSTRING_MIN_GAP + textWidth;
                    end

                    fs.lineWidth = lineWidth;

                    if lineWidth > maxLineWidth then
                        maxLineWidth = lineWidth;
                    end

                    if textHeight > maxLineHeight then
                        maxLineHeight = textHeight;
                    end

                    if useGridLayout and textWidth > colMaxWidths[col] and fs.inGrid then
                        colMaxWidths[col] = textWidth;
                    end
                end
            end

            if row ~= 1 then
                totalHeight = totalHeight + SPACING_NEW_LINE;
            end
            totalHeight = Round(totalHeight);

            if useGridLayout then
                rowOffsetYs[row] = -totalHeight;
            else
                local obj;
                local iconGap;

                for col = 1, numCols do
                    fs = grid[row][col];
                    if fs then
                        fs:ClearAllPoints();

                        if fs.icon then
                            obj = fs.icon;
                            obj:ClearAllPoints();
                            iconGap = fs.icon.iconGap or 0;
                            if fs.alignIndex == 2 then
                                fs:SetPoint("TOPLEFT", obj, "TOPRIGHT", iconGap, 0);
                            elseif fs.alignIndex == 3 then
                                fs:SetPoint("TOPRIGHT", obj, "TOPLEFT", -iconGap, 0);
                            else
                                fs:SetPoint("TOPLEFT", obj, "TOPRIGHT", iconGap, 0);
                            end
                        else
                            obj = fs;
                        end

                        if fs.alignIndex == 2 then
                            if fs.icon then
                                obj:SetPoint("TOPLEFT", ref, "TOP", -0.5*fs.lineWidth + fs.horizontalOffset, -totalHeight);
                            else
                                obj:SetPoint("TOP", ref, "TOP", 0 + fs.horizontalOffset, -totalHeight);
                            end
                        elseif fs.alignIndex == 3 then
                            obj:SetPoint("TOPRIGHT", ref, "TOPRIGHT", 0 + fs.horizontalOffset, -totalHeight);
                        else
                            obj:SetPoint("TOPLEFT", ref, "TOPLEFT", 0 + fs.horizontalOffset, -totalHeight);
                        end
                    end
                end
            end

            totalHeight = totalHeight + maxLineHeight;
            totalHeight = Round(totalHeight);
        end

        if not topLinesWidth then
            topLinesWidth = maxLineWidth;
        elseif row <= TOPLINE_MAX_ROW then
            if maxLineWidth > topLinesWidth then
                topLinesWidth = maxLineWidth;
            end
        end
    end

    if useGridLayout then
        local offsetX, offsetY;
        for row = 1, self.numLines do
            offsetX = 0;
            offsetY = rowOffsetYs[row];
            for col = 1, numCols do
                fs = grid[row][col];
                textWidth = colMaxWidths[col] + 1;
                if fs then
                    fs:ClearAllPoints();
                    if fs.alignIndex == 2 then
                        if fs.inGrid then
                            fs:SetPoint("TOPLEFT", ref, "TOPLEFT", offsetX, offsetY);
                            fs:SetWidth(textWidth);
                        else
                            fs:SetPoint("TOP", ref, "TOP", offsetX, offsetY);
                        end
                    elseif fs.alignIndex == 3 then
                        if col == numCols then
                            fs:SetPoint("TOPRIGHT", ref, "TOPRIGHT", 0, offsetY);
                        else
                            fs:SetPoint("TOPLEFT", ref, "TOPLEFT", offsetX, offsetY);
                            fs:SetWidth(textWidth);
                        end
                    else
                        fs:SetPoint("TOPLEFT", ref, "TOPLEFT", offsetX, offsetY);
                    end
                end

                offsetX = offsetX + colMaxWidths[col] + FONTSTRING_MIN_GAP;
            end
        end

        maxLineWidth = 0;
        for col = 1, numCols do
            maxLineWidth = maxLineWidth + colMaxWidths[col];
            if col > 1 then
                maxLineWidth = maxLineWidth + FONTSTRING_MIN_GAP;
            end
        end
    end

    local contentWidth = Round(maxLineWidth);
    self.Content:SetWidth(contentWidth);

    if usePreviewModel then
        local modelWidth = self.DualModel:GetWidth();
        topLinesWidth = topLinesWidth or 0;
        topLinesWidth = topLinesWidth + modelWidth + TOOLTIP_PADDING;
        contentWidth = max(topLinesWidth, maxLineWidth);
        self:SetClampRectInsets(-4, 4, 56, -4);
    else
        self:SetClampRectInsets(-4, 4, 4, -4);
    end

    local fullWidth = Round(contentWidth) + 2*TOOLTIP_PADDING;
    local fullHeight = Round(totalHeight) + 2*TOOLTIP_PADDING;

    self:SetSize(fullWidth, fullHeight);
end

function SharedTooltip:SetFrameAlpha(alpha)
    self:SetAlpha(alpha);
    if self.DualModel then
        self.DualModel:SetModelAlpha(alpha);
    end
end

function SharedTooltip:LoadTheme()
    if self.Background then
        self.Background:SetTexture(addon.ThemeUtil:GetTextureFile("TooltipBackground-Temp.png"));
    end

    if self.HotkeyFrame then
        self.HotkeyFrame:LoadTheme();
    end
end

local function SharedTooltip_OnUpdate_FadeIn(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        local alpha = 10*self.t;
        if alpha >= 1 then
            alpha = 1;
            self.t = nil;
            self:SetScript("OnUpdate", nil);
        end
        self:SetFrameAlpha(alpha);
    else
        self:SetFrameAlpha(0);
    end
end

local function SharedTooltip_OnUpdate_Layout(self, elapsed)
    self:SetScript("OnUpdate", nil);
    self:Layout();

    if self.showDelay then
        self:SetScript("OnUpdate", SharedTooltip_OnUpdate_FadeIn);
    end
end


function SharedTooltip:LayoutNextUpdate()
    self:SetScript("OnUpdate", SharedTooltip_OnUpdate_Layout);
end

function SharedTooltip:Show()
    local layoutComplete;

    self:DisplayModel();

    if self.fontChanged or self.useGridLayout then
        --fontString width will take one frame to change
        layoutComplete = false;
        self:LayoutNextUpdate();
    else
        layoutComplete = true;
        self:Layout();
    end

    if self.showDelay then
        self.t = self.showDelay;
        self:SetFrameAlpha(0);
        if layoutComplete then
           self:SetScript("OnUpdate", SharedTooltip_OnUpdate_FadeIn);
        end
    else
        self.t = nil;
        self:SetFrameAlpha(1);
    end

    self:ShowFrame();
end

function SharedTooltip:SetShowDelay(delay)
    if delay and delay > 0 then
        self.showDelay = -delay;
    else
        self.showDelay = nil;
    end
end

function SharedTooltip:Hide()
    self:HideFrame();
    self:ClearAllPoints();
    self:SetScript("OnUpdate", nil);
    self:ClearLines();
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
	end
end

SharedTooltip:SetScript("OnEvent", SharedTooltip.OnEvent);

SharedTooltip:SetScript("OnHide", function(self)
    self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    self.tooltipInfo = nil;
    self.tooltipData = nil;
end);


do
    --Emulate the default GameTooltip
    --Code from Interface/SharedXML/Tooltip/TooltipDataHandler.lua

    local function AddTooltipDataAccessor(handler, accessor, getterName)
        local isItem = string.find(getterName, "Item");

        handler[accessor] = function(self, ...)
            local tooltipInfo = {
                getterName = getterName,
                getterArgs = { ... };
                isItem = (isItem ~= nil) or nil,
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

SharedTooltip:ClearLines();

function SharedTooltip:FormatIconText(icon, text)
    return format(FORMAT_ICON_TEXT, icon, text);
end

function SharedTooltip:AddSimpleIconText(file, size, text, r, g, b)
    size = size or FONT_HEIGHT_MEDIUM;

    local icon = self:AddIcon(file, size, size, "OVERLAY", 0);
    local fs = self:AddLeftLine(text, r, g, b, true);

    fs.icon = icon;
    icon.iconGap = SPACING_INTERNAL;

    return fs
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

    addon.CallbackRegistry:Register("SharedTooltip.TOOLTIP_DATA_UPDATE", TOOLTIP_DATA_UPDATE);
end


do
    local function PostFontSizeChanged()
        if SharedTooltip.HotkeyFrame then
            SharedTooltip.HotkeyFrame:UpdateBaseHeight();
        end

        local _;
        _, FONT_HEIGHT_MEDIUM = _G[FONT_MEDIUM]:GetFont();
        FONT_HEIGHT_MEDIUM = Round(FONT_HEIGHT_MEDIUM);
    end
    addon.CallbackRegistry:Register("PostFontSizeChanged", PostFontSizeChanged);

    local function PostInputDeviceChanged(dbValue)
        if SharedTooltip.HotkeyFrame then
            SharedTooltip.HotkeyFrame:UpdateBaseHeight();
        end
    end
    addon.CallbackRegistry:Register("PostInputDeviceChanged", PostInputDeviceChanged);
end


do  --DEBUG
    --[[
    local f = CreateFrame("Frame", "NTT", nil);
    f:SetSize(100, 100);
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

    local function Setup()
        local pieces = {};
        local cornerSize = 32;
        local offset = cornerSize * 0.5;
        local file = "Interface/AddOns/DialogueUI/Art/Tooltip_Debug";

        local function CreatePiece()
            local tex = f:CreateTexture(nil, "BACKGROUND");
            table.insert(pieces, tex);
            tex:SetSize(cornerSize, cornerSize);
            
            tex:SetTexture(file)
            return tex
        end

        f.P1 = CreatePiece();
        f.P1:SetPoint("TOPLEFT", f, "TOPLEFT", -offset, offset);
        f.P1:SetTexCoord(0, 0.25, 0, 0.25);
    
        f.P3 = CreatePiece();
        f.P3:SetPoint("TOPRIGHT", f, "TOPRIGHT", offset, offset);
        f.P3:SetTexCoord(0.75, 1, 0, 0.25);

        f.P7 = CreatePiece();
        f.P7:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -offset, -offset);
        f.P7:SetTexCoord(0, 0.25, 0.75, 1);
    
        f.P9 = CreatePiece();
        f.P9:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", offset, -offset);
        f.P9:SetTexCoord(0.75, 1, 0.75, 1);
        
        f.P2 = CreatePiece();
        f.P2:SetPoint("TOPLEFT", f.P1, "TOPRIGHT", 0, 0);
        f.P2:SetPoint("BOTTOMRIGHT", f.P3, "BOTTOMLEFT", 0, 0);
        f.P2:SetHorizTile(true);
        f.P2:SetVertTile(false);
        f.P2:SetTexture(file)
        f.P2:SetTexCoord(0.25, 0.75, 0, 0.25);

        f.P4 = CreatePiece();
        f.P4:SetPoint("TOPLEFT", f.P1, "BOTTOMLEFT", 0, 0);
        f.P4:SetPoint("BOTTOMRIGHT", f.P7, "TOPRIGHT", 0, 0);
        f.P4:SetTexCoord(0, 0.25, 0.25, 0.75);
        f.P4:SetVertTile(true);

        f.P6 = CreatePiece();
        f.P6:SetPoint("TOPLEFT", f.P3, "BOTTOMLEFT", 0, 0);
        f.P6:SetPoint("BOTTOMRIGHT", f.P9, "TOPRIGHT", 0, 0);
        f.P6:SetTexCoord(0.75, 1, 0.25, 0.75);
        f.P6:SetVertTile(true);

        f.P8 = CreatePiece();
        f.P8:SetPoint("TOPLEFT", f.P7, "TOPRIGHT", 0, 0);
        f.P8:SetPoint("BOTTOMRIGHT", f.P9, "BOTTOMLEFT", 0, 0);
        f.P8:SetTexCoord(0.25, 0.75, 0.75, 1);
        f.P8:SetHorizTile(true);

        f.P5 = CreatePiece();
        f.P5:SetPoint("TOPLEFT", f.P1, "BOTTOMRIGHT", 0, 0);
        f.P5:SetPoint("BOTTOMRIGHT", f.P9, "TOPLEFT", 0, 0);
        f.P5:SetHorizTile(true);
        f.P5:SetVertTile(true);
        f.P5:SetTexCoord(0.25, 0.75, 0.25, 0.75);
    end
    --]]

    --C_Timer.After(1, Setup);
end