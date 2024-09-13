-- Create a simple smooth scroll frame

local _, addon = ...
local API = addon.API;
local DeltaLerp = API.DeltaLerp;
local SCROLL_BLEND_SPEED = 0.15;    --0.2

local ScrollFrameMixin = {};


function ScrollFrameMixin:OnUpdate_Easing(elapsed)
    self.value = DeltaLerp(self.value, self.scrollTarget, self.blendSpeed, elapsed);

    if (self.value - self.scrollTarget) > -0.4 and (self.value - self.scrollTarget) < 0.4 then
        --complete
        self.value = self.scrollTarget;
        self:SetScript("OnUpdate", nil);

        if self.value == 0 then
            --at top
            --self.borderTop:Hide();
            --FadeFrame(self.borderTop, 0.25, 0);
        elseif self.value == self.range then
            --at bottom
            --self.borderBottom:Hide();
            --FadeFrame(self.borderBottom, 0.25, 0);
        end
    end

    self:SetOffset(self.value);
end

function ScrollFrameMixin:SetOffset(value)
    self.topDividerAlpha = value/24;
    if self.topDividerAlpha > 1 then
        self.topDividerAlpha = 1;
    elseif self.topDividerAlpha < 0 then
        self.topDividerAlpha = 0;
    end
    self.borderTop:SetAlpha(self.topDividerAlpha);

    self.bottomDividerAlpha = (self.range - value)/24;
    if self.bottomDividerAlpha > 1 then
        self.bottomDividerAlpha = 1;
    elseif self.bottomDividerAlpha < 0 then
        self.bottomDividerAlpha = 0;
    end

    self.borderBottom:SetAlpha(self.bottomDividerAlpha);
    self.value = value;
    self:SetVerticalScroll(value);
end

function ScrollFrameMixin:ResetScroll()
    self:SetScript("OnUpdate", nil);
    self:SetOffset(0);
    self.scrollTarget = 0;
end

function ScrollFrameMixin:GetScrollTarget()
    return self.scrollTarget or self:GetVerticalScroll()
end

function ScrollFrameMixin:ScrollBy(deltaValue)
    local offset = self:GetVerticalScroll();
    self:ScrollTo(offset + deltaValue);
end

function ScrollFrameMixin:SetScrollRange(range)
    self.range = range;
end

function ScrollFrameMixin:ScrollTo(value)
    value = API.Clamp(value, 0, self.range);
    if value ~= self.scrollTarget then
        self.scrollTarget = value;
        self:SetScript("OnUpdate", self.OnUpdate_Easing);
        if self.range > 0 then
            self:UpdateOverlapBorderVisibility();
        end
    end
end

function ScrollFrameMixin:ScrollToTop()
    self:ScrollTo(0);
    self.borderTop:Hide();
    if self.range > 0 and self.useBottom then
        self.borderBottom:Show();
    end
end

function ScrollFrameMixin:ScrollToBottom()
    self:ScrollTo(self.range);
    self.borderBottom:Hide();
    if self.range > 0 and self.useTop then
        self.borderTop:Show();
    end
end

function ScrollFrameMixin:IsAtPageTop()
    local offset = self:GetVerticalScroll();
    return self.value <= 0.1
end

function ScrollFrameMixin:IsAtPageBottom()
    local offset = self:GetVerticalScroll();
    return self.value + 0.1 >= (self.range or 0)
end

function ScrollFrameMixin:SetBlendSpeed(blendSpeed)
    self.blendSpeed = blendSpeed or SCROLL_BLEND_SPEED
end

function ScrollFrameMixin:SetUseOverlapBorder(useTop, useBottom)
    self.useTop = useTop;
    self.useBottom = useBottom;
    self:UpdateOverlapBorderVisibility();
end

function ScrollFrameMixin:UpdateOverlapBorderVisibility()
    self.borderTop:SetShown(self.useTop);
    self.borderBottom:SetShown(self.useBottom);
end

local function InitEasyScrollFrame(scrollFrame, borderTop, borderBottom)
    scrollFrame.value = 0;
    scrollFrame.range = 0;
    scrollFrame.borderTop = borderTop;
    scrollFrame.borderBottom = borderBottom;
    scrollFrame.blendSpeed = SCROLL_BLEND_SPEED;
    API.Mixin(scrollFrame, ScrollFrameMixin);
end
addon.InitEasyScrollFrame = InitEasyScrollFrame;