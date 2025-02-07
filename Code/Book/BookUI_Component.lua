local _, addon = ...


local BookComponent = {};
addon.BookComponent = BookComponent;


local API = addon.API;
local L = addon.L;
local FontUtil = addon.FontUtil;
local ThemeUtil = addon.ThemeUtil;
local GetDBBool = addon.GetDBBool;
local Mixin = API.Mixin;
local Round = API.Round;
local CreateFrame = CreateFrame;


-- User Settings

------------------


local PAGE_SELECTED_COLOR = "Ivory";
local PAGE_NORMAL_COLOR = "LightBrown";


local PageButtonMixin = {};
do  --Pagination
    function PageButtonMixin:SetPage(page)
        self.PageText:SetText(page);
        self.page = page;
    end

    function PageButtonMixin:SetSelected(state)
        if state == self.selected then return end;
        self.selected = state;

        if state then
            ThemeUtil:SetFontColor(self.PageText, PAGE_SELECTED_COLOR);
            self.Background:SetTexCoord(780/1024, 820/1024, 1564/2048, 1604/2048);
        else
            ThemeUtil:SetFontColor(self.PageText, PAGE_NORMAL_COLOR);
            self.Background:SetTexCoord(844/1024, 884/1024, 1564/2048, 1604/2048);
        end
    end

    function PageButtonMixin:OnEnter()
        self.Highlight:Show();
    end

    function PageButtonMixin:OnLeave()
        self.Highlight:Hide();
    end

    function PageButtonMixin:SetObjectSize(buttonSize)
        self:SetSize(buttonSize, buttonSize);
    end

    function PageButtonMixin:SetUITexture(file)
        self.Background:SetTexture(file);
        self.Highlight:SetTexture(file);
    end
end


local CloseButton;
do
    function BookComponent:GetCloseButton(parent)
        if not CloseButton then
            CloseButton = CreateFrame("Button", nil, parent);
            CloseButton.Texture = CloseButton:CreateTexture(nil, "ARTWORK");
            CloseButton.Texture:SetAllPoints(true);
            CloseButton.Texture:SetTexCoord(768/1024, 832/1024, 1488/2048, 1552/2048);
            CloseButton.Highlight = CloseButton:CreateTexture(nil, "HIGHLIGHT");
            CloseButton.Highlight:SetAllPoints(true);
            CloseButton.Highlight:SetTexCoord(832/1024, 896/1024, 1488/2048, 1552/2048);

            function CloseButton:OnClick()
                parent:Hide();
            end
            CloseButton:SetScript("OnClick", CloseButton.OnClick);

            function CloseButton:SetUITexture(file)
                CloseButton.Texture:SetTexture(file);
                CloseButton.Highlight:SetTexture(file);
            end
        end
        return CloseButton
    end
end


do  --Header / Book Title
    local TITLE_SPACING = 4;
    local MAX_PAGE_BUTTONS = 9;

    local HeaderFrameMixin = {};

    function HeaderFrameMixin:SetTitle(title)
        --debug: Check mising glyph
        --[[
        do
            local name = C_Item.GetItemInfo(226364);
            title = name;
            local index = 12;
            print(string.sub(title, 12, 12))
            print(string.byte(title, 14))
        end
        --]]
        local minLineHeight = 14;
        self:SetAutoScalingText(self.Title, title, minLineHeight);
    end

    function HeaderFrameMixin:SetAutoScalingText(fontString, text, minLineHeight)
        fontString:SetMaxLines(1);
        fontString:SetHeight(0);
        fontString:SetText(text);

        local _, baseLineHeight = fontString:GetFont();
        baseLineHeight = Round(baseLineHeight);

        local tryHeight = baseLineHeight;
        local finalScale = 1;

        while tryHeight >= minLineHeight do
            local scale = tryHeight / baseLineHeight;
            fontString:SetTextScale(scale);
            finalScale = scale;
            if fontString:IsTruncated() then
                tryHeight = tryHeight - 2;
            else
                break
            end
        end

        if fontString:IsTruncated() then
            local maxLines = 2;
            fontString:SetMaxLines(maxLines);
            --After SetMaxLines, It takes one frame to get the correct FontString height
            --So we calculate its height instead of measuring it
            self.titleHeight = finalScale * ( maxLines*(baseLineHeight + TITLE_SPACING) - TITLE_SPACING);
        else
            self.titleHeight = fontString:GetHeight();
        end

        self.titleHeight = Round(self.titleHeight);
    end

    function HeaderFrameMixin:GetHeaderHeight()
        return Round( (self:GetTitleHeight()) + (self.heightBelow or 0) )
    end

    function HeaderFrameMixin:SetHeightBelowTitle(heightBelow)
        --Usually the Paragraph Spacing
        --Distance between the bottom of the Title text and the top the body is Page Spacing
        self.heightBelow = heightBelow;
    end

    function HeaderFrameMixin:GetTitleHeight()
        return self.titleHeight or self.Title:GetHeight()
    end

    function HeaderFrameMixin:GetTitleEffectiveLineHeight()
        local _, baseLineHeight = self.Title:GetFont();
        local scale = self.Title:GetTextScale();
        return baseLineHeight * scale
    end

    function HeaderFrameMixin:SetLocation(isGameObject, locationText)
        if  isGameObject and GetDBBool("BookShowLocation") then
            self.Location:SetText(locationText);
            self.Location:Show();
        else
            self.Location:SetText(nil);
            self.Location:Hide();
        end
    end

    function HeaderFrameMixin:SetMaxPage(maxPage)
        self:ReleaseAllObjects();
        self.maxPage = maxPage;
        self.currentPage = 0;

        if maxPage <= 1 then
            self.dynamicPagination = false;
            self.numPageButtons = 0;
            return 1
        end

        local buttonWidth = self.pageButtonWidth;
        local buttonGap = self.pageButtonGap;
        local numButtons;
        if maxPage > MAX_PAGE_BUTTONS then
            numButtons = MAX_PAGE_BUTTONS;
            self.dynamicPagination = true;
        else
            numButtons = maxPage;
            self.dynamicPagination = false;
        end
        self.numPageButtons = numButtons;

        local fullWidth = (buttonWidth + buttonGap) * numButtons - buttonGap;
        local fromOffsetX = -0.5 * fullWidth;

        for i = 1, numButtons do
            local button = self.pageButtonPool:Acquire();
            button.index = i;
            button:SetPage(i);
            button:SetObjectSize(buttonWidth);
            button:SetPoint("LEFT", self.HeaderDivider, "CENTER", fromOffsetX + (i - 1) * (buttonWidth + buttonGap), 0);
            button:SetSelected(i == 1);
        end

        self:SetCurrentPage(1);

        return numButtons
    end

    function HeaderFrameMixin:UpdatePageButtons()
        local page = self.currentPage;
        if self.dynamicPagination then
            local leftMostPage = math.max(1, page - 4);  --(MAX_PAGE_BUTTONS - 1)/2
            if leftMostPage == 1 then
                for index, button in self.pageButtonPool:EnumerateActive() do
                    if index == MAX_PAGE_BUTTONS then
                        button:SetPage(self.maxPage);
                    else
                        button:SetPage(index);
                    end
                end
            else
                local rightMostPage = page + 4;
                if rightMostPage >= self.maxPage then
                    for index, button in self.pageButtonPool:EnumerateActive() do
                        if index == 1 then
                            button:SetPage(1);
                        else
                            button:SetPage(self.maxPage + index - MAX_PAGE_BUTTONS);
                        end
                    end
                else
                    for index, button in self.pageButtonPool:EnumerateActive() do
                        if index == 1 then
                            button:SetPage(1);
                        elseif index == MAX_PAGE_BUTTONS then
                            button:SetPage(self.maxPage);
                        else
                            button:SetPage(page + index - 5);   --Set the center button to current page
                        end
                    end
                end
            end
        end

        local function SetPageButtonSelected(pageButton)
            pageButton:SetSelected(pageButton.page == page);
        end
        self.pageButtonPool:ProcessActiveObjects(SetPageButtonSelected);
    end

    function HeaderFrameMixin:SetCurrentPage(page)
        if page ~= self.currentPage then
            self.currentPage = page;
            self:UpdatePageButtons();
        end
    end

    function HeaderFrameMixin:SetPageButtonSize(buttonWidth, buttonGap)
        self.pageButtonWidth = buttonWidth;
        self.pageButtonGap = buttonGap;
    end

    function HeaderFrameMixin:ReleaseAllObjects()
        self.pageButtonPool:Release();
    end

    function HeaderFrameMixin:SetUITexture(file)
        self.textureFile = file;
        if self.pageButtonPool then
            local function SetBackGround(pageButton)
                pageButton:SetUITexture(file);
            end
            self.pageButtonPool:ProcessAllObjects(SetBackGround);
        end
    end

    function HeaderFrameMixin:SetPageTextColor(selectedColor, nomralColor)
        PAGE_SELECTED_COLOR = selectedColor;
        PAGE_NORMAL_COLOR = nomralColor;

        if self.pageButtonPool then
            local function SetPageButtonSelected(pageButton)
                if pageButton.selected then
                    ThemeUtil:SetFontColor(pageButton.PageText, PAGE_SELECTED_COLOR);
                else
                    ThemeUtil:SetFontColor(pageButton.PageText, PAGE_NORMAL_COLOR);
                end
            end
            self.pageButtonPool:ProcessActiveObjects(SetPageButtonSelected);
        end
    end

    function HeaderFrameMixin:QueryLetterSender(itemGUID)
        self.itemGUID = itemGUID;
        local tooltipData = itemGUID and addon.TooltipAPI.GetItemByGUID(itemGUID);
        if tooltipData then
            self.dataInstanceID = tooltipData.dataInstanceID;
            if self.dataInstanceID then
                self:RegisterEvent("TOOLTIP_DATA_UPDATE");
                self:SetScript("OnEvent", self.OnEvent);
                self:ProcessTooltipData(tooltipData);
            end
        else
            self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
        end
    end

    function HeaderFrameMixin:ProcessTooltipData(tooltipData)
        local line2 = tooltipData.lines and tooltipData.lines[2];
        if line2 and line2.leftColor and line2.leftColor.r == 1 and line2.leftColor.g == 1 and line2.leftColor.b == 1 then
            self.Location:SetText(line2.leftText);
            self.Location:Show();
        end
    end

    function HeaderFrameMixin:OnEvent(event, ...)
        if event == "TOOLTIP_DATA_UPDATE" then
            local dataInstanceID = ...
            if dataInstanceID and dataInstanceID == self.dataInstanceID then
                self:QueryLetterSender(self.itemGUID);
            end
        end
    end

    function HeaderFrameMixin:OnHide()
        self.dataInstanceID = nil;
        self.itemGUID = nil;
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    end


    function BookComponent:InitHeader(headerFrame)
        local Title = headerFrame:CreateFontString(nil, "OVERLAY", "DUIFont_Book_Title");
        headerFrame.Title = Title;
        Title:SetJustifyH("CENTER");
        Title:SetJustifyV("TOP");
        Title:SetMaxLines(2);
        Title:SetSpacing(TITLE_SPACING);
        Title:SetPoint("TOP", headerFrame, "TOP", 0, 0);

        local Location = headerFrame:CreateFontString(nil, "OVERLAY", "DUIFont_Book_10");
        headerFrame.Location = Location;
        Location:SetJustifyH("CENTER");
        Location:SetJustifyV("TOP");
        Location:SetPoint("BOTTOM", Title, "TOP", 0, 9);

        Mixin(headerFrame, HeaderFrameMixin);
        headerFrame:SetScript("OnHide", headerFrame.OnHide);


        local function PageButton_OnClick(f)
            local MainFrame = headerFrame:GetParent();
            if f.page == 1 then
                MainFrame:ScrollTo(0);
            else
                MainFrame:ScrollToPage(f.page);
            end
            MainFrame.ScrollFrame.paginationTimer = 1;  --Update pagination immediately
        end

        local function CreatePageButton()
            local button = CreateFrame("Button", nil, headerFrame, "DUIBookPageButtonTemplate");
            Mixin(button, PageButtonMixin);
            button:SetScript("OnEnter", button.OnEnter);
            button:SetScript("OnLeave", button.OnLeave);
            button:SetScript("OnClick", PageButton_OnClick);
            button.Background:SetTexCoord(844/1024, 884/1024, 1564/2048, 1604/2048);
            button.Highlight:SetTexCoord(908/1024, 948/1024, 1564/2048, 1604/2048);
            return button
        end

        local function RemovePageButton(pageButton)
            pageButton:Hide();
            pageButton:ClearAllPoints();
        end

        local function OnAcquirePageButton(pageButton)
            pageButton:SetUITexture(headerFrame.textureFile);
        end

        headerFrame.pageButtonPool = API.CreateObjectPool(CreatePageButton, RemovePageButton, OnAcquirePageButton);
    end
end


do  --Location (Show location for GameObject)
    local GetBestMapForUnit = C_Map.GetBestMapForUnit;
    local GetMapInfo = C_Map.GetMapInfo;
    local GetPlayerMapPosition = C_Map.GetPlayerMapPosition;
    local GetMinimapZoneText = GetMinimapZoneText;

    local FORMAT_MAP_COORD = "%s  %.0f, %.0f";

    function BookComponent:GetPlayerLocation()
        local uiMapID = GetBestMapForUnit("player");
        local mapName, x, y;
        if uiMapID then
            local mapInfo = GetMapInfo(uiMapID);
            if mapInfo then
                mapName = mapInfo.name;
            end
            local position = GetPlayerMapPosition(uiMapID, "player");
            if position then
                x = position.x;
                y = position.y;
            end
        end

        if not mapName then
            mapName = GetMinimapZoneText();
        end

        if x and y then
            x = x * 100;
            y = y * 100;
            return string.format(FORMAT_MAP_COORD, mapName, x, y)
        else
            return mapName
        end
    end
end


do  --ItemButton (Show item's description lore "")
    local match = string.match;
    local GetItemByID = addon.TooltipAPI.GetItemByID;
    local SourceItemButtonMixin = {};

    function SourceItemButtonMixin:SetItem(itemID)
        self.queryTimes = 0;
        self.itemID = itemID;

        if itemID then
            local tooltipData = GetItemByID(itemID);
            if tooltipData then
               self:ProcessTooltipData(tooltipData);
            else
                self:ClearAll();
            end
        else
            self:ClearAll();
        end
    end

    function SourceItemButtonMixin:ProcessTooltipData(tooltipData)
        self:SetScript("OnUpdate", nil);
        self.t = nil;

        if not (tooltipData and tooltipData.lines) then
            self:ClearAll();
            return
        end

        local line, description;
        local numLines = #tooltipData.lines;

        for i = numLines, 2, -1 do
            line = tooltipData.lines[i];
            if line.leftText and line.type ~= 20 then
                if match(line.leftText, "^[\"“]") then
                    description = line.leftText;
                    break
                end
            end
        end

        if description then
            self:DisplayItemDescription(self.itemID, description);
        else
            if self.queryTimes > 2 then
                self:ClearAll();
            else
                self.queryTimes = self.queryTimes + 1;
                self.t = 0;
                self:SetScript("OnUpdate", self.OnUpdate);
            end
        end
    end

    function SourceItemButtonMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.2 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            local tooltipData = self.itemID and GetItemByID(self.itemID);
            self:ProcessTooltipData(tooltipData);
        end
    end

    function SourceItemButtonMixin:DisplayItemDescription(itemID, description)
        local icon = C_Item.GetItemIconByID(itemID);
        self.ItemIcon:SetTexture(icon);
        self.ItemText:SetText(description);
        self.ItemBorder:Show();
        self.ItemIcon:Show();
        self.ItemText:Show();
        self.TextBackground:Show();
        self:Layout();
        ThemeUtil:SetFontColor(self.ItemText, "DarkModeGrey70");
        self.ItemText:SetShadowOffset(1, -1);
        self.ItemText:SetShadowColor(0, 0, 0);
    end

    function SourceItemButtonMixin:SetWidgetSize(borderSize, iconSize, borderEffectiveSize, fontSize, maxTextWidth)
        self.ItemBorder:SetSize(borderSize, borderSize);
        self.ItemIcon:SetSize(iconSize, iconSize);
        self.borderEffectiveSize = borderEffectiveSize;
        self.fontSize = fontSize;
        self.ItemText:SetWidth(maxTextWidth);
        if self:IsShown() then
            self:Layout();
        end
    end

    function SourceItemButtonMixin:SetTextSpacing(spacing)
        self.ItemText:SetSpacing(spacing);
    end

    function SourceItemButtonMixin:Layout()
        local borderSize = self.borderEffectiveSize;
        local gap = self.fontSize;
        self.ItemBorder:ClearAllPoints();
        self.ItemBorder:SetPoint("CENTER", self, "LEFT", 0.5*borderSize, 0);
        self.ItemText:ClearAllPoints();
        self.ItemText:SetPoint("LEFT", self.ItemBorder, "RIGHT", gap, 0);
        local textWidth = self.ItemText:GetWrappedWidth();
        local textHeight = self.ItemText:GetHeight();
        self.TextBackground:SetSize(textWidth + 2*gap, textHeight + 2*gap);
        self.TextBackground:ClearAllPoints();
        self.TextBackground:SetPoint("LEFT", self.ItemText, "LEFT", -gap, 0);
        self:SetSize(API.Round(borderSize + 2 * gap + textWidth), API.Round(math.max(textHeight, borderSize)));
    end

    function SourceItemButtonMixin:ClearDisplay()
        self.ItemBorder:Hide();
        self.ItemIcon:Hide();
        self.ItemText:Hide();
        self.TextBackground:Hide();
    end

    function SourceItemButtonMixin:ClearAll()
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        self:ClearDisplay();
    end

    function SourceItemButtonMixin:OnHide()
        if self.t then
            self:ClearAll();
        end
    end

    function SourceItemButtonMixin:SetTexture(file)
        self.ItemBorder:SetTexture(file);
    end

    function BookComponent:CreateSourceItemButton(parent)
        local f = CreateFrame("Frame", nil, parent, "DUIBookItemButtonTemplate");
        f.TextBackground:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/NameplateDialogShadow.png");
        f.ItemIcon:SetTexCoord(0.0625, 0.9275, 0.0625, 0.9275);
        f.ItemBorder:SetTexCoord(768/1024, 864/1024, 1616/2048, 1712/2048);
        f.fontSize = 14;
        f.borderEffectiveSize = 64;
        API.Mixin(f, SourceItemButtonMixin);
        f:SetScript("OnHide", f.OnHide);
        return f
    end
end