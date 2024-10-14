-- Create a simple smooth scroll frame

local _, addon = ...
local API = addon.API;
local DeltaLerp = API.DeltaLerp;
local Clamp = API.Clamp;
local SCROLL_BLEND_SPEED = 0.15;    --0.2


local ScrollFrameMixin = {};
do
    function ScrollFrameMixin:OnUpdate_Easing(elapsed)
        self.value = DeltaLerp(self.value, self.scrollTarget, self.blendSpeed, elapsed);

        if (self.value - self.scrollTarget) > -0.4 and (self.value - self.scrollTarget) < 0.4 then
            --print("complete")
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

            if self.isRecyclable then
                --self:DebugGetCount();
                self.recycleTimer = -1;
                self:UpdateView(true);
            end

            if self.usePagination then
                self.paginationTimer = 1;
            end

            if self.onScrollFinishedCallback then
                self.onScrollFinishedCallback();
            end
        end

        if self.isRecyclable then
            self.recycleTimer = self.recycleTimer + elapsed;
            if self.recycleTimer > 0.033 then
                self.recycleTimer = 0;
                self:UpdateView();
            end
        end

        if self.usePagination then
            self.paginationTimer = self.paginationTimer + elapsed;
            if self.paginationTimer > 0.2 then
                self.paginationTimer = 0;
                self:UpdatePagination();
            end
        end

        self:SetOffset(self.value);
    end

    function ScrollFrameMixin:OnUpdate_SteadyScroll(elapsed)
        self.value = self.value + self.scrollSpeed * elapsed;
        if self.value < 0 then
            self.value = 0;
            self.isSteadyScrolling = nil;
        elseif self.value > self.range then
            self.value = self.range;
            self.isSteadyScrolling = nil;
        elseif self.scrollSpeed < 4 and self.scrollSpeed > -4 then
            self.isSteadyScrolling = nil;
        else
            self.isSteadyScrolling = true;
        end
        self.scrollTarget = self.value;

        if not self.isSteadyScrolling then
            self:SetScript("OnUpdate", nil);

            if self.isRecyclable then
                self.recycleTimer = -1;
                self:UpdateView(true);
            end

            if self.usePagination then
                self.paginationTimer = 1;
            end

            if self.onScrollFinishedCallback then
                self.onScrollFinishedCallback();
            end
        end

        if self.isRecyclable then
            self.recycleTimer = self.recycleTimer + elapsed;
            if self.recycleTimer > 0.033 then
                self.recycleTimer = 0;
                self:UpdateView();
            end
        end

        if self.usePagination then
            self.paginationTimer = self.paginationTimer + elapsed;
            if self.paginationTimer > 0.2 then
                self.paginationTimer = 0;
                self:UpdatePagination();
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

    function ScrollFrameMixin:SnapTo(value, ignoreRange)
        if not ignoreRange then
            value = Clamp(value, 0, self.range);
        end

        self:SetScript("OnUpdate", nil);
        self:SetOffset(value);
        self.scrollTarget = value;
        self.isSteadyScrolling = nil;

        if self.isRecyclable then
            self:UpdateView(true);
        end

        if self.usePagination then
            self:UpdatePagination();
        end
    end

    function ScrollFrameMixin:ResetScroll()
        self:SnapTo(0);
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

    function ScrollFrameMixin:GetScrollRange()
        return self.range or self:GetVerticalScrollRange()
    end

    function ScrollFrameMixin:IsScrollable()
        return self:GetScrollRange() > 0
    end

    function ScrollFrameMixin:ScrollTo(value)
        value = Clamp(value, 0, self.range);
        self.isSteadyScrolling = nil;
        if value ~= self.scrollTarget then
            self.scrollTarget = value;
            self:SetScript("OnUpdate", self.OnUpdate_Easing);
            self.recycleTimer = 0;
            self.paginationTimer = 0;
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

    function ScrollFrameMixin:SteadyScroll(strengh)
        --For Joystick: strengh -1 ~ +1

        if strengh > 0.8 then
            self.scrollSpeed = 80 + 600 * (strengh - 0.8);
        elseif strengh < -0.8 then
            self.scrollSpeed = -80 + 600 * (strengh + 0.8);
        else
            self.scrollSpeed = 100 * strengh
        end

        if not self.isSteadyScrolling then
            self.recycleTimer = 0;
            self.paginationTimer = 0;
            self:SetScript("OnUpdate", self.OnUpdate_SteadyScroll);
        end
    end

    function ScrollFrameMixin:IsAtPageTop()
        --local offset = self:GetVerticalScroll();
        return self.value <= 0.1
    end

    function ScrollFrameMixin:IsAtPageBottom()
        --local offset = self:GetVerticalScroll();
        return self.value + 0.1 >= (self.range or 0)
    end

    function ScrollFrameMixin:SetBlendSpeed(blendSpeed)
        self.blendSpeed = blendSpeed or SCROLL_BLEND_SPEED;
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

    function ScrollFrameMixin:OnHide()
        self:SetScript("OnUpdate", nil);
        self.isSteadyScrolling = nil;
        if self.scrollTarget and self.scrollTarget ~= self.value then
            self:SnapTo(self.scrollTarget);
        end
    end
end

local function InitEasyScrollFrame(scrollFrame, borderTop, borderBottom)
    scrollFrame.value = 0;
    scrollFrame.range = 0;
    scrollFrame.borderTop = borderTop;
    scrollFrame.borderBottom = borderBottom;
    scrollFrame.blendSpeed = SCROLL_BLEND_SPEED;
    API.Mixin(scrollFrame, ScrollFrameMixin);
    scrollFrame:SetScript("OnHide", scrollFrame.OnHide);
    return scrollFrame
end
addon.InitEasyScrollFrame = InitEasyScrollFrame;


--Recyclable Content ScrollFrame
do
    local ipairs = ipairs;

    local RecyclableFrameMixin = {};

    function RecyclableFrameMixin:GetViewSize()
        return self:GetHeight()
    end

    function RecyclableFrameMixin:SetContent(content)
        --Content = {
        --    [index] = {
        --        offset =  offsetY
        --        otherData...
        --    },
        --}

        self.content = content;

        --Objects are released from a different path
        self.bins = {};
        self.contentIndexObject = {};
    end

    function RecyclableFrameMixin:ClearContent()
        self.content = nil;
        self.bins = nil;
        self.contentIndexObject = nil;
    end

    function RecyclableFrameMixin:AcquireAndSetData(data, contentIndex)
        local type = self:GetDataRequiredObjectType(data);
        local obj;

        if self.bins[type] and self.bins[type].count > 0 then
            local b = self.bins[type];
            obj = b[b.count];
            b[b.count] = nil;
            b.count = b.count - 1;
        end

        return self:SetObjectData(obj, data, contentIndex);
    end

    function RecyclableFrameMixin:RecycleObject(contentIndex)
        local obj = self.contentIndexObject[contentIndex];

        obj:Hide();
        obj:ClearAllPoints();

        local type = obj:GetObjectType();
        local b = self.bins[type];
        if not b then
            b = {
                count = 0,
            };
            self.bins[type] = b;
        end

        b.count = b.count + 1;
        b[b.count] = obj;
        self.contentIndexObject[contentIndex] = nil;
    end

    function RecyclableFrameMixin:UpdateView(useScrollTarget)
        local viewSize = self:GetViewSize();
        local fromOffset;
        if useScrollTarget then
            fromOffset = self:GetScrollTarget();
        else
            fromOffset = self:GetVerticalScroll();
        end
        local toOffset = fromOffset + viewSize;

        for contentIndex, data in ipairs(self.content) do
            if (data.offsetY <= fromOffset and data.endingOffsetY >= fromOffset) or (data.offsetY >= fromOffset and data.endingOffsetY <= toOffset) or (data.offsetY <= toOffset and data.endingOffsetY >= toOffset) then
                --In range
                if not self.contentIndexObject[contentIndex] then
                    self.contentIndexObject[contentIndex] = self:AcquireAndSetData(data, contentIndex);
                end
            else
                --Outside range
                if self.contentIndexObject[contentIndex] then
                    self:RecycleObject(contentIndex);
                end
            end
        end
    end

    function RecyclableFrameMixin:SetUsePagination(usePagination)
        self.usePagination = usePagination;
    end

    function RecyclableFrameMixin:DebugGetCount()
        local active = 0;
        local unused = 0;

        for contentIndex, obj in pairs(self.contentIndexObject) do
            active = active + 1;
        end

        for type, bin in pairs(self.bins) do
            for _, obj in pairs(bin) do
                unused = unused + 1;
            end
        end

        print("Active:", active, " Unused:", unused)
    end


    --Overridden by Owner
    function RecyclableFrameMixin:SetObjectData(object, data, contentIndex)
        --Override
        --Return object
    end

    function RecyclableFrameMixin:GetDataRequiredObjectType(data)

    end

    function RecyclableFrameMixin:UpdatePagination()
        --Override
    end
    ----


    local function InitRecyclableScrollFrame(scrollFrame)
        API.Mixin(scrollFrame, RecyclableFrameMixin);
        scrollFrame.isRecyclable = true;
    end
    addon.InitRecyclableScrollFrame = InitRecyclableScrollFrame;
end