local _, addon = ...


local BookComponent = {};
addon.BookComponent = BookComponent;


local API = addon.API;
local L = addon.L;
local FontUtil = addon.FontUtil;
local Mixin = API.Mixin;
local Round = API.Round;


local Pagination = {};
do
    local PageButtonMixin = {};
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

    local HeaderFrameMixin = {};

    function HeaderFrameMixin:SetTitle(title)
        local minLineHeight = 14;
        self:SetAutoScalingText(self.Title, title, minLineHeight);
    end

    function HeaderFrameMixin:GetHeaderHeight()
        return Round( (self.titleHeight or self.Title:GetHeight()) + (self.heightBelow or 0) )
    end

    function HeaderFrameMixin:SetHeightBelowTitle(heightBelow)
        --Usually the Paragraph Spacing
        --Distance between the bottom of the Title text and the top the body is Page Spacing
        self.heightBelow = heightBelow;
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

    function BookComponent:InitHeader(headerFrame)
        local Title = headerFrame:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Title_18");
        headerFrame.Title = Title;
        Title:SetJustifyH("CENTER");
        Title:SetJustifyV("TOP");
        Title:SetMaxLines(2);
        Title:SetSpacing(TITLE_SPACING);
        Title:SetPoint("TOP", headerFrame, "TOP", 0, 0);
        Mixin(headerFrame, HeaderFrameMixin);
    end
end