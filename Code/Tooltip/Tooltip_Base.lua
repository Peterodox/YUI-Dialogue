local _, addon = ...
local API = addon.API;
local PixelUtil = addon.PixelUtil;
local CreateFrame = CreateFrame;
local max = math.max;
local Round = API.Round;
local format = string.format;


local SPACING_NEW_LINE = 4;     --Between paragraphs
local SPACING_INTERNAL = 2;     --Within the same paragraph
local TOOLTIP_PADDING = 12;
local TOOLTIP_MAX_WIDTH = 256;
local FONTSTRING_MAX_WIDTH = TOOLTIP_MAX_WIDTH - 2*TOOLTIP_PADDING;
local FONTSTRING_SHRINK_IF_MODEL = 36;


local FONT_LARGE = "DUIFont_Tooltip_Large";
local FONT_MEDIUM = "DUIFont_Tooltip_Medium";
local FONT_SMALL = "DUIFont_Tooltip_Small";
local FONT_HEIGHT_MEDIUM = 12;
local FONTSTRING_MIN_GAP = 24;  --Betweeb the left and the right text of the same line
local FORMAT_ICON_TEXT = "|T%s:0:0:0:-"..SPACING_NEW_LINE.."|t %s";


local CursorFollower = CreateFrame("Frame");

local TooltipBaseMixin = {};

function TooltipBaseMixin:UpdatePixel(scale)
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

function TooltipBaseMixin:InitFrame()
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
    end

    if not self.fontStrings then
        self.fontStrings = {};
    end

    if not self.grid then
        self.grid = {};
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
            icon:SetTexCoord(0, 1, 0, 1);
        end

        self.iconPool = API.CreateObjectPool(CreateIcon, RemoveIcon);
    end

    self:UpdatePixel();
end

function TooltipBaseMixin:Init()
    self:InitFrame();
    self.Init = nil;
    self.InitFrame = nil;
end

function TooltipBaseMixin:HideHotkey()
    if self.HotkeyFrame and self.hasHotkey then
        self.HotkeyFrame:Hide();
        self.HotkeyFrame:ClearAllPoints();
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self.onHotkeyPressedCallback = nil;
    end
end

function TooltipBaseMixin:NumLines()
    return self.numLines or 0
end

function TooltipBaseMixin:ClearLines()
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

    if self.DualModel and self.usePreviewModel then
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

local function TooltipBaseMixin_OnUpdate_FadeIn(self, elapsed)
    if not self.t then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self:SetFrameAlpha(1);
        return
    end

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

local function TooltipBaseMixin_OnUpdate_Layout(self, elapsed)
    self:SetScript("OnUpdate", nil);
    self:Layout();

    if self.showDelay then
        self:SetScript("OnUpdate", TooltipBaseMixin_OnUpdate_FadeIn);
    end
end

function TooltipBaseMixin:SetFrameAlpha(alpha)
    self:SetAlpha(alpha);
    if self.DualModel then
        self.DualModel:SetModelAlpha(alpha);
    end
end

function TooltipBaseMixin:Show(instant)
    local layoutComplete;

    if self.DisplayModel then
        self:DisplayModel();
    end

    if self.fontChanged or self.useGridLayout then
        --fontString width will take one frame to change
        layoutComplete = false;
        self:LayoutNextUpdate();
    else
        layoutComplete = true;
        self:Layout();
    end

    if self.showDelay and not instant then
        self.t = self.showDelay;
        self:SetFrameAlpha(0);
        if layoutComplete then
            self:SetScript("OnUpdate", TooltipBaseMixin_OnUpdate_FadeIn);
        end
    else
        self.t = nil;
        self:SetFrameAlpha(1);
    end

    self:ShowFrame();
end

function TooltipBaseMixin:SetShowDelay(delay)
    if delay and delay > 0 then
        self.showDelay = -delay;
    else
        self.showDelay = nil;
    end
end

function TooltipBaseMixin:Hide()
    self:HideFrame();
    self:ClearAllPoints();
    self:SetScript("OnUpdate", nil);
    self:ClearLines();
end

local TOPLINE_MAX_ROW = 2;

function TooltipBaseMixin:Layout()
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

    if usePreviewModel and self.DualModel then
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

function TooltipBaseMixin:LoadTheme()
    if self.Background then
        self.Background:SetTexture(addon.ThemeUtil:GetTextureFile("TooltipBackground-Temp.png"));
    end

    if self.HotkeyFrame then
        self.HotkeyFrame:LoadTheme();
    end
end

function TooltipBaseMixin:LayoutNextUpdate()
    self:SetScript("OnUpdate", TooltipBaseMixin_OnUpdate_Layout);
end

function TooltipBaseMixin:SetOwner(owner, anchor, offsetX, offsetY)
    if self.Init then
        self:Init();
    end

    self.owner = owner;
    anchor = anchor or "ANCHOR_BOTTOM";
    offsetX = offsetX or 0;
    offsetY = offsetY or 0;

    self:ClearAllPoints();
    CursorFollower:SetCursorObject(nil);

    if anchor == "ANCHOR_NONE" then
        return
    elseif anchor == "ANCHOR_CURSOR" then
        CursorFollower:SetCursorObject(self, 0, 8);
    else
        self:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", offsetX, offsetY);
    end
end

function TooltipBaseMixin:ReTriggerOnEnter()
    if self:IsVisible() and self.owner and self.owner.OnEnter and self.owner:IsShown() and self.owner:IsMouseOver() then
        self.owner:OnEnter();
    end
end

function TooltipBaseMixin:SetLineFont(fontString, sizeIndex)
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

function TooltipBaseMixin:SetLineAlignment(fontString, alignIndex)
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

function TooltipBaseMixin:AcquireFontString()
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

function TooltipBaseMixin:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex, horizontalOffset)
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

    fs:SetWidth(self.maxTextWidth or FONTSTRING_MAX_WIDTH);
    fs:SetText(text);
    fs:SetTextColor(r, g, b, 1);
    fs:Show();
    fs.inGrid = nil;
    fs.horizontalOffset = horizontalOffset;

    return fs
end

function TooltipBaseMixin:SetGridLine(row, col, text, r, g, b, sizeIndex, alignIndex)
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

function TooltipBaseMixin:AddIcon(file, width, height, layer, sublevel)
    width = width or FONT_HEIGHT_MEDIUM;
    local f = self.iconPool:Acquire();
    f:ClearAllPoints();
    f:SetPoint("TOPLEFT", self.Content, "TOPLEFT", 0, 0);
    f:SetSize(width, height or width);
    f:SetDrawLayer(layer or "OVERLAY", sublevel or 0);
    f:SetTexture(file);
    return f
end

function TooltipBaseMixin:AddLeftLine(text, r, g, b, wrapText, offsetY, sizeIndex, horizontalOffset)
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

function TooltipBaseMixin:AddCenterLine(text, r, g, b, wrapText, offsetY, sizeIndex)
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

function TooltipBaseMixin:SetTitle(text, r, g, b)
    self:AddLeftLine(text, r, g, b, true, nil, 1);
end

function TooltipBaseMixin:AddRightLine(text, r, g, b, wrapText, offsetY, sizeIndex)
    --Right line must come in pairs with a LeftLine
    --This will NOT start a new line

    if (not text) or (text == "") then return end
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

function TooltipBaseMixin:FormatIconText(icon, text)
    return format(FORMAT_ICON_TEXT, icon, text);
end

function TooltipBaseMixin:AddSimpleIconText(file, size, text, r, g, b)
    size = size or FONT_HEIGHT_MEDIUM;

    local icon = self:AddIcon(file, size, size, "OVERLAY", 0);
    local fs = self:AddLeftLine(text, r, g, b, true);

    fs.icon = icon;
    icon.iconGap = SPACING_INTERNAL;

    return fs
end

function TooltipBaseMixin:AddBlankLine()
    local n = self.numLines + 1;
    self.numLines = n;
    self.grid[n] = {
        gap = SPACING_NEW_LINE,
    };
end

function TooltipBaseMixin:AddColoredLine(text, colorGlobal)
    local r, g, b;
    if colorGlobal and colorGlobal.GetRGB then
        r, g, b = colorGlobal:GetRGB();
    else
        r, g, b = 1, 1, 1;
    end
    self:AddLeftLine(text, r, g, b, true);
end

function TooltipBaseMixin:AddLine(text, r, g, b, wrapText)
    self:AddLeftLine(text, r, g, b, wrapText, nil, 2);
end

function TooltipBaseMixin:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
    self:AddLeftLine(leftText, leftR, leftG, leftB);
    self:AddRightLine(rightText, rightR, rightG, rightB);
end

function TooltipBaseMixin:SetMaxTextWidth(maxTextWidth)
    self.maxTextWidth = maxTextWidth or FONTSTRING_MAX_WIDTH;
end

function TooltipBaseMixin:GetLeftLineText(row)
    if self.grid[row] and self.grid[row][1] then
        return self.grid[row][1]:GetText()
    end
end

function TooltipBaseMixin:OverwriteLeftLineText(row, text)
    if self.grid[row] and self.grid[row][1] then
        return self.grid[row][1]:SetText(text)
    end
end

function TooltipBaseMixin:GetLastLeftLine()
    if self.numLines > 0 and self.grid[self.numLines] then
        return self.grid[self.numLines][1]
    end
end

function TooltipBaseMixin:AddTexture(file, textureInfoTable)
    --Emulate GameTooltip Bahavior
    --Adds a texture to the beginning of the last left line

    local fs = self:GetLastLeftLine();
    if not fs then return false end;

    local width, height;
    local l, r, t, b = 0.0625, 0.9375, 0.0625, 0.9375;

    if textureInfoTable then
        width = textureInfoTable.width;
        height = textureInfoTable.height;
        local coords = textureInfoTable.texCoords;
        if coords then
            l, r, t, b = coords.left, coords.right, coords.top, coords.bottom;
        end
    end

    local icon = self:AddIcon(file, width, height);
    icon:SetTexCoord(l, r, t, b);
    fs.icon = icon;
    icon.iconGap = SPACING_INTERNAL;

    return true
end


do
    CursorFollower.GetCursorPosition = GetCursorPosition;
    CursorFollower.DeltaLerp = API.DeltaLerp;

    function CursorFollower:SetCursorObject(obj, offsetX, offsetY)
        self.obj = obj;
        if obj and obj:IsVisible() then
            self:SetParent(obj);
            obj:ClearAllPoints();
            self.isUpdating = true;
            self.offsetX = offsetX or 0;
            self.offsetY = offsetY or 0;
            self.x, self.y = self.GetCursorPosition();
            self.t = 1;
            self:SetScript("OnUpdate", self.OnUpdate);
            self:Show();
        else
            self:Hide();
        end
    end

    function CursorFollower:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.05 then
            self.t = 0;
            self.targetX, self.targetY = self.GetCursorPosition();
        end
        self.x = self.DeltaLerp(self.x, self.targetX, 0.15, elapsed);
        self.y = self.DeltaLerp(self.y, self.targetY, 0.15, elapsed);
        self.obj:SetPoint("BOTTOM", nil, "BOTTOMLEFT", self.x + self.offsetY, self.y + self.offsetY);
    end

    function CursorFollower:OnHide()
        if self.isUpdating then
            self.isUpdating = nil;
            self:SetScript("OnUpdate", nil);
            self:Hide();
            self.x, self.y, self.targetX, self.targetY = nil, nil, nil, nil;
        end
    end
    CursorFollower:SetScript("OnHide", CursorFollower.OnHide);
end


local Tooltips = {};

local function CreateTooltipBase()
    local f = CreateFrame("Frame");

    f.ShowFrame = f.Show;
    f.HideFrame = f.Hide;

    API.Mixin(f, TooltipBaseMixin);

    f:Hide();
    f:SetSize(16, 16);
    f:SetIgnoreParentScale(true);
    f:SetIgnoreParentAlpha(true);
    f:SetFrameStrata("TOOLTIP");
    f:SetFixedFrameStrata(true);
    f:SetClampedToScreen(true);
    f:SetClampRectInsets(-4, 4, 4, -4);

    f:ClearLines();

    table.insert(Tooltips, f);

    return f
end
addon.CreateTooltipBase = CreateTooltipBase;


do
    local CallbackRegistry = addon.CallbackRegistry;

    local function PostInputDeviceChanged(dbValue)
        for _, tooltip in ipairs(Tooltips) do
            if tooltip.HotkeyFrame then
                tooltip.HotkeyFrame:UpdateBaseHeight();
            end
        end
    end
    CallbackRegistry:Register("PostInputDeviceChanged", PostInputDeviceChanged);

    local function PostFontSizeChanged()
        PostInputDeviceChanged();

        local _;
        _, FONT_HEIGHT_MEDIUM = _G[FONT_MEDIUM]:GetFont();
        FONT_HEIGHT_MEDIUM = Round(FONT_HEIGHT_MEDIUM);

        local widthMultiplier = max(1, FONT_HEIGHT_MEDIUM / 10);
        FONTSTRING_MAX_WIDTH = widthMultiplier * (TOOLTIP_MAX_WIDTH - 2*TOOLTIP_PADDING);

        CallbackRegistry:Trigger("TooltipTextMaxWidthChanged", FONTSTRING_MAX_WIDTH);
    end
    CallbackRegistry:Register("PostFontSizeChanged", PostFontSizeChanged);
end