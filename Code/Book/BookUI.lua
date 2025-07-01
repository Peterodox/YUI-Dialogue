local _, addon = ...
local API = addon.API;
local L = addon.L;
local BookComponent = addon.BookComponent;
local GetDBBool = addon.GetDBBool;
local CallbackRegistry = addon.CallbackRegistry;
local TTSUtil = addon.TTSUtil;
local BindingUtil = addon.BindingUtil;
local SwipeEmulator = addon.SwipeEmulator;
local FadeHelper = addon.UIParentFadeHelper;
local Round = API.Round;
local FadeFrame = API.UIFrameFade;


local MainFrame;
local EL = CreateFrame("Frame");    --EventListener
local Formatter = {};               --Format content, convert html to fontstring
local Cache = CreateFrame("Frame"); --Cache the whole book when opened


local InCombatLockdown = InCombatLockdown;
local UnitGUID = UnitGUID;
local IsShiftKeyDown = IsShiftKeyDown;
local GetBindingAction = GetBindingAction;
local match = string.match;
local find = string.find;
local gsub = string.gsub;
local GetItemIDByGUID = C_Item.GetItemIDByGUID;     --Not in Classic

local CloseItemText = CloseItemText;
local ItemTextGetCreator = ItemTextGetCreator;
local ItemTextGetItem = ItemTextGetItem;
local ItemTextGetMaterial = ItemTextGetMaterial;
local ItemTextGetText = ItemTextGetText;
local ItemTextGetPage = ItemTextGetPage;
local ItemTextHasNextPage = ItemTextHasNextPage;
local ItemTextPrevPage = ItemTextPrevPage;
local ItemTextNextPage = ItemTextNextPage;
local ItemTextIsFullPage = ItemTextIsFullPage;  --Retail? material == "ParchmentLarge"



-- User Settings

------------------


local PIXEL_SCALE = 0.53333;
local FRAME_SIZE_MULTIPLIER = 1.0;  --(See DialogueUI.lua) 1.1 / 1.25
local WOW_PAGE_WIDTH = 412; --ParchmentLarge
local OTHER_CONTENT_ALPHA = 0.4;


local TagFonts = {
    ["p"] = "DUIFont_Book_Paragraph",
    ["h1"] = "DUIFont_Book_H1",
    ["h2"] = "DUIFont_Book_H2",
    ["h3"] = "DUIFont_Book_H3",
    ["title"] = "DUIFont_Book_Title",
    ["smallprint"] = "DUIFont_Book_10",
};

local RawSize = {   --Unit: Pixel
    FRAME_WIDTH = 768,
    FRAME_HEIGHT_MAX = 896,
    FRAME_HEIGHT_MIN = 192,
    FRAME_TOP_HEIGHT = 64,
    FRAME_BOTTOM_HEIGHT = 88,

    PIECE_WIDTH = 1024,
    PIECE_HEIGHT_FULL = 1152,
    PIECE_TOP_HEIGHT = 192,
    PIECE_TOP_OFFSET = 128,
    PIECE_BOTTOM_HEIGHT = 256,
    PIECE_BOTTOM_OFFSET = -128,
    PIECE_BOTTOM_OVERLAP = -40,

    PADDING_H = 60,     --To the left/right
    PADDING_V = 90,     --To the top/bottom

    CLOSE_BUTTON_OFFSET = 26,
    CLOSE_BUTTON_SIZE = 64,

    HEADER_DIVIDER_HEIGHT = 32,
    FOOTER_DIVIDER_HEIGHT = 32,

    HEADER_OVERLAP_HEIGHT = 80,
    HEADER_DIVIDER_BELOW_TITLE = -46,

    PAGE_BUTTON_SIZE = 40,
    PAGE_BUTTON_GAP = 2,

    ITEM_BORDER_SIZE = 96,
    ITEM_BORDER_EFFECTIVE_SIZE = 80,
    ITEM_ICON_SIZE = 64,
};

local ConvertedSize = {};

local function CalculateSizeData()
    local a = PIXEL_SCALE * FRAME_SIZE_MULTIPLIER;
    for k, v in pairs(RawSize) do
        ConvertedSize[k] = a * v;
    end

    ConvertedSize.FRAME_SHRINK_RANGE = a * (RawSize.FRAME_HEIGHT_MAX - RawSize.FRAME_TOP_HEIGHT - RawSize.FRAME_BOTTOM_HEIGHT);
    ConvertedSize.CONTENT_WIDTH = a * (RawSize.FRAME_WIDTH - 2*RawSize.PADDING_H);

    Formatter.UtilityFontString:SetWidth(ConvertedSize.CONTENT_WIDTH);
end


local function GetObjectTypeAndID(guid)
    local type = match(guid, "^(%a+)%-");
    if type == "GameObject" then
        local id = match(guid, "GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)");
        if id then
            return type, tonumber(id)
        end
    elseif type == "Item" then
        if GetItemIDByGUID then
            local itemID = GetItemIDByGUID(guid);
            return type, itemID, itemID
        else
            return type, guid
        end
    end
end

local function IsMultiPageBook()
    local page = ItemTextGetPage();
    local hasNext = ItemTextHasNextPage();
    return (page == 1 and hasNext) or (page > 1)
end


do  --Cache
    Cache.data = {};

    function Cache:ClearObjectCache()
        self.activeData = nil;
        self.fullyCached = false;
        self:SetScript("OnUpdate", nil);
    end

    function Cache:SetActiveObject(objectType, objectID, itemID)
        --objectType: item, npc
        --objectID: itemID, creatureID
        --itemID: Nilable, retail only

        self:SetScript("OnUpdate", nil);

        local isObjectChanged;
        local identifier;
        local objectLocation;

        if objectType and objectID then
            identifier = objectType..objectID;
            isObjectChanged = identifier ~= self.identifier;
            self.identifier = identifier;
            if objectType == "GameObject" then
                objectLocation = BookComponent:GetPlayerLocation();
            end
        else
            identifier = "unknown";
            isObjectChanged = true;
            self.identifier = nil;
        end

        local data = {
            pageTexts = {},         --[page] = rawText
            fullyCached = false,
            maxPage = 1,
            pageStartOffset = {},   --[page] = offsetY,
            maxContentIndex = 0,
            location = objectLocation,
            title = ItemTextGetItem(),
            itemID = itemID,
            formattedContent = {
                --[index] = {
                --  text = text,
                --  fontTag = tag,
                --  image = image,
                --  width = width, height =  height\
                --  align = number (1 left 2 center 3 right)
                --  posY = offsetY
                --}
            },
        };

        self.activeData = data;
        self.fullyCached = false;
        self.needTurnBack = false;

        return isObjectChanged
    end

    function Cache:GetLastPagePosition()
        if not (self.identifier and self.pagePositions) then return end;
        return self.pagePositions[self.identifier]
    end

    function Cache:SavePagePosition()
        if not self.identifier then return end;
        if not self.pagePositions then
            self.pagePositions = {};
        end

        local id = self.identifier;
        local offset = MainFrame.ScrollFrame:GetVerticalScroll();
        --ScrollOffset is affected by FrameScale and FontSize, we clear pagePositions if these parameters changed
        self.pagePositions[id] = offset;
    end

    function Cache:IsCurrentObjectFullyCached()
        return self.fullyCached
    end

    function Cache:IsMultiPageBook()
        if self.activeData then
            return self.activeData.maxPage > 1
        else
            IsMultiPageBook();
        end
    end

    function Cache:GetMaxPage()
        return self.activeData and self.activeData.maxPage or 1
    end

    function Cache:GetBookLocation()
        return self.activeData and self.activeData.location
    end

    function Cache:GetCurrentItemID()
        return self.activeData and self.activeData.itemID
    end

    function Cache:OnUpdate_TurnNextPage(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.016 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            ItemTextNextPage();
            self.needTurnBack = false;
        end
    end

    function Cache:RequestTurnNextPage()
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_TurnNextPage);
    end

    function Cache:OnUpdate_TurnPrevPage(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.016 then
            self.t = 0;
            ItemTextPrevPage();
            local page = ItemTextGetPage();
            if page <= 1 then
                self:SetScript("OnUpdate", nil);
                self.needTurnBack = false;
                self:BeginCalculateTextHeight();
            end
        end
    end

    function Cache:RequestTurnPrevPage()
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_TurnPrevPage);
    end

    function Cache:CacheCurrentPage()
        local page = ItemTextGetPage();
        local rawText = ItemTextGetText(page);  --No argument required. This for test purpose.
        self.activeData.pageTexts[page] = rawText;

        if ItemTextHasNextPage() then
            self:RequestTurnNextPage();
        else
            self.activeData.maxPage = page;
            self.activeData.fullyCached = true;
            self.fullyCached = true;
            if page >  1 then
                self.needTurnBack = true;
            else
                self.needTurnBack = false;
            end

            self:BeginCalculateTextHeight();
        end
    end

    function Cache:EnumeratePageTexts()
        if self.activeData then
            return ipairs(self.activeData.pageTexts);
        else
            return ipairs({})
        end
    end

    function Cache:EnumerateFormattedContent()
        if self.activeData then
            return ipairs(self.activeData.formattedContent)
        else
            return ipairs({});
        end
    end

    function Cache:CalculateFullContentHeight(fromOffsetY, removePagePadding)
        local offsetY = fromOffsetY;
        local page = 0;

        for i, v in Cache:EnumerateFormattedContent() do
            if v.text then
                offsetY = offsetY + v.spacingAbove;
                if v.isPageStart then
                    page = page + 1;
                    Cache:SetPageStartOffset(page, offsetY);
                end
                v.offsetY = offsetY;
                offsetY = Round(offsetY + v.textHeight + v.spacingBelow);
                v.endingOffsetY = offsetY;
            elseif v.image then
                offsetY = offsetY + v.spacingAbove;
                if v.isPageStart then
                    page = page + 1;
                    Cache:SetPageStartOffset(page, offsetY);
                end
                v.offsetY = offsetY;
                offsetY = Round(offsetY + v.height);
                v.endingOffsetY = offsetY;
            end
        end

        return offsetY
    end

    function Cache:GetMaxContentIndex()
        if self.activeData then
            return self.activeData.maxContentIndex
        else
            return 0
        end
    end

    function Cache:OnUpdate_CalculateTextHeight(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.0 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            for i = 1, 10 do
                self.fromContentIndex = self.fromContentIndex + 1;

                if self.fromContentIndex <= self.toContentIndex then
                    local data = self.activeData.formattedContent[self.fromContentIndex];
                    if data.text then
                        local height = Formatter:GetTextHeight(data.fontTag, data.text);
                        data.textHeight = height;
                    end
                else
                    MainFrame:ShowUI();
                    return
                end
            end
            self:SetScript("OnUpdate", self.OnUpdate_CalculateTextHeight);
        end
    end

    function Cache:BeginCalculateTextHeight()
        local title = self.activeData.title;   --"The Dark Portal and the Fall of Stormwind"
        MainFrame.Header:SetTitle(title);
        Formatter.titleText = title;

        local addPagePadding = IsMultiPageBook();
        local maxPage = Cache:GetMaxPage();

        for page, rawText in Cache:EnumeratePageTexts() do
            Cache:FlagNextContentIsPageStart();
            Formatter:FormatText(rawText);
            if addPagePadding and (page ~= maxPage) then
                Cache:AddSpacerToLastContent(Formatter.PAGE_SPACING);
            end
        end

        self:CalculateTextHeight();
    end

    function Cache:CalculateTextHeight()
        --OnSettingsChanged
        MainFrame:ReleaseAllObjects();
        self.t = 0;
        self.fromContentIndex = 0;
        self.toContentIndex = self:GetMaxContentIndex();
        self:SetScript("OnUpdate", self.OnUpdate_CalculateTextHeight);
    end

    function Cache:StoreText(fontTag, text, justifyH, spacingBelow)
        local index = self.activeData.maxContentIndex + 1;
        self.activeData.maxContentIndex = index;

        justifyH = justifyH or "LEFT";
        if justifyH == "right" then
            --Treat right-alignment as middle unless we encounter some edge cases (issue#98)
            justifyH = "CENTER";
        end

        local spacingAbove = 0;
        if self.spacingPending then
            spacingAbove = self.spacingPending;
            self.spacingPending = nil;
        end

        local isPageStart;
        if self.nextContentIsPageStart then
            self.nextContentIsPageStart = nil;
            isPageStart = true;
        end

        self.activeData.formattedContent[index] = {
            text = text,
            align = justifyH,
            fontTag = fontTag,
            spacingBelow = spacingBelow or 0,
            spacingAbove = spacingAbove,
            isPageStart = isPageStart,
        };
    end

    function Cache:RemoveLastTextSpacingBelow()
        local index = self.activeData and self.activeData.maxContentIndex;
        if index and self.activeData.formattedContent[index] then
            self.activeData.formattedContent[index].spacingBelow = 0;
        end
    end

    function Cache:StoreImage(file, align, width, height, left, right, top, bottom)
        local index = self.activeData.maxContentIndex + 1;
        self.activeData.maxContentIndex = index;

        align = align or "CENTER";

        local spacingAbove = 0;
        if self.spacingPending then
            spacingAbove = self.spacingPending;
            self.spacingPending = nil;
        end

        local isPageStart;
        if self.nextContentIsPageStart then
            self.nextContentIsPageStart = nil;
            isPageStart = true;
        end

        self.activeData.formattedContent[index] = {
            image = file,
            align = align,
            width = width,
            height = height,
            left = left,
            right = right,
            top = top,
            bottom = bottom,
            spacingBelow = 0,
            spacingAbove = spacingAbove,
            isPageStart = isPageStart,
        };
    end

    function Cache:AddSpacerToLastContent(height)
        local index = self.activeData.maxContentIndex;
        local data = self:GetContentDataByIndex(index);
        if data then
            data.spacingBelow = data.spacingBelow + height;
        end
    end

    function Cache:AddSpacerToNextContent(height)
        if self.spacingPending then
            self.spacingPending = self.spacingPending + height;
        else
            self.spacingPending = height;
        end
    end

    function Cache:FlagNextContentIsPageStart()
        self.nextContentIsPageStart = true;
    end

    function Cache:SetPageStartOffset(page, offsetY)
        if self.activeData then
            self.activeData.pageStartOffset[page] = offsetY;
        end
    end

    function Cache:GetPageStartOffset(page)
        if self.activeData then
            return self.activeData.pageStartOffset[page] or 0
        end
    end

    function Cache:GetContentDataByIndex(contentIndex)
        if self.activeData and self.activeData.formattedContent[contentIndex] then
            return self.activeData.formattedContent[contentIndex]
        end
    end

    function Cache:GetFormattedContent()
        if self.activeData then
            return self.activeData.formattedContent
        else
            return {}
        end
    end

    function Cache:GetRawContent(concatnate)
        --For clipboard
        if self.activeData then
            if concatnate then
                local text = self.activeData.title or "";
                local itemID = self:GetCurrentItemID();
                if itemID then
                    text = text.."\n[itemID:"..itemID.."]";
                else
                    local location = self:GetBookLocation();
                    if location then
                        text = text.."\n"..location;
                    end
                end
                local addPager = #self.activeData.pageTexts > 1;
                for page, rawText in ipairs(self.activeData.pageTexts) do
                    if addPager then
                        text = text.."\n\n"..page.."\n"..rawText;
                    else    --one page
                        text = text.."\n\n"..rawText;
                    end
                end
                return text
            else
                return self.activeData.pageTexts
            end
        end
    end
end


DUIBookUIMixin = {};

do  --Background Calculation \ Theme
    local TextureKit = {
        [1] = {file = "Parchment.png", textColor = {0.19, 0.17, 0.13}, pageSelectedColor = "Ivory", pageNormalColor = "LightBrown", shadow = false, widgetTheme = 3},
        [2] = {file = "Metal.png", textColor = {0.8, 0.8, 0.8}, pageSelectedColor = "DarkModeGrey90", pageNormalColor = "DarkModeGrey70", shadow = true, widgetTheme = 4},
    };

    function DUIBookUIMixin:SetTextureKit(textureKitID)
        if textureKitID and TextureKit[textureKitID] and textureKitID ~= self.textureKitID then
            local info = TextureKit[textureKitID];
            local file = string.format("Interface/AddOns/DialogueUI/Art/Book/TextureKit-"..info.file);

            self.textureKitID = textureKitID;
            self.textureFile = file;
            self.widgetTheme = info.widgetTheme;

            if self.BackgroundPieces then
                for _, obj in pairs(self.BackgroundPieces) do
                    obj:SetTexture(file);
                end
            end

            if self.CloseButton then
                self.CloseButton:SetUITexture(file);
            end

            self.Header:SetUITexture(file);
            self.Header.HeaderScrollOverlap:SetTexture(file);
            self.Header.HeaderScrollOverlap:SetTexCoord(128/1024, 896/1024, 1408/2048, 1488/2048);

            self.Footer.FooterDivider:SetTexture(file);
            self.Footer.FooterDivider:SetTexCoord(0, 768/1024, 1488/2048, 1520/2048);

            self.Header.HeaderDivider:SetTexture(file);
            self.Header.HeaderDivider:SetTexCoord(0, 768/1024, 1520/2048, 1552/2048);

            local r, g, b = unpack(info.textColor);
            local useShadow = info.shadow;
            local fontObject;

            for tag, fontObjectName in pairs(TagFonts) do
                fontObject = _G[fontObjectName];
                if tag == "smallprint" then
                    addon.ThemeUtil:SetFontColor(fontObject, info.pageNormalColor);
                else
                    fontObject:SetTextColor(r, g, b);
                end
                if useShadow then
                    fontObject:SetShadowOffset(0, 2);
                    fontObject:SetShadowColor(0, 0, 0);
                else
                    fontObject:SetShadowOffset(0, 0);
                end
            end

            self.Header:SetPageTextColor(info.pageSelectedColor, info.pageNormalColor);

            if self.TTSButton then
                self.TTSButton:SetTheme(info.widgetTheme);
            end

            if self.CopyTextButton then
                self.CopyTextButton:SetTheme(info.widgetTheme);
            end

            if self.SourceItemButton then
                self.SourceItemButton:SetTexture(file);
            end
        end
    end

    function DUIBookUIMixin:SetFrameHeight(height, scrollable)
        local p = self.BackgroundPieces;

        if not p then
            p = {};
            self.BackgroundPieces = p;
            p[1] = self:CreateTexture(nil, "BACKGROUND", nil, -1);
            p[2] = self.Footer:CreateTexture(nil, "OVERLAY", nil, -1);      --We use the bottom texture's upper border to "mask" the text body
        end

        local cs = ConvertedSize;

        if height < cs.FRAME_HEIGHT_MIN then
            height = cs.FRAME_HEIGHT_MIN;
        end

        local isDynamicHeight = (not scrollable) and (height + 8) < cs.FRAME_HEIGHT_MAX;
        local useTwoPieceBG = scrollable or isDynamicHeight;

        if not isDynamicHeight then
            height = cs.FRAME_HEIGHT_MAX;
        end

        if useTwoPieceBG or (useTwoPieceBG ~= self.useTwoPieceBG) then
            p[1]:ClearAllPoints();  --Top Piece
            p[2]:ClearAllPoints();  --Bottom Piece

            if useTwoPieceBG then
                local centralRatio = (height - cs.FRAME_TOP_HEIGHT - cs.FRAME_BOTTOM_HEIGHT) / cs.FRAME_SHRINK_RANGE;
                if centralRatio > 1 then    --Shouldn't happen
                    centralRatio = 1;
                end

                p[1]:SetTexCoord(0, 1, 0, (192 + 744 * centralRatio)/2048);
                p[1]:SetSize(cs.PIECE_WIDTH, cs.PIECE_TOP_HEIGHT);
                p[1]:SetPoint("TOP", self, "TOP", 0, cs.PIECE_TOP_OFFSET);
                p[1]:SetPoint("BOTTOM", p[2], "TOP", 0, cs.PIECE_BOTTOM_OVERLAP);

                p[2]:SetTexCoord(0, 1, 1152/2048, 1408/2048);
                p[2]:SetSize(cs.PIECE_WIDTH, cs.PIECE_BOTTOM_HEIGHT);
                p[2]:SetPoint("BOTTOM", self, "BOTTOM", 0, cs.PIECE_BOTTOM_OFFSET);

                p[2]:Show();
            else    --Use the top piece to display whole background
                height = cs.FRAME_HEIGHT_MAX;

                p[1]:SetTexCoord(0, 1, 0, 1152/2048);
                p[1]:SetSize(cs.PIECE_WIDTH, cs.PIECE_HEIGHT_FULL);
                p[1]:SetPoint("CENTER", self, "CENTER", 0, 0);
                p[2]:Hide();
            end

            self.useTwoPieceBG = useTwoPieceBG;
            self:SetSize(cs.FRAME_WIDTH, height);
        end

        return height
    end

    function DUIBookUIMixin:Reposition()
        local viewportWidth, viewportHeight = API.GetBestViewportSize();
        local distanceToEdge = 48;
        local defaultOffsetX, anchor;
        local vignetteOffset = viewportWidth * 128/896;
        self.ScreenVignette:ClearAllPoints();

        local isLeft = true;

        if isLeft then
            defaultOffsetX = -0.5*viewportWidth + distanceToEdge;
            anchor = "LEFT";
            self.ScreenVignette:SetTexCoord(0, 1, 0, 1);
            self.ScreenVignette:SetPoint("TOPLEFT", nil, "TOP", -0.5*viewportWidth -vignetteOffset, 1);
            self.ScreenVignette:SetPoint("BOTTOMRIGHT", nil, "BOTTOM", 0.5*viewportWidth, -1);
        else
            defaultOffsetX = 0.5*viewportWidth - distanceToEdge;
            anchor = "RIGHT";
            self.ScreenVignette:SetTexCoord(1, 0, 0, 1);
            self.ScreenVignette:SetPoint("TOPLEFT", nil, "TOP", -0.5*viewportWidth, 1);
            self.ScreenVignette:SetPoint("BOTTOMRIGHT", nil, "BOTTOM", 0.5*viewportWidth + vignetteOffset, -1);
        end

        self.defaultOffsetX = defaultOffsetX;
        self.defaultAnchor = anchor;

        self:ClearAllPoints();
        self:SetPoint(anchor, nil, "CENTER", defaultOffsetX, 0);
    end

    function DUIBookUIMixin:UpdateSourceItemButton()
        if self.SourceItemButton then
            local cs = ConvertedSize;
            self.SourceItemButton:SetTextSpacing(Formatter.TEXT_SPACING);
            local maxTextWidth = cs.CONTENT_WIDTH - cs.ITEM_BORDER_EFFECTIVE_SIZE;
            self.SourceItemButton:SetWidgetSize(cs.ITEM_BORDER_SIZE, cs.ITEM_ICON_SIZE, cs.ITEM_BORDER_EFFECTIVE_SIZE, Formatter.FONT_SIZE, maxTextWidth);
        end
    end

    function DUIBookUIMixin:Resize()
        --Resize after base frame/font size change (Small/Medium/Large)
        local cs = ConvertedSize;

        self.ContentFrame:SetSize(cs.FRAME_WIDTH, 64);  --Height doesn't really matter

        if self.CloseButton then
            self.CloseButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -cs.CLOSE_BUTTON_OFFSET, -cs.CLOSE_BUTTON_OFFSET);
            self.CloseButton:SetSize(cs.CLOSE_BUTTON_SIZE, cs.CLOSE_BUTTON_SIZE);
        end

        self.Header.Title:SetWidth(cs.CONTENT_WIDTH);
        self.Header.Title:SetPoint("TOP", self, "TOP", 0, -cs.PADDING_V);

        self.Header.HeaderScrollOverlap:SetSize(cs.FRAME_WIDTH, cs.HEADER_OVERLAP_HEIGHT);
        self.Footer.FooterDivider:SetSize(cs.FRAME_WIDTH, cs.FOOTER_DIVIDER_HEIGHT);
        self.Header.HeaderDivider:SetSize(cs.FRAME_WIDTH, cs.HEADER_DIVIDER_HEIGHT);
        self.Header:SetPageButtonSize(cs.PAGE_BUTTON_SIZE, cs.PAGE_BUTTON_GAP);

        self.Header:SetWidth(cs.CONTENT_WIDTH);
        self:LayoutWidgets();
        self:UpdateSourceItemButton();
    end

    function DUIBookUIMixin:SetScrollContentHeight(contentHeight, maxPage)
        --Determine if the current page can be fully displayed
        --If the page needs to be scrollable nad book has multiple pages, it will scroll down util it reach the bottom, then turn to next page
        --Scroll backwards will scroll to the page's top
        --The Header (including Book Name and Pagination for multi-page) use constant size

        local cs = ConvertedSize;

        local usePagination = maxPage > 1;  --If the book has multiple pages but we can still show all content in a single page, we don't use pagination
        local titleHeight = self.Header:GetTitleHeight();
        local titleLineHeight = self.Header:GetTitleEffectiveLineHeight();
        local titleSpacing = 0.35 * titleLineHeight;
        local heightBelowTitle;
        local heightBelowTitleNoPagi = titleSpacing + 2;

        if usePagination then
            heightBelowTitle = Formatter.PARAGRAPH_SPACING + cs.PAGE_BUTTON_SIZE;
        else
            heightBelowTitle = heightBelowTitleNoPagi;
        end

        local maxContentHeight = cs.FRAME_HEIGHT_MAX - 2*cs.PADDING_V - titleHeight - heightBelowTitle;
        local scrollable = contentHeight > maxContentHeight;

        if not scrollable then
            usePagination = false;
        end

        if maxPage > 1 and not usePagination then
            local offsetY = self:GetContentFromOffsetY(false);
            offsetY = Cache:CalculateFullContentHeight(offsetY);
        end

        if not usePagination then
            heightBelowTitle = heightBelowTitleNoPagi;
            maxPage = 1;
        end

        self.Header:SetHeightBelowTitle(heightBelowTitle);

        --Update Pagination
        local numPageButtons = self.Header:SetMaxPage(maxPage);

        --Adjust Header: padding below title
        local headerOffsetY;

        if usePagination then
            self.Header.HeaderDividerExclusion:Show();
            local buttonSpan = numPageButtons * (cs.PAGE_BUTTON_SIZE + cs.PAGE_BUTTON_GAP) + 3*cs.PAGE_BUTTON_GAP;
            self.Header.HeaderDividerExclusion:SetWidth(buttonSpan);                --Cut HeaderDivider
            self.Header.HeaderDividerExclusion:SetHeight(cs.PAGE_BUTTON_SIZE + 4);
            headerOffsetY = cs.HEADER_DIVIDER_BELOW_TITLE;
            self.Header.HeaderDivider:ClearAllPoints();
            self.Header.HeaderDivider:SetPoint("CENTER", self.Header.Title, "BOTTOM", 0, headerOffsetY);
        else
            self.Header.HeaderDividerExclusion:Hide();
            headerOffsetY = -Formatter.PARAGRAPH_SPACING;
            self.Header.HeaderDivider:ClearAllPoints();
            self.Header.HeaderDivider:SetPoint("CENTER", self, "TOP", 0, -Round(cs.PADDING_V + titleHeight + titleSpacing));
        end

        local headerHeight = self.Header:GetHeaderHeight();
        local totalFrameHeight = headerHeight + contentHeight + 2*cs.PADDING_V;
        local frameHeight = self:SetFrameHeight(totalFrameHeight, scrollable);
        local scrollRange;

        --debug
        --self.DebugArea:ClearAllPoints();
        --self.DebugArea:SetSize(32, contentHeight);
        --self.DebugArea:SetPoint("TOP", self.ContentFrame, "TOP", 0, 0);

        self.ScrollFrame:ClearAllPoints();
        self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0,  -cs.PADDING_V - headerHeight);
        self.ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, cs.PADDING_V);

        if scrollable then
            self.ContentFrame:SetParent(self.ScrollFrame.ScrollChild);
            self.ContentFrame:SetPoint("TOPLEFT", self.ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
            self.ContentFrame:SetFrameLevel(self.ScrollFrame.ScrollChild:GetFrameLevel());
            local scrollFrameHeight = self.ScrollFrame:GetHeight();
            scrollRange = Round(contentHeight + Formatter.PAGE_SPACING - scrollFrameHeight);
            self:SetScript("OnMouseWheel", self.OnMouseWheel);
        else
            scrollRange = 0;
            self.ContentFrame:SetParent(self);
            self.ContentFrame:SetPoint("TOP", self, "TOP", 0, -cs.PADDING_V - headerHeight);
            self.ContentFrame:SetFrameLevel(self.Footer:GetFrameLevel() + 10);
            self:SetScript("OnMouseWheel", nil);
        end

        self.scrollable = scrollable;
        self.ScrollFrame:SetScrollRange(scrollRange);
        self.ScrollFrame:SetUseOverlapBorder(scrollable, scrollable);

        self.Header:SetHeight(Round(headerHeight));
        SwipeEmulator:SetScrollable(scrollable, self.ScrollFrame);
    end
end

do  --Scroll Anim
    --Tested on 120Hz, displaying all fontstrings at the same time don't have performance issue
    --So should I still recycle objects that are out of viewport?

    function DUIBookUIMixin:ResetScroll()
        self.ScrollFrame:ResetScroll();
    end

    function DUIBookUIMixin:IsAtPageTop()
        if self.scrollable then
            return self.ScrollFrame:IsAtPageTop();
        else
            return true
        end
    end

    function DUIBookUIMixin:IsAtPageBottom()
        if self.scrollable then
            return self.ScrollFrame:IsAtPageBottom();
        else
            return true
        end
    end

    function DUIBookUIMixin:OnMouseWheel(delta)
        if not Cache:IsCurrentObjectFullyCached() then
            return
        end

        if delta > 0 then
            if IsShiftKeyDown() then
                self:ScrollToNearPrevPage();
            else
                self:ScrollBy(-Formatter.OFFSET_PER_SCROLL);
            end
        else
            if IsShiftKeyDown() then
                self:ScrollToNearNextPage();
            else
                self:ScrollBy(Formatter.OFFSET_PER_SCROLL);
            end
        end
    end

    function DUIBookUIMixin:ScrollBy(deltaValue)
        self.ScrollFrame:ScrollBy(deltaValue);
    end

    function DUIBookUIMixin:ScrollTo(value)
        self.ScrollFrame:ScrollTo(value);
    end

    function DUIBookUIMixin:ScrollToContent(contentIndex)
        --Move content to the top if possible
        local data = Cache:GetContentDataByIndex(contentIndex);
        if data then
            local offsetY = data.offsetY;
            offsetY = offsetY - self.scrollFromOffetY;
            self:ScrollTo(offsetY);
        end
    end

    function DUIBookUIMixin:ScrollToPage(page)
        local maxPage = Cache:GetMaxPage();
        if page > maxPage then
            page = maxPage;
        end

        if page == 1 then
            self:ScrollTo(0);
            return
        end

        local offsetY = Cache:GetPageStartOffset(page);
        if offsetY then
            offsetY = offsetY - self.scrollFromOffetY;
            self:ScrollTo(offsetY);
        end
    end

    function DUIBookUIMixin:GetCurrentPage()
        --We consider the new page as the current one when it reach the x% of the frame
        local offset = self.ScrollFrame:GetScrollTarget() + self.scrollFromOffetY + 0.4*self.ScrollFrame:GetViewSize();
        local maxPage = Cache:GetMaxPage();

        local pageOffset;

        if self.ScrollFrame:IsAtPageTop() then
            return 1
        end

        if self.ScrollFrame:IsAtPageBottom() then
            return maxPage
        end

        for page = maxPage, 1, -1 do
            pageOffset = Cache:GetPageStartOffset(page);
            if offset > pageOffset then
                return page
            end
        end

        return 1
    end

    function DUIBookUIMixin:ScrollToNearNextPage()
        local offset = self.ScrollFrame:GetScrollTarget() + self.scrollFromOffetY + 0.1;
        local maxPage = Cache:GetMaxPage();

        local pageOffset;

        for page = 1, maxPage do
            pageOffset = Cache:GetPageStartOffset(page);
            if offset < pageOffset then
                if page == 1 and page < maxPage then
                    page = 2;
                    pageOffset = Cache:GetPageStartOffset(page);
                end
                local offsetY = pageOffset - self.scrollFromOffetY;
                self:ScrollTo(offsetY)
                break
            end
        end
    end

    function DUIBookUIMixin:ScrollToNearPrevPage()
        local offset = self.ScrollFrame:GetScrollTarget() + self.scrollFromOffetY - 0.1;
        local maxPage = Cache:GetMaxPage();

        local pageOffset;

        for page = maxPage, 1, -1 do
            pageOffset = Cache:GetPageStartOffset(page);
            if offset > pageOffset then
                local offsetY;
                if page == 1 then
                    offsetY = 0;
                else
                    offsetY = pageOffset - self.scrollFromOffetY;
                end
                self:ScrollTo(offsetY)
                break
            end
        end
    end
end

do  --Formatter
    local IgnoredTags = {
        ["<br/>"] = true,
        ["</p>"] = true;
        ["<HTML><BODY>"] = true,
        ["</BODY></HTML>"] = true,
    };

    local ValidAlignments = {
        ["left"] = "LEFT",
        ["center"] = "CENTER",
        ["right"] = "RIGHT",
    };

    function Formatter:SetBaseFontSize(baseFontSize)
        self.FONT_SIZE = baseFontSize;
        self.TEXT_SPACING = 0.35 * baseFontSize;        --Recommended Line Height: 1.2 - 1.5
        self.PARAGRAPH_SPACING = 4 * self.TEXT_SPACING;
        self.PAGE_SPACING = 4 * self.PARAGRAPH_SPACING;
        self.OFFSET_PER_SCROLL = Round(4 * (self.FONT_SIZE + self.TEXT_SPACING));

        self.UtilityFontString:SetSpacing(self.TEXT_SPACING);
    end

    function Formatter:AcquireTexture()
        local tex = MainFrame.texturePool:Acquire();
        return tex
    end

    function Formatter:SetFontObjectByTag(fontString, fontTag)
        if not (fontTag and TagFonts[fontTag]) then
            fontTag = "p";
        end
        fontString:SetFontObject(TagFonts[fontTag]);
    end

    function Formatter:AcquireFontStringByTag(fontTag)
        local fs = MainFrame.fontStringPool:Acquire();
        self:SetFontObjectByTag(fs, fontTag);
        return fs
    end

    function Formatter:InsertText(offsetY, text, tag, justifyH)
        --Unused
        --Add no spacing
        local fs = self:AcquireFontStringByTag(tag);
        local textRef = MainFrame.ContentFrame;
        fs:SetPoint("TOP", textRef, "TOP", 0, -offsetY);
        fs:SetJustifyH(justifyH or "LEFT");
        fs:SetText(text);
        local height = fs:GetHeight();
        offsetY = Round(offsetY + height);
        return offsetY, height
    end

    function Formatter:InsertHeader(offsetY, text, tag, justifyH)
        --Unused
        --Add paragrah spacing to the bottom
        local textHeight;
        offsetY, textHeight = self:InsertText(offsetY, text, tag, justifyH);
        offsetY = offsetY  + ConvertedSize.PADDING_H
        return offsetY, textHeight
    end

    function Formatter:InsertParagraph(offsetY, text, tag, justifyH)
        --Unused
        --Add paragrah spacing to the top
        local textHeight;
        offsetY, textHeight = self:InsertText(offsetY + self.PARAGRAPH_SPACING, text, tag, justifyH);
        return offsetY, textHeight
    end

    function Formatter:SetUtilityTextWidth(width)
        self.UtilityFontString:SetWidth(width);
    end

    function Formatter:GetTextHeight(fontTag, text)
        self.UtilityFontString:SetSpacing(Formatter.TEXT_SPACING);
        self.UtilityFontString:SetSize(ConvertedSize.CONTENT_WIDTH, 0);
        if fontTag ~= self.utilityFontTag then
            self.utilityFontTag = fontTag;
            self.UtilityFontString:SetFontObject(TagFonts[fontTag]);
        end
        self.UtilityFontString:SetText(text);
        local height = self.UtilityFontString:GetHeight();
        self.UtilityFontString:SetText(nil);

        return height
    end

    function Formatter:FormatText(text)
        if find(text, "<HTML>") then
            return self:FormatHTML(text)
        else
            return self:FormatParagraph(text)
        end
    end

    function Formatter:FormatParagraph(text)
        local paragraphs = API.SplitParagraph(text);
        local fontTag = "p";
        local align = "LEFT";
        local paragraphSpacing = self.PARAGRAPH_SPACING;
        local numParagraphs = paragraphs and #paragraphs or 0;
        local anyAdded = false;

        if numParagraphs > 0 then
            for i, paragraphText in ipairs(paragraphs) do
                if paragraphText ~= "" then
                    anyAdded = true;
                    Cache:StoreText(fontTag, paragraphText, align, paragraphSpacing);
                end
            end
        else

        end

        if anyAdded then
            Cache:RemoveLastTextSpacingBelow();
        end

        --PP = paragraphs;    --debug
    end

    local function CleanUpTags(text)
        --Remove <>
        text = gsub(text, "^<[^<>]+>", "", 1);
        text = gsub(text, "^<[^<>]+>", "", 1);
        text = gsub(text, "<[^<>]+>$", "", 1);
        text = gsub(text, "<[^<>]+>$", "", 1);
        text = gsub(text, "<[^<>]+>$", "", 1);
        return text
    end

    function Formatter:FormatHTML(text)
        local paragraphs = API.SplitParagraph(text);
        local match = match;
        local lower = string.lower;

        local numTexts = 0;
        local numImages = 0;
        local paragraphSpacing = self.PARAGRAPH_SPACING
        local numParagraphs = paragraphs and #paragraphs or 0;
        local anyAdded = false;

        if numParagraphs > 0 then
            for i, paragraphText in ipairs(paragraphs) do
                if not IgnoredTags[paragraphText] then
                    local tag, align;
                    tag = match(paragraphText, "^</*([%w]+)/*>");
                    if not tag then
                        tag = match(paragraphText, "^<([%w]+)%s");
                    end
                    --print(i, tag)
                    if tag and not IgnoredTags[tag] then
                        tag = lower(tag);

                        if tag == "img" then
                            local file = match(paragraphText, "src=\"([%S]+)\"");   --src=\"([%S]+)\"%s
                            if file then
                                numImages = numImages + 1;
                                local width = match(paragraphText,"width=\"(%d+)");
                                width = width and tonumber(width);
                                local height = match(paragraphText,"height=\"(%d+)");
                                height = height and tonumber(height);
                                align = match(paragraphText,"align=\"(%a+)") or "center";
                                local imageWidth, imageHeight;
                                local left, right, top, bottom = 0, 1, 0, 1;
                                file = lower(file);

                                if not (width and height) then
                                    width, height = BookComponent:GetTextureSize(file);
                                end

                                if not (width and height) then
                                    local ratio, _l, _r, _t, _b = BookComponent:GetTextureCoordForFile(file);   --Check AtlasInfo
                                    if ratio then
                                        imageWidth = ConvertedSize.CONTENT_WIDTH;
                                        imageHeight = ratio * imageWidth;
                                        width = imageWidth;
                                        height = imageHeight;
                                        left, right, top, bottom = _l, _r, _t, _b;
                                    end

                                    if not (width and height) then
                                        if width then
                                            width = math.min(width, ConvertedSize.CONTENT_WIDTH);
                                            height = width;
                                        elseif height then
                                            height = math.min(height, ConvertedSize.CONTENT_WIDTH);
                                            width = height;
                                        end
                                    end
                                end

                                if not (width and height) then
                                    width = ConvertedSize.CONTENT_WIDTH;
                                    height = width;
                                    imageWidth = Round(width * 0.618)
                                    imageHeight = imageWidth;
                                end

                                if width and height then
                                    if file == "interface\\common\\spacer" then
                                        Cache:AddSpacerToNextContent(self.PARAGRAPH_SPACING);
                                    else
                                        if not imageWidth then
                                            local scale = width / WOW_PAGE_WIDTH;
                                            imageWidth = Round(ConvertedSize.CONTENT_WIDTH * scale);
                                            imageHeight = Round(imageWidth * height / width);
                                        end
                                        Cache:StoreImage(file, align, imageWidth, imageHeight, left, right, top, bottom);
                                    end
                                end
                            end
                        else
                            local _;
                            _, align = match(paragraphText, "^<([%w]+)%s+align=\"(%a+)\"");

                            if align then
                                align = lower(align);
                            end

                            if (not align) or (not ValidAlignments[align]) then
                                align = "LEFT";
                            end

                            paragraphText = CleanUpTags(paragraphText);

                            if paragraphText and paragraphText ~= "" then
                                numTexts = numTexts + 1;
                                if numTexts > 1 or (paragraphText ~= self.titleText) then
                                    if not (tag and TagFonts[tag]) then
                                        tag = "p";
                                    end
                                    anyAdded = true;
                                    Cache:StoreText(tag, paragraphText, align, paragraphSpacing);
                                end
                            end
                        end
                    else
                        paragraphText = CleanUpTags(paragraphText);
                        if paragraphText and paragraphText ~= "" then
                            numTexts = numTexts + 1;
                            align = "LEFT";
                            tag = "p";
                            anyAdded = true;
                            Cache:StoreText(tag, paragraphText, align, paragraphSpacing);
                        end
                    end
                end
            end
        else

        end

        if anyAdded then
            Cache:RemoveLastTextSpacingBelow();
        end

        --PP = paragraphs;    --debug
    end

    function DUIBookUIMixin:GetContentFromOffsetY(scrollable)
        local fromOffsetY;
        if scrollable then
            fromOffsetY = Round(ConvertedSize.PADDING_H - Formatter.PARAGRAPH_SPACING);
        else
            fromOffsetY = Round(Formatter.PARAGRAPH_SPACING);
        end
        MainFrame.scrollFromOffetY = fromOffsetY;
        return fromOffsetY
    end

    function DUIBookUIMixin:RebuildContentFromCache()
        --debug
        if not Cache:IsCurrentObjectFullyCached() then
            return
        end

        self:ReleaseAllObjects();

        local maxPage = Cache:GetMaxPage();
        local offsetY = self:GetContentFromOffsetY(maxPage > 1);
        offsetY = Cache:CalculateFullContentHeight(offsetY);
        self:SetScrollContentHeight(offsetY, maxPage);

        self.ScrollFrame:SetContent(Cache:GetFormattedContent());

        local lastOffset = Cache:GetLastPagePosition();
        if lastOffset then
            self.ScrollFrame:SnapTo(lastOffset);
        else
            self:ResetScroll();
        end

        if self.SourceItemButton and GetDBBool("BookUIItemDescription") then
            self:UpdateSourceItemButton();
            self.SourceItemButton:SetItem(Cache:GetCurrentItemID());
        end
        --print("MAX INDEX", Cache:GetMaxContentIndex());
    end

    function DUIBookUIMixin:SetMaxPage(maxPage)

    end
end

do  --Main UI
    function DUIBookUIMixin:OnLoad()
        MainFrame = self;
        addon.BookUI = self;
        self.OnLoad = nil;
        self:SetScript("OnLoad", nil);

        addon.SharedVignette:AddOwner(self);    --"SharedVignette" defined in DialogueUI.lua

        --UtilityFontString is used to evaluate text height
        local UtilityFontString = self.ContentFrame:CreateFontString(nil, "ARTWORK", "DUIFont_Book_Paragraph");
        UtilityFontString:SetJustifyV("TOP");
        --UtilityFontString:SetPoint("TOP", nil, "BOTTOM", 0, -64);
        UtilityFontString:SetPoint("TOP", MainFrame.ContentFrame, "TOP", 0, 0);
        --UtilityFontString:SetIgnoreParentAlpha(true);
        Formatter.UtilityFontString = UtilityFontString;

        CalculateSizeData();
        Formatter:SetBaseFontSize(12);  --debug
        self:SetFrameHeight(480);

        API.SetPlayCutsceneCallback(function()
            self:Hide();
        end);
    end

    function DUIBookUIMixin:Init()
        self.Init = nil;
        self:Reposition();

        BookComponent:InitHeader(self.Header);


        --ScrollFrame
        local ScrollFrame = self.ScrollFrame;
        addon.InitEasyScrollFrame(ScrollFrame, self.Header.HeaderScrollOverlap, self.Footer.FooterDivider);
        addon.InitRecyclableScrollFrame(ScrollFrame);

        function ScrollFrame:SetObjectData(obj, data, contentIndex)
            if not obj then
                if data.text then
                    obj = Formatter:AcquireFontStringByTag(data.fontTag);
                elseif data.image then
                    obj = Formatter:AcquireTexture();
                end
            end

            local offsetX = 0;

            if data.text then
                Formatter:SetFontObjectByTag(obj, data.fontTag);
                obj:SetJustifyH(data.align);
                obj:SetText(data.text);
                offsetX = 0;
            elseif data.image then
                obj:SetSize(data.width, data.height);
                obj:SetTexture(data.image);
                obj:SetTexCoord(data.left, data.right, data.top, data.bottom);
                --[[
                --Always centralize IMG unless we encounter some edge cases (issue#98)
                if data.align == "left" then
                    offsetX = -0.5*(ConvertedSize.CONTENT_WIDTH - data.width);
                elseif data.align == "right" then
                    offsetX = 0.5*(ConvertedSize.CONTENT_WIDTH - data.width);
                else
                    offsetX = 0;
                end
                --]]
                offsetX = 0;
            end

            obj.contentIndex = contentIndex;
            obj:SetPoint("TOP", MainFrame.ContentFrame, "TOP", offsetX, -data.offsetY);
            obj:Show();

            if MainFrame.isReadingContent then
                if data.text then
                    if obj.contentIndex == MainFrame.focusedContentIndex then
                        --obj:SetAlpha(1);
                        FadeFrame(obj, 0, 1);
                    else
                        FadeFrame(obj, 0, OTHER_CONTENT_ALPHA);
                        --obj:SetAlpha(OTHER_CONTENT_ALPHA);
                    end
                end
            end

            return obj
        end

        function ScrollFrame:GetDataRequiredObjectType(data)
            if data.text then
                return "FontString"
            elseif data.image then
                return "Texture"
            end
        end

        function ScrollFrame:UpdatePagination()
            local page = MainFrame:GetCurrentPage();
            MainFrame.Header:SetCurrentPage(page);
        end
        ScrollFrame:SetUsePagination(true);


        --Objecti Pool
        local function CreateFontString()
            local fontString = self.ContentFrame:CreateFontString(nil, "ARTWORK", "DUIFont_Quest_Paragraph");
            fontString:SetSpacing(Formatter.TEXT_SPACING);
            return fontString
        end

        local function RemoveFontString(fontString)
            fontString:SetText(nil);
            fontString:Hide();
            fontString:ClearAllPoints();
        end

        local function OnAcquireFontString(fontString)
            fontString:SetSpacing(Formatter.TEXT_SPACING);
            fontString:SetSize(ConvertedSize.CONTENT_WIDTH, 0);
        end

        self.fontStringPool = API.CreateObjectPool(CreateFontString, RemoveFontString, OnAcquireFontString);


        local function CreateTexture()
            local tex = self.ContentFrame:CreateTexture(nil, "ARTWORK");
            return tex
        end

        local function RemoveTexture(tex)
            tex:SetTexture(nil);
            tex:Hide();
            tex:ClearAllPoints();
        end

        self.texturePool = API.CreateObjectPool(CreateTexture, RemoveTexture);


        self.CloseButton = BookComponent:GetCloseButton(self);

        self:Resize();
        self:SetTextureKit(1);

        self:OnShow();
    end

    function DUIBookUIMixin:ReleaseAllObjects()
        if self.Init then return end;

        self.focusedContentIndex = nil;
        self.fontStringPool:Release();
        self.texturePool:Release();
    end

    function DUIBookUIMixin:OnShow()
        EL:RegisterEvent("PLAYER_REGEN_ENABLED");
        EL:RegisterEvent("PLAYER_REGEN_DISABLED");
        EL.inCombat = InCombatLockdown();
        self:SetScript("OnKeyDown", self.OnKeyDown);
        self:EnableGamePadStick(true);
        self:SetScript("OnGamePadStick", self.OnGamePadStick);
        self:SetScript("OnGamePadButtonDown", self.OnGamePadButtonDown);
        addon.SharedVignette:TryShow();
        CallbackRegistry:Trigger("BookUI.Show");
    end

    function DUIBookUIMixin:OnHide()
        EL:UnregisterEvent("PLAYER_REGEN_ENABLED");
        EL:UnregisterEvent("PLAYER_REGEN_DISABLED");
        self:SetScript("OnKeyDown", nil);
        if not InCombatLockdown() then
            self:EnableGamePadStick(false);
        end
        self:SetScript("OnGamePadStick", nil);
        self:SetScript("OnGamePadButtonDown", nil);
        CloseItemText();
        self:ReleaseAllObjects();
        Cache:ClearObjectCache();
        self.ScrollFrame:ClearContent();
        addon.SharedVignette:TryHide();
        self:StopReadingBook();
        CallbackRegistry:Trigger("BookUI.Hide");
        FadeHelper:FadeInUI(self);
    end

    function DUIBookUIMixin:OnMouseUp(button)
        if button == "LeftButton" then
            if GetDBBool("TTSEnabled") and GetDBBool("BookTTSClickToRead") and (not SwipeEmulator:ShouldConsumeClick()) then
                self:SpeakCursorFocusContent();
            end
        elseif button == "RightButton" and GetDBBool("RightClickToCloseUI") and self:IsMouseMotionFocus() then
            self:Hide();
        end
    end

    local EasingFunc = addon.EasingFunctions.outQuart;
    local ANIM_DURATION_SCROLL_EXPAND = 0.5;
    local function AnimIntro_FlyIn_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        local offsetY = EasingFunc(self.t, -48, 0, ANIM_DURATION_SCROLL_EXPAND);
        local alpha = 4*self.t;

        if alpha > 1 then
            alpha = 1;
        end

        if self.t >= ANIM_DURATION_SCROLL_EXPAND then
            offsetY = 0;
            self.t = 0;
            self:SetScript("OnUpdate", nil);

            local function ShowOutOfBoundObjects(obj)
                --obj:Show();
            end
            self.fontStringPool:ProcessActiveObjects(ShowOutOfBoundObjects);
            self.texturePool:ProcessActiveObjects(ShowOutOfBoundObjects);
        end

        self:SetPoint(self.defaultAnchor, nil, "CENTER", self.defaultOffsetX, offsetY);
        self:SetAlpha(alpha);
    end

    function DUIBookUIMixin:ShowUI()
        if API.IsPlayingCutscene() then
            return
        end

        SwipeEmulator:SetOwner(self.ScrollFrame);
        self:RebuildContentFromCache();

        if not self:IsShown() then
            self.t = 0;
            self:SetAlpha(0);
            self:Show();
            self:SetScript("OnUpdate", AnimIntro_FlyIn_OnUpdate);
            FadeHelper:FadeOutUI(self);
        end

        CallbackRegistry:Trigger("BookUI.BookCached");
    end

    function DUIBookUIMixin:HideUI()
        Cache:ClearObjectCache();
        self:Hide();
    end

    CallbackRegistry:Register("DialogueUI.HandleEvent", function()
        --Close book UI when dialogue UI is showing
        --Interact with NPC trigger ITEM_TEXT_CLOSED but we have an option to keep the book UI open
        MainFrame:HideUI();
    end);
end

do  --TTS
    function DUIBookUIMixin:GetCursorFocusContent()
        if not self:IsMouseMotionFocus() then return end;

        for _, obj in self.fontStringPool:EnumerateActive() do
            if obj:IsMouseOver() then
                return obj.contentIndex
            end
        end
    end

    function DUIBookUIMixin:FadeOtherContent()
        --Debug make other paragraphs transparent
        if self.focusedContentIndex and self.isReadingContent then
            local function FadeObject(obj)
                if obj.contentIndex == self.focusedContentIndex then
                    FadeFrame(obj, 1, 1);
                else
                    FadeFrame(obj, 1, OTHER_CONTENT_ALPHA);
                end
            end
            self.fontStringPool:ProcessAllObjects(FadeObject);
            self.ScrollFrame.onScrollFinishedCallback = function()
                self:FadeOtherContent();
            end;
        else
            local FadeObject;
            if self:IsVisible() then
                function FadeObject(obj)
                    FadeFrame(obj, 0.5, 1);
                end
            else
                function FadeObject(obj)
                    FadeFrame(obj, 0, 1);
                end
            end
            self.fontStringPool:ProcessAllObjects(FadeObject);
            self.ScrollFrame.onScrollFinishedCallback = nil;
        end
    end

    function DUIBookUIMixin:StopReadingBook()
        TTSUtil:StopReadingBook();
        if self.isReadingContent then
            self.isReadingContent = false;
            self.focusedContentIndex = nil;
            self:FadeOtherContent();
        end
    end

    function DUIBookUIMixin:ReadAndMoveToNextLine()
        --We only move the page when the current view cannot contain the full paragrah
        if not self.isReadingContent then
            return
        end

        if not Cache:IsCurrentObjectFullyCached() then
            self.isReadingContent = false;
            return
        end

        local contentIndex = (self.focusedContentIndex or 0) + 1;
        local data = Cache:GetContentDataByIndex(contentIndex);
        local found;

        if data then
            while data and (not data.text) do
                contentIndex = contentIndex + 1;
                data = Cache:GetContentDataByIndex(contentIndex);
            end

            if data and data.text then
                found = true;
                self.focusedContentIndex = contentIndex;
                TTSUtil:ReadBookLine(data.text);

                local viewSize = self.ScrollFrame:GetViewSize();
                local fromOffset = self.ScrollFrame:GetVerticalScroll(); --self:GetScrollTarget();
                local toOffset = fromOffset + viewSize;
                if (data.endingOffsetY <= fromOffset) or (data.offsetY >= toOffset) or (data.offsetY <= toOffset and data.endingOffsetY >= toOffset) then
                    local offsetY = data.offsetY;
                    offsetY = offsetY - self.scrollFromOffetY;
                    SwipeEmulator:StopWatching(self.ScrollFrame);
                    self:ScrollTo(offsetY);
                end
            end
        else

        end

        if found then
            self.isReadingContent = true;
        else
            self.isReadingContent = false;
        end

        self:FadeOtherContent();

        return found
    end

    function DUIBookUIMixin:SpeakCursorFocusContent()
        local contentIndex = self:GetCursorFocusContent();
        if contentIndex then
            if self.focusedContentIndex == contentIndex then
                self:StopReadingBook();
                return
            end
            local data = Cache:GetContentDataByIndex(contentIndex);
            if data and data.text then
                self.focusedContentIndex = contentIndex;
                self.isReadingContent = true;
                local userInput = true;
                TTSUtil:ReadBookLine(data.text, userInput);
                self:FadeOtherContent();
            end
        end
    end

    function DUIBookUIMixin:SpeakTopContent()
        --For TTSButton, speak the top paragrah
        if not self:IsVisible() then return end;

        local contentIndex = 1;
        local data = Cache:GetContentDataByIndex(contentIndex);

        if data then
            local viewSize = self.ScrollFrame:GetViewSize();
            local fromOffset = self.ScrollFrame:GetVerticalScroll();
            local toOffset = fromOffset + viewSize;
            local foundIndex;
            while data do
                if data.text and ((data.offsetY <= fromOffset and data.endingOffsetY >= fromOffset) or (data.offsetY >= fromOffset))  then
                    local offsetY = data.offsetY;
                    offsetY = offsetY - self.scrollFromOffetY;
                    SwipeEmulator:StopWatching(self.ScrollFrame);
                    self:ScrollTo(offsetY);
                    foundIndex = contentIndex;
                    break
                end
                contentIndex = contentIndex + 1;
                data = Cache:GetContentDataByIndex(contentIndex);
            end

            if foundIndex then
                if self.focusedContentIndex == foundIndex then
                    self:StopReadingBook();
                    return
                end
                data = Cache:GetContentDataByIndex(foundIndex);
                if data and data.text then
                    self.focusedContentIndex = foundIndex;
                    self.isReadingContent = true;
                    local userInput = true;
                    TTSUtil:ReadBookLine(data.text, userInput);
                    self:FadeOtherContent();
                end
            end
        end
    end

    function DUIBookUIMixin:GetAndScrollToNextText()
        local contentIndex = self.focusedContentIndex or self:GetCursorFocusContent();
        if contentIndex then
            local data = Cache:GetContentDataByIndex(contentIndex);
            if data then
                local offsetY = data.offsetY;
                offsetY = offsetY - self.scrollFromOffetY;
                self:ScrollTo(offsetY);
            end
        end
    end
end

do  --Keyboard Control, In Combat Behavior
    local IsModifierKeyDown = IsModifierKeyDown;

    function DUIBookUIMixin:OnKeyDown(key)
        local valid = false;

        if key == "ESCAPE" then
            valid = true;
            if addon.Clipboard:CloseIfShown() then

            else
                self:Hide();
            end
        elseif key == "F1" then
            valid = true;
            addon.SettingsUI:ToggleUI();
        elseif BindingUtil:GetActiveKeyAction(key) == "TTS" and (not IsModifierKeyDown()) and GetDBBool("TTSEnabled") and GetDBBool("TTSUseHotkey") then
            valid = true;
            addon.TTSUtil:ToggleSpeaking("book");
        else
            local action = GetBindingAction(key);
            if action == "OPENALLBAGS" or action == "TOGGLEBACKPACK" then
                valid = true;
                self:Hide();
            end
        end

        if InCombatLockdown() then
            self:Hide();
        else
            self:SetPropagateKeyboardInput(not valid);
        end
    end

    function DUIBookUIMixin:OnGamePadStick(stick, x, y, len)
        --SetPropagateKeyboardInput Also affect Joystick
        if stick == "Right" then
            if not EL.inCombat then
                self:SetPropagateKeyboardInput(false);
            end
            self.ScrollFrame:SteadyScroll(-y);
        elseif stick ~= "Camera" then
            if not EL.inCombat then
                self:SetPropagateKeyboardInput(true);
            end
        end
    end

    function DUIBookUIMixin:OnGamePadButtonDown(button)
        local valid = false;

        if button == "PADLSHOULDER" then
            if self.scrollable then
                valid = true;
                self:ScrollToNearPrevPage();
            end
        elseif button == "PADRSHOULDER" then
            if self.scrollable then
                valid = true;
                self:ScrollToNearNextPage();
            end
        elseif button == "PADMENU" or button == "PADFORWARD" then
            valid = true;
            addon.SettingsUI:ToggleUI();
        elseif button == "PADBACK" or button == "PAD2" then
            valid = true;
            if addon.Clipboard:CloseIfShown() then

            else
                self:Hide();
            end
        elseif button == "PADLTRIGGER" and (not IsModifierKeyDown()) and GetDBBool("TTSEnabled") and GetDBBool("TTSUseHotkey") then
            valid = true;
            addon.TTSUtil:ToggleSpeaking("book");
        end

        if not EL.inCombat then
            self:SetPropagateKeyboardInput(not valid);
        end
    end
end

do  --EventListener
    local BOOK_EVENTS = {
        "ITEM_TEXT_BEGIN",
        "ITEM_TEXT_READY",
        "ITEM_TEXT_CLOSED",
        "ITEM_TEXT_TRANSLATION",
    };

    local MaterialTextureKitID = {
        ["Default"] = 1,
        ["Stone"] = 2,
        ["Parchment"] = 1,
        ["Marble"] = 2,
        ["Silver"] = 2,
        ["Bronze"] = 2,
        ["ParchmentLarge"] = 1,
        ["Progenitor"] = 2,
    };

    function EL:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.03 then
            self:SetScript("OnUpdate", nil);
            if (not self.showItemText) and MainFrame:IsShown() and (not GetDBBool("BookKeepUIOpen")) then
                MainFrame:Hide();
            end
        end
    end

    function EL:ProcessEventNextUpdate(customDelay)
        customDelay = customDelay or 0;
        self.t = -customDelay;
        self.processEvent = true;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function EL:OnEvent(event, ...)
        if event == "ITEM_TEXT_BEGIN" then
            --1st start interacting with book
            if MainFrame.Init then
                MainFrame:Init();
            end

            local material = ItemTextGetMaterial() or "Parchment";
            --material = "Stone"; --debug  Parchment Stone
            local textureKitID = MaterialTextureKitID[material] or 1;
            MainFrame:SetTextureKit(textureKitID);

            --if QuestUtil.QuestTextContrastUseLightText() then

            local guid = UnitGUID("npc");
            local objectType, objectID, itemID;

            if guid then
                objectType, objectID, itemID = GetObjectTypeAndID(guid);
            end

            local isObjectChanged = Cache:SetActiveObject(objectType, objectID, itemID);

            MainFrame.Header:QueryLetterSender(nil);
            if objectType == "GameObject" then
                MainFrame.Header:SetLocation(true, Cache:GetBookLocation());
            else
                MainFrame.Header:SetLocation(false);
                if itemID == 8383 then  --Plain Letter
                    MainFrame.Header:QueryLetterSender(guid);
                end
            end

            self.itemTextBegun = true;

            if MainFrame.SourceItemButton then
                MainFrame.SourceItemButton:SetItem(nil);
            end

        elseif event == "ITEM_TEXT_READY" then
            self.showItemText = true;
            --Game shows ItemTextFrame here
            --local creator = ItemTextGetCreator();   --Niable, "\n\n"..ITEM_TEXT_FROM.."\n"..creator.."\n"

            if (not Cache.needTurnBack) and Cache:IsCurrentObjectFullyCached() then
                --MainFrame:ShowUI();
            elseif Cache.needTurnBack and IsMultiPageBook() then
                --Cache:RequestTurnPrevPage();
            elseif not Cache:IsCurrentObjectFullyCached() then
                Cache:CacheCurrentPage();
            end

        elseif event == "ITEM_TEXT_CLOSED" then
            --Game closes ItemTextFrame here
            if self.itemTextBegun then
                self.itemTextBegun = false;
                Cache:SavePagePosition();
                CloseItemText();
            end
            self.showItemText = false;
            --MainFrame:Hide();
            self:ProcessEventNextUpdate();          --Clicking on a currently read book triggers 2 Close - 1 Begin - 1 Ready

        elseif event == "ITEM_TEXT_TRANSLATION" then
            --Game shows ItemTextFrame here (Classic only?)
            local delay = ...

        elseif event == "PLAYER_REGEN_DISABLED" then
            self.inCombat = true;
            self:SetPropagateKeyboardInput(true);
            self:EnableGamePadStick(false);
            self:SetScript("OnGamePadStick", nil);
            self:SetScript("OnGamePadButtonDown", nil);
            if self:IsShown() then
                addon.CameraUtil:OnEnterCombatDuringInteraction();
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.inCombat = false;
            if MainFrame:IsVisible() then
                self:SetScript("OnGamePadStick", self.OnGamePadStick);
                self:SetScript("OnGamePadButtonDown", self.OnGamePadButtonDown);
            end
        end

        --print(event, ..., GetTimePreciseSec()); --debug
    end

    function EL:EnableModule(state)
        local f = ItemTextFrame;
        if state then
            self.enabled = true;
            self:SetScript("OnEvent", self.OnEvent);
            for _, event in ipairs(BOOK_EVENTS) do
                self:RegisterEvent(event);
            end
            if f then
                f:UnregisterAllEvents();
            end
        elseif self.enabled then
            self.enabled = false;
            self:SetScript("OnEvent", nil);
            self:UnregisterAllEvents();
            for _, event in ipairs(BOOK_EVENTS) do
                if f then
                    f:RegisterEvent(event);
                end
            end
        end
    end

    local function EnableBookUI(state)
        --Used in Core.lua, related settings ("Use WoW's Default UI In Instance")
        state = state and GetDBBool("BookUIEnabled");
        if state then
            if not EL.enabled then
                EL:EnableModule(true);
            end
        else
            if EL.enabled then
                EL:EnableModule(false);
                MainFrame:Hide();
            end
        end
    end
    addon.EnableBookUI = EnableBookUI;
end


do  --Settings
    local FrameSizeIndexScale = {
        [0] = 0.9,
        [1] = 1.0,
        [2] = 1.1,
        [3] = 1.25,
        [4] = 1.4,
    };

    function DUIBookUIMixin:OnSettingsChanged()
        if not self:IsShown() then return end;

        if not self.settingsDirty then
            self.settingsDirty = true;
            C_Timer.After(0, function()
                self.settingsDirty = nil;
                CalculateSizeData();
                Cache:CalculateTextHeight();
            end)
        end
    end

    local function Settings_FrameSize(dbValue)
        --Image size doesn't get recalculated until cache is wiped (close and repoen book to take effect)
        if GetDBBool("MobileDeviceMode") then
            dbValue = 4;
        end

        local newScale = dbValue and FrameSizeIndexScale[dbValue];
        if newScale then
            if newScale ~= FRAME_SIZE_MULTIPLIER then
                MainFrame:OnSettingsChanged();
            end
            FRAME_SIZE_MULTIPLIER = newScale;
            CalculateSizeData();
            if not MainFrame.Init then
                MainFrame:Resize();
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.BookUISize", Settings_FrameSize);

    local function OnFontSizeChanged(baseFontSize, fontSizeID)
        Formatter:SetBaseFontSize(baseFontSize);
        MainFrame:OnSettingsChanged();
    end
    CallbackRegistry:Register("FontSizeChanged", OnFontSizeChanged);

    local function Settings_BookUIEnabled(state)
        EL:EnableModule(state);
    end
    CallbackRegistry:Register("SettingChanged.BookUIEnabled", Settings_BookUIEnabled);

    local function Settings_BookDarkenScreen(state)
        MainFrame.ScreenVignette:SetShown(state);
    end
    CallbackRegistry:Register("SettingChanged.BookDarkenScreen", Settings_BookDarkenScreen);

    local function Settings_BookShowLocation(state)
        if MainFrame:IsShown() then
            if state then
                MainFrame.Header:SetLocation(true, Cache:GetBookLocation());
            else
                MainFrame.Header:SetLocation(false);
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.BookShowLocation", Settings_BookShowLocation);


    --TTS and Copy Buttons
    local TTSButton;

    local function Settings_TTSEnabled(dbValue)
        if dbValue == true then
            if not TTSButton then
                local themeID = 3;
                TTSButton = addon.CreateTTSButton(MainFrame, themeID);
                TTSButton:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 8, -8);
                TTSButton.system = "book";
                MainFrame.TTSButton = TTSButton;
            end
            TTSButton:Show();
            if MainFrame.widgetTheme then
                TTSButton:SetTheme(MainFrame.widgetTheme);
            end
        else
            if TTSButton then
                TTSButton:Hide();
            end
        end
        MainFrame:LayoutWidgets();
    end
    CallbackRegistry:Register("SettingChanged.TTSEnabled", Settings_TTSEnabled);

    --Clipboard
    local CopyTextButton;

    local function CopyTextButton_OnClick(self)
        if addon.Clipboard:CloseIfFromSameSender(self) then
            return
        end
        local str = Cache:GetRawContent(true);
        addon.Clipboard:ShowContent(str, self);
    end

    local function Settings_ShowCopyTextButton(dbValue)
        if dbValue == true then
            if not CopyTextButton then
                local themeID = 1;  --Brown
                CopyTextButton = addon.CreateCopyTextButton(MainFrame, CopyTextButton_OnClick, themeID);
                CopyTextButton:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -8, -8);
                MainFrame.CopyTextButton = CopyTextButton;
                CopyTextButton:SetWidth(16);    --down from 24
            end
            CopyTextButton:Show();
            if MainFrame.widgetTheme then
                CopyTextButton:SetTheme(MainFrame.widgetTheme);
            end
        else
            if CopyTextButton then
                CopyTextButton:Hide();
            end
        end
        MainFrame:LayoutWidgets();
    end
    CallbackRegistry:Register("SettingChanged.ShowCopyTextButton", Settings_ShowCopyTextButton);

    function DUIBookUIMixin:LayoutWidgets()
        local object1, object2;

        if GetDBBool("TTSEnabled") and TTSButton then
            object1 = TTSButton;
        end

        if GetDBBool("ShowCopyTextButton") and CopyTextButton then
            if object1 then
                object2 = CopyTextButton;
            else
                object1 = CopyTextButton;
            end
        end

        if object1 then
            local offset = ConvertedSize.CLOSE_BUTTON_OFFSET;
            object1:ClearAllPoints();
            object1:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", offset, -offset);
            if object2 then
                object2:ClearAllPoints();
                object2:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", offset + 32, -offset);
            end
        end
    end


    --Source Item Button
    local SourceItemButton;

    local function Settings_BookUIItemDescription(state, userInput)
        if state then
            if not SourceItemButton then
                SourceItemButton = BookComponent:CreateSourceItemButton(MainFrame);
                SourceItemButton:SetPoint("BOTTOM", MainFrame, "TOP", 0, 16);
                MainFrame.SourceItemButton = SourceItemButton;
            end
            SourceItemButton:Show();
            SourceItemButton:SetTexture(MainFrame.textureFile);
            if MainFrame:IsShown() then
                MainFrame:Resize();
                SourceItemButton:SetItem(Cache:GetCurrentItemID());
            end
        else
            if SourceItemButton then
                SourceItemButton:Hide();
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.BookUIItemDescription", Settings_BookUIItemDescription);
end


do  --Hide Default UI
    --[[
    local hideDefaultUI = true;    --false when we do debug
    if hideDefaultUI then
        if ItemTextFrame then   --Mute
            ItemTextFrame:UnregisterAllEvents();
        end
    else
        ItemTextFrame:SetParent(nil);
        ItemTextFrame:SetScale(0.65);
        EL:SetScript("OnEvent", nil);
    end
    --]]
end


do  --ItemTextGetText Override Debug
    --[[
    local Libram = {
        [1] = 
<The pages are covered in ancient elven runes.>

The pages herein contain memories of events that transpired in the collection and creation of the reagents required to craft lesser arcanum.

May our enemies never gain access to these libram.

May I live to see the pallid light of the moon shine upon Quel'Thalas once again.

May I die but for the grace of Kael'thas.

May I kill for the glory of Illidan.

-Master Kariel Winthalus

<HTML>
<BODY>
<IMG src="Interface\Pictures\11733_blackrock_256"/>
</BODY>
</HTML>

<HTML>
<BODY>
<IMG src="Interface\Pictures\11733_blasted_256"/>
</BODY>
</HTML>

<HTML>
<BODY>
<IMG src="Interface\Pictures\11733_ungoro_256"/>
</BODY>
</HTML>
,
    };

    function ItemTextGetText(page)
        return Libram[page]
    end
    --]]
end