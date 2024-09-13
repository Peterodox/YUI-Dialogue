local _, addon = ...
local API = addon.API;
local L = addon.L;
local BookComponent = addon.BookComponent;
local KeyboardControl = addon.KeyboardControl;
local GetDBBool = addon.GetDBBool;
local Round = API.Round;


local MainFrame;
local EL = CreateFrame("Frame");    --EventListener
local DataProvider = {};            --Store text info
local Formatter = {};               --Format content, convert html to fontstring
local Cache = CreateFrame("Frame"); --Cache the whole book when opened


local InCombatLockdown = InCombatLockdown;
local UnitGUID = UnitGUID;
local IsShiftKeyDown = IsShiftKeyDown;
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


local PIXEL_SCALE = 0.53333;
local FRAME_SIZE_MULTIPLIER = 1.0;  --(See DialogueUI.lua) 1.1 / 1.25
local WOW_PAGE_WIDTH = 412; --ParchmentLarge

local NEW_PAGE_SCROLL_COOLDOWN = 0.5;   --Only allow turning 1 page every X duration


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

    HEADER_SCROLL_OVERLAP = 80,
    FOOTER_SCROLL_OVERLAP = 40,
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
            return type, GetItemIDByGUID(guid);
        else
            return type, guid;
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
    end

    function Cache:SetActiveObject(objectType, objectID)
        --objectType: item, npc
        --objectID: itemID, creatureID
        self:SetScript("OnUpdate", nil);

        local isObjectChanged;
        local identifier;

        if objectType and objectID then
            identifier = objectType..objectID;
            isObjectChanged = identifier ~= self.identifier;
            self.identifier = identifier;
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
        local rawText = ItemTextGetText();
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
        MainFrame:DisplayCurrentPage();

        self.t = 0;
        self.fromContentIndex = 0;
        self.toContentIndex = self:GetMaxContentIndex();
        self:SetScript("OnUpdate", self.OnUpdate_CalculateTextHeight);
    end

    function Cache:StoreText(fontTag, text, justifyH, spacingBelow)
        local index = self.activeData.maxContentIndex + 1;
        self.activeData.maxContentIndex = index;

        justifyH = justifyH or "LEFT";

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

    function Cache:StoreImage(file, width, height, left, right, top, bottom)
        local index = self.activeData.maxContentIndex + 1;
        self.activeData.maxContentIndex = index;

        local align = "CENTER";

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
        local data = self:GetFormattedContentByIndex(index);
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
            return self.activeData.pageStartOffset[page]
        end
    end

    function Cache:GetFormattedContentByIndex(contentIndex)
        if self.activeData and self.activeData.formattedContent[contentIndex] then
            return self.activeData.formattedContent[contentIndex]
        end
    end
end


DUIBookUIMixin = {};

do  --Background Calculation \ Theme
    local TextureKit = {
        [1] = "Parchment.png";
    };

    function DUIBookUIMixin:SetTextureKit(textureKitID)
        if textureKitID and TextureKit[textureKitID] and textureKitID ~= self.textureKitID then
            self.textureKitID = textureKitID;
            local file = string.format("Interface/AddOns/DialogueUI/Art/Book/TextureKit-"..TextureKit[textureKitID]);

            if self.BackgroundPieces then
                for _, obj in pairs(self.BackgroundPieces) do
                    obj:SetTexture(file);
                end
            end

            if self.CloseButton then
                self.CloseButton:SetUITexture(file);
            end

            self.Header.HeaderScrollOverlap:SetTexture(file);
            self.Header.HeaderScrollOverlap:SetTexCoord(128/1024, 896/1024, 1408/2048, 1488/2048);
        end
    end

    function DUIBookUIMixin:SetFrameHeight(height, scrollable)
        local p = self.BackgroundPieces;

        if not p then
            p = {};
            self.BackgroundPieces = p;
            p[1] = self:CreateTexture(nil, "BACKGROUND", nil, -1);
            p[2] = self.Footer:CreateTexture(nil, "OVERLAY", nil, -1);
        end

        local cs = ConvertedSize;

        if height < cs.FRAME_HEIGHT_MIN then
            height = cs.FRAME_HEIGHT_MIN;
        end

        local isDynamicHeight = (not self.isMultiPageBook) and (height + 8) < cs.FRAME_HEIGHT_MAX;
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
        local defaultOffsetX = -0.5*viewportWidth + distanceToEdge;
        defaultOffsetX = 0.5*viewportWidth - distanceToEdge;
        self.defaultOffsetX = defaultOffsetX;
        self:ClearAllPoints();
        self:SetPoint("RIGHT", nil, "CENTER", defaultOffsetX, 0);
    end

    function DUIBookUIMixin:Resize()
        --Resize after base frame/font size change (Small/Medium/Large)
        local cs = ConvertedSize;

        self.ContentFrame:SetSize(cs.FRAME_WIDTH, 64);  --Height doesn't really matter

        if self.CloseButton then
            self.CloseButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -cs.CLOSE_BUTTON_OFFSET, -cs.CLOSE_BUTTON_OFFSET);
            self.CloseButton:SetSize(cs.CLOSE_BUTTON_SIZE, cs.CLOSE_BUTTON_SIZE);
        end

        self.Header.Title:SetWidth(ConvertedSize.CONTENT_WIDTH);
        self.Header.Title:SetPoint("TOP", self, "TOP", 0, -cs.PADDING_V);
        self.Header:SetHeightBelowTitle(Formatter.PARAGRAPH_SPACING);

        self.Header.HeaderScrollOverlap:SetSize(cs.FRAME_WIDTH, cs.HEADER_SCROLL_OVERLAP);
        self.Footer.FooterDivider:SetSize(cs.FRAME_WIDTH, cs.FOOTER_SCROLL_OVERLAP);
    end

    function DUIBookUIMixin:SetScrollContentHeight(contentHeight)
        --Determine if the current page can be fully displayed
        --If the page needs to be scrollable nad book has multiple pages, it will scroll down util it reach the bottom, then turn to next page
        --Scroll backwards will scroll to the page's top
        --The Header (including Book Name and Pagination for multi-page) use constant size

        local cs = ConvertedSize;
        local headerHeight = self.Header:GetHeaderHeight();
        local maxContentHeight = cs.FRAME_HEIGHT_MAX - 2*cs.PADDING_V - headerHeight;
        local totalFrameHeight = headerHeight + contentHeight + 2*cs.PADDING_V;

        local scrollable = contentHeight > maxContentHeight;
        local frameHeight = self:SetFrameHeight(totalFrameHeight, scrollable);
        local scrollRange;

        --debug
        --self.DebugArea:ClearAllPoints();
        --self.DebugArea:SetSize(32, contentHeight);
        --self.DebugArea:SetPoint("TOP", self.ContentFrame, "TOP", 0, 0);
        self:ResetScroll();

        if scrollable then
            self.ScrollFrame:ClearAllPoints();
            self.ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0,  -cs.PADDING_V - headerHeight);
            self.ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, cs.PADDING_V);
            self.ContentFrame:SetParent(self.ScrollFrame.ScrollChild);
            self.ContentFrame:SetPoint("TOPLEFT", self.ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
            self.ContentFrame:SetFrameLevel(self.ScrollFrame.ScrollChild:GetFrameLevel());
            local scrollFrameHeight = self.ScrollFrame:GetHeight();
            scrollRange = Round(contentHeight + Formatter.PAGE_SPACING - scrollFrameHeight);
        else
            scrollRange = 0;
            self.ContentFrame:SetParent(self);
            self.ContentFrame:SetPoint("TOP", self, "TOP", 0, -cs.PADDING_V - headerHeight);
            self.ContentFrame:SetFrameLevel(self.Footer:GetFrameLevel() + 10);
        end

        self.scrollable = scrollable;
        self.ScrollFrame:SetScrollRange(scrollRange);
        self.ScrollFrame:SetUseOverlapBorder(scrollable, scrollable);
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

        if self.oneScrollMode then
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
        else
            if not self.ScrollLocker then
                local f = CreateFrame("Frame");
                self.ScrollLocker = f;
                f:Hide();
                f.t = 0;
                f:SetScript("OnUpdate", function(_, elapsed)
                    f.t = f.t + elapsed;
                    if f.t > NEW_PAGE_SCROLL_COOLDOWN then
                        f.t = 0;
                        f:Hide();
                        self.scrollLocked = false;
                    end
                end)
            end

            if delta > 0 then
                if self:IsAtPageTop() then
                    local page = ItemTextGetPage();
                    if page > 1 then
                        --if not self.scrollLocked then
                            ItemTextPrevPage();
                        --end
                    end
                else
                    self:ScrollBy(-Formatter.OFFSET_PER_SCROLL);
                end
            else
                if self:IsAtPageBottom() then
                    local hasNext = ItemTextHasNextPage();
                    if hasNext then
                        if not self.scrollLocked then
                            ItemTextNextPage();
                        end
                    end
                else
                    self:ScrollBy(Formatter.OFFSET_PER_SCROLL);
                end
            end

            self.scrollLocked = true;
            self.ScrollLocker:Show();
        end
    end

    function DUIBookUIMixin:ScrollBy(deltaValue)
        self.ScrollFrame:ScrollBy(deltaValue);
    end

    function DUIBookUIMixin:ScrollTo(value)
        self.ScrollFrame:ScrollTo(value);
    end

    function DUIBookUIMixin:ScrollToContent(contentIndex)
        local data = Cache:GetFormattedContentByIndex(contentIndex);
        if data then
            local offsetY = data.offsetY;
            offsetY = offsetY - self.scrollTopOffet;
            self:ScrollTo(offsetY);
        end
    end

    function DUIBookUIMixin:ScrollToPage(page)
        local maxPage = Cache:GetMaxPage();
        if page > maxPage then
            page = maxPage;
        end

        local offsetY = Cache:GetPageStartOffset(page);
        if offsetY then
            offsetY = offsetY - self.scrollTopOffet;
            self:ScrollTo(offsetY);
        end
    end

    function DUIBookUIMixin:ScrollToNearNextPage()
        local offset = self.ScrollFrame:GetScrollTarget() + self.scrollTopOffet + 0.1;
        local maxPage = Cache:GetMaxPage();

        local pageOffset;

        for page = 1, maxPage do
            pageOffset = Cache:GetPageStartOffset(page);
            if offset < pageOffset then
                local offsetY = pageOffset - self.scrollTopOffet;
                self:ScrollTo(offsetY)
                break
            end
        end
    end

    function DUIBookUIMixin:ScrollToNearPrevPage()
        local offset = self.ScrollFrame:GetScrollTarget() + self.scrollTopOffet - 0.1;
        local maxPage = Cache:GetMaxPage();

        local pageOffset;

        for page = maxPage, 1, -1 do
            pageOffset = Cache:GetPageStartOffset(page);
            if offset > pageOffset then
                local offsetY = pageOffset - self.scrollTopOffet;
                self:ScrollTo(offsetY)
                break
            end
        end
    end
end

do  --Formatter
    local TagFonts = {
        ["p"] = "DUIFont_Quest_Paragraph",
        ["h1"] = "DUIFont_Quest_Title_18",
        ["h2"] = "DUIFont_Quest_Title_16",
        ["h3"] = "DUIFont_Quest_Title_16",
    };

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
        self.OFFSET_PER_SCROLL = Round(5 * (self.FONT_SIZE + self.TEXT_SPACING));

        self.UtilityFontString:SetSpacing(self.TEXT_SPACING);
    end

    function Formatter:AcquireTexture()
        local tex = MainFrame.texturePool:Acquire();
        return tex
    end

    function Formatter:AcquireFontStringByTag(fontTag)
        local fs = MainFrame.fontStringPool:Acquire();
        if not (fontTag and TagFonts[fontTag]) then
            fontTag = "p";
        end
        fs:SetFontObject(TagFonts[fontTag]);
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

    function Formatter:FormatText(text)
        if find(text, "^<HTML>") then
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

        if numParagraphs > 0 then
            for i, paragraphText in ipairs(paragraphs) do
                if i == numParagraphs then
                    Cache:StoreText(fontTag, paragraphText, align, 0);
                else
                    Cache:StoreText(fontTag, paragraphText, align, paragraphSpacing);
                end
            end
        else

        end
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


    local function CleanUpTags(text)
        --Remove <>
        text = gsub(text, "^<[^<>]+>", "", 1);
        text = gsub(text, "^<[^<>]+>", "", 1);
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

        if numParagraphs > 0 then
            for i, paragraphText in ipairs(paragraphs) do
                if not IgnoredTags[paragraphText] then
                    local tag, align;
                    tag = match(paragraphText, "^</*([%w]+)/*>");
                    if not tag then
                        tag = match(paragraphText, "^<([%w]+)%s");
                    end

                    if tag and not IgnoredTags[tag] then
                        tag = lower(tag);

                        if tag == "img" then
                            local file = match(paragraphText, "src=\"([%S]+)\"%s");
                            if file then
                                numImages = numImages + 1;
                                local width = match(paragraphText,"width=\"(%d+)");
                                width = width and tonumber(width);
                                local height = match(paragraphText,"height=\"(%d+)");
                                height = height and tonumber(height);
                                align = match(paragraphText,"align=\"(%a+)") or "center";
                                local imageWidth, imageHeight;
                                local left, right, top, bottom = 0, 1, 0, 1;
                                if not (width and height) then
                                    file = lower(file);
                                    local ratio;
                                    ratio, left, right, top, bottom = BookComponent:GetTextureCoordForFile(file);
                                    if ratio then
                                        imageWidth = ConvertedSize.CONTENT_WIDTH;
                                        imageHeight = ratio * imageWidth;
                                        width = imageWidth;
                                        height = imageHeight;
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
                                if width and height then
                                    if lower(file) == "interface\\common\\spacer" then
                                        Cache:AddSpacerToNextContent(self.PARAGRAPH_SPACING);
                                    else
                                        if not imageWidth then
                                            local scale = width / WOW_PAGE_WIDTH;
                                            imageWidth = Round(ConvertedSize.CONTENT_WIDTH * scale);
                                            imageHeight = Round(imageWidth * height / width);
                                        end
                                        Cache:StoreImage(file, imageWidth, imageHeight, left, right, top, bottom);
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
                                    if i == numParagraphs then
                                        Cache:StoreText(tag, paragraphText, align, 0);
                                    else
                                        Cache:StoreText(tag, paragraphText, align, paragraphSpacing);
                                    end
                                end
                            end
                        end
                    else
                        paragraphText = CleanUpTags(paragraphText);
                        if paragraphText and paragraphText ~= "" then
                            numTexts = numTexts + 1;
                            align = "LEFT";
                            tag = "p";
                            if i == numParagraphs then
                                Cache:StoreText(tag, paragraphText, align, 0);
                            else
                                Cache:StoreText(tag, paragraphText, align, paragraphSpacing);
                            end
                        end
                    end
                end
            end
        else

        end

        PP = paragraphs;    --debug
    end

    function DUIBookUIMixin:RebuildContentFromCache()
        --debug
        if not Cache:IsCurrentObjectFullyCached() then
            return
        end

        self:ReleaseAllObjects();

        local obj;
        local textRef = MainFrame.ContentFrame;
        local Formatter = Formatter;

        local offsetY = Round(ConvertedSize.PADDING_H - Formatter.PARAGRAPH_SPACING);
        self.scrollTopOffet = offsetY;
        local data;

        local page = 0;

        local debugMaxVisible = 200;

        for i, v in Cache:EnumerateFormattedContent() do
            if v.text then
                offsetY = offsetY + v.spacingAbove;
                if i < debugMaxVisible then
                    obj = Formatter:AcquireFontStringByTag(v.fontTag);
                    obj:SetPoint("TOP", textRef, "TOP", 0, -offsetY);
                    obj:SetJustifyH(v.align);
                    obj:SetText(v.text);
                end
                if v.isPageStart then
                    page = page + 1;
                    Cache:SetPageStartOffset(page, offsetY);
                end
                v.offsetY = offsetY;
                offsetY = Round(offsetY + v.textHeight);
                offsetY = offsetY + v.spacingBelow;
            elseif v.image then
                offsetY = offsetY + v.spacingAbove;
                if i < debugMaxVisible then
                    obj = Formatter:AcquireTexture();
                    obj:SetPoint("TOP", textRef, "TOP", 0, -offsetY);
                    obj:SetSize(v.width, v.height);
                    obj:SetTexture(v.image);
                    obj:SetTexCoord(v.left, v.right, v.top, v.bottom);
                end
                if v.isPageStart then
                    page = page + 1;
                    Cache:SetPageStartOffset(page, offsetY);
                end
                v.offsetY = offsetY;
                offsetY = Round(offsetY + v.height);
            end
        end

        self:SetScrollContentHeight(offsetY);

        --print("MAX INDEX", Cache:GetMaxContentIndex());
    end

    function DUIBookUIMixin:DisplayCurrentPage()
        if IsMultiPageBook() then
            self:SetScript("OnMouseWheel", self.OnMouseWheel);
        else
            self:SetScript("OnMouseWheel", nil);
        end

        self:ReleaseAllObjects();

        local title = ItemTextGetItem();   --"The Dark Portal and the Fall of Stormwind"
        self.Header:SetTitle(title);
        Formatter.titleText = title;

        local oneScrollMode = true;
        self.oneScrollMode = oneScrollMode;

        if oneScrollMode then
            local addPagePadding = IsMultiPageBook();
            local maxPage = Cache:GetMaxPage();

            for page, rawText in Cache:EnumeratePageTexts() do
                Cache:FlagNextContentIsPageStart();
                Formatter:FormatText(rawText);
                if addPagePadding and (page ~= maxPage) then
                    Cache:AddSpacerToLastContent(Formatter.PAGE_SPACING);
                end
            end
        else
            local rawText = ItemTextGetText();
            Cache:FlagNextContentIsPageStart();
            Formatter:FormatText(rawText);
        end
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
        local UtilityFontString = self.ContentFrame:CreateFontString(nil, "ARTWORK", "DUIFont_Quest_Paragraph");
        UtilityFontString:SetJustifyV("TOP");
        --UtilityFontString:SetPoint("TOP", nil, "BOTTOM", 0, -64);
        UtilityFontString:SetPoint("TOP", MainFrame.ContentFrame, "TOP", 0, 0);
        --UtilityFontString:SetIgnoreParentAlpha(true);
        Formatter.UtilityFontString = UtilityFontString;


        CalculateSizeData();
        Formatter:SetBaseFontSize(12);  --debug
        self:SetFrameHeight(480);
    end

    function DUIBookUIMixin:Init()
        self.Init = nil;
        self:Reposition();

        BookComponent:InitHeader(self.Header);
        addon.InitEasyScrollFrame(self.ScrollFrame, self.Header.HeaderScrollOverlap, self.Footer.FooterDivider);

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

        self.fontStringPool:Release();
        self.texturePool:Release();
    end

    function DUIBookUIMixin:OnShow()
        EL:RegisterEvent("PLAYER_REGEN_ENABLED");
        EL:RegisterEvent("PLAYER_REGEN_DISABLED");
        self:SetScript("OnKeyDown", self.OnKeyDown);
        addon.SharedVignette:TryShow();
    end

    function DUIBookUIMixin:OnHide()
        EL:UnregisterEvent("PLAYER_REGEN_ENABLED");
        EL:UnregisterEvent("PLAYER_REGEN_DISABLED");
        self:SetScript("OnKeyDown", nil);
        CloseItemText();
        self:ReleaseAllObjects();
        Cache:ClearObjectCache();
        addon.SharedVignette:TryHide();
    end

    function DUIBookUIMixin:OnMouseUp(button)
        if button == "RightButton" and GetDBBool("RightClickToCloseUI") and self:IsMouseMotionFocus() then
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

        self:SetPoint("RIGHT", nil, "CENTER", self.defaultOffsetX, offsetY);
        self:SetAlpha(alpha);
    end

    function DUIBookUIMixin:ShowUI()
        self.isMultiPageBook = IsMultiPageBook();
        --self:DisplayCurrentPage();
        self:RebuildContentFromCache();

        if not self:IsShown() then
            self.t = 0;

            self:DebugHide();

            self:SetAlpha(0);
            self:Show();
            self:SetScript("OnUpdate", AnimIntro_FlyIn_OnUpdate);
        end
    end

    function DUIBookUIMixin:DebugHide()
        local cutoffY = self.ScrollFrame:GetHeight();

        local function HideOutOfBoundObjects(obj)
            if obj.posY and obj.posY > cutoffY then
                --obj:Hide();
            end
        end

        self.fontStringPool:ProcessActiveObjects(HideOutOfBoundObjects);
        self.texturePool:ProcessActiveObjects(HideOutOfBoundObjects);
    end
end

do  --Keyboard Control, In Combat Behavior
    function DUIBookUIMixin:OnKeyDown(key)
        local valid = false;

        if key == "ESCAPE" then
            self:Hide();
            valid = true;
        end

        if InCombatLockdown() then
            self:Hide();
        else
            self:SetPropagateKeyboardInput(not valid);
        end
    end
end

do  --EventListener
    EL:RegisterEvent("ITEM_TEXT_BEGIN");
    EL:RegisterEvent("ITEM_TEXT_TRANSLATION");
    EL:RegisterEvent("ITEM_TEXT_READY");
    EL:RegisterEvent("ITEM_TEXT_CLOSED");

    function EL:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.03 then
            self:SetScript("OnUpdate", nil);
            if (not self.showItemText) and MainFrame:IsShown() then
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

            local title = ItemTextGetItem();
            local material = ItemTextGetMaterial();
            --if QuestUtil.QuestTextContrastUseLightText() then

            local guid = UnitGUID("npc");
            local objectType, objectID;

            if guid then
                objectType, objectID = GetObjectTypeAndID(guid);
            end

            local isObjectChanged = Cache:SetActiveObject(objectType, objectID);
            self.itemTextBegun = true;

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
                CloseItemText();
            end
            self.showItemText = false;
            --MainFrame:Hide();
            self:ProcessEventNextUpdate();          --Clicking on a currently read book triggers 2 Close - 1 Begin - 1 Ready

        elseif event == "ITEM_TEXT_TRANSLATION" then
            --Game shows ItemTextFrame here (Classic only?)
            local delay = ...

        elseif event == "PLAYER_REGEN_DISABLED" then
            self:SetPropagateKeyboardInput(true);

        elseif event == "PLAYER_REGEN_ENABLED" then

        end

        --print(event, ..., GetTimePreciseSec()); --debug
    end
    EL:SetScript("OnEvent", EL.OnEvent);
end


do
    local hideDefaultUI = false;    --false when we do debug
    if hideDefaultUI then
        if ItemTextFrame then   --Mute
            ItemTextFrame:UnregisterAllEvents();
        end
    else
        ItemTextFrame:SetParent(nil);
        ItemTextFrame:SetScale(0.65);
    end
end