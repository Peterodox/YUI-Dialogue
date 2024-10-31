-- Create a pseudo GameTooltip that captures AddLine, AddDoubleLine
-- Currently used to get Pawn updrade info

local _, addon = ...

local TC = {};
addon.TooltipCapture = TC;

local CreateColor = CreateColor;

function TC:Show()

end

function TC:Hide()
    self:ClearLines();
end

function TC:OnHide()
    self:Hide();
end

function TC:SetOwner(owner, anchor)
    self:ClearLines();
end

function TC:SetPoint()

end

function TC:ClearLines()
    self.n = 0;
    self.lines = {};
end
TC:ClearLines();

function TC:AddLine(tooltipText, r, g, b, wrapText)
    if (not tooltipText) or tooltipText == "" then return end;

    self.n = self.n + 1;
    self.lines[self.n] = {
        leftText = tooltipText,
        leftColor = CreateColor(r or 1, g or 1, b or 1),
    };
end

function TC:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
    local leftValid = leftText and leftText ~= "";
    local rightValid = rightText and rightText ~= "";

    if leftValid and rightValid then

    elseif leftValid and not rightValid then
        return self:AddLine(leftText, leftR, leftG, leftB, true);
    elseif rightValid and not leftValid then
        leftText = " ";
    end

    self.n = self.n + 1;
    self.lines[self.n] = {
        leftText = leftText,
        leftColor = CreateColor(leftR or 1, leftG or 1, leftB or 1),
        rightText = rightText,
        rightColor = CreateColor(rightR or 1, rightG or 1, rightB or 1),
    };
end

function TC:SendToProcess(ourTooltip)
    self.target = ourTooltip;
    if self.n and self.n > 0 then
        ourTooltip:ProcessTooltipDataLines(self.lines);
    end
end

function TC:SetHyperlink(link)
    self.link = link;
end