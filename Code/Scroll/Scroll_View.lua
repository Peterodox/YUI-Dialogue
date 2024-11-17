local _, addon = ...
local API = addon.API;
local Clamp = API.Clamp;

local pairs = pairs;
local tinsert = table.insert;


local ScrollViewMixin = {};

function ScrollViewMixin:GetDataIndexBegin()
	return self.dataIndexBegin or 0;
end
function ScrollViewMixin:GetDataIndexEnd()
	return self.dataIndexEnd or 0;
end
function ScrollViewMixin:GetDataRange()
	return self.dataIndexBegin, self.dataIndexEnd;
end
function ScrollViewMixin:SetDataRange(dataIndexBegin, dataIndexEnd)
	self.dataIndexBegin = dataIndexBegin;
	self.dataIndexEnd = dataIndexEnd;
end

function ScrollViewMixin:GetScrollOffset()
    return self.scrollOffset or 0;
end

function ScrollViewMixin:SetAllowNegativeScrollRange(state)
    self.allowNegativeScrollRange = state;
end

function ScrollViewMixin:SetScrollRange(maxScrollOffset)
    if (not self.allowNegativeScrollRange) and maxScrollOffset < 0 then
        maxScrollOffset = 0;
    end

    self.maxScrollOffset = maxScrollOffset;
end

function ScrollViewMixin:GetScrollRange()
    return self.maxScrollOffset or 0
end

function ScrollViewMixin:IsScrollable()
    return self:GetScrollRange() > 0
end

function ScrollViewMixin:IsAtBottom()
    return self:GetScrollOffset() + 0.1 >= self:GetScrollRange();
end

function ScrollViewMixin:ScrollBy(offset)
    self:SetScrollOffset( self:GetScrollOffset() + offset);
end

function ScrollViewMixin:ScrollToTop()
    self:SetScrollOffset(0);
end

function ScrollViewMixin:ScrollToBottom()
    self:SetScrollOffset(self:GetScrollRange());
end

function ScrollViewMixin:GetViewSize()
    return self.viewSize or 0
end

function ScrollViewMixin:OnSizeChanged()
    self.viewSize = self:GetHeight();
end

function ScrollViewMixin:SetSpacing(spacing)
    self.spacing = spacing;
end

function ScrollViewMixin:GetExtent()
    return self.dataProvider:GetExtent()
end

function ScrollViewMixin:GetMaxDataIndex()
    return self.dataProvider:GetMaxDataIndex();
end

function ScrollViewMixin:CreateObject()
    return self.dataProvider:CreateObject();
end

function ScrollViewMixin:SetObjectData(object, dataIndex)
    return self.dataProvider:SetObjectData(object, dataIndex);
end

function ScrollViewMixin:GetMaxExtent()
    return self.dataProvider and self.dataProvider:GetMaxExtent() or 0
end

function ScrollViewMixin:UpdateScrollRange()
    self:SetScrollRange(self:GetMaxExtent() - self:GetViewSize());
end

function ScrollViewMixin:OnContentChanged(updateWhenAtBottom)
    local instantUpdate = (not updateWhenAtBottom) or (self:IsAtBottom());
    self:UpdateScrollRange();

    if instantUpdate then
        self.scrollOffset = self:GetScrollRange();
        self:UpdateView();
        self.dataProvider:OnViewUpdated();
    else
        --blip

    end

    if self.scrollBar then
        self.scrollBar:UpdateThumbSize();
        if instantUpdate then
            self.scrollBar:UpdateThumbPosition();
        else
            self.scrollBar:SetHasNewMessage();
        end
    end
end

function ScrollViewMixin:SetDataProvider(dataProvider)
    self.dataProvider = dataProvider;
    dataProvider.owner = self;
    self:SetSpacing(dataProvider:GetSpacing());
    self:SetScrollRange(dataProvider:GetMaxExtent() - self:GetViewSize());
    self:SetStep(dataProvider:GetStep());
    self:SetDataRange(0, 0);
    self.scrollOffset = 0;
    self:UpdateView();
end

function ScrollViewMixin:SetScrollBar(scrollBar)
    if self.scrollBar then
        self.scrollBar:Detach();
    end
    self.scrollBar = scrollBar;
    scrollBar:SetOwner(self);
end

function ScrollViewMixin:SetScrollOffset(scrollOffset)
    scrollOffset = Clamp(scrollOffset, 0, self.maxScrollOffset);

    self.scrollOffset = scrollOffset;

    if self.hasContent and (scrollOffset < self.viewScrollBegin or scrollOffset > self.viewScrollEnd) then
        self:UpdateView();
    end

    if self.activeObjects then
        for object in pairs(self.activeObjects) do
            self:SetObjectPositionByScrollOffset(object, scrollOffset);
        end
    end

    if self.scrollBar then
        self.scrollBar:UpdateThumbPosition();
    end
end

function ScrollViewMixin:SetObjectPositionByScrollOffset(object, scrollOffset)
    object:SetPoint("TOPLEFT", self, "TOPLEFT", 0, scrollOffset - object.fromOffset);
end

function ScrollViewMixin:SetStep(step)
    self.step = step;
end

function ScrollViewMixin:OnMouseWheel(delta)
    if delta > 0 then
        if self.scrollOffset > 0 then
            local scrollTarget = self.scrollOffset - self.step;
            if scrollTarget < 0 then
                scrollTarget = 0;
            end
            self:SetScrollOffset(scrollTarget);
        end
    else
        if self.scrollOffset < self.maxScrollOffset then
            local scrollTarget = self.scrollOffset + self.step;
            if scrollTarget > self.maxScrollOffset then
                scrollTarget = self.maxScrollOffset;
            end
            self:SetScrollOffset(scrollTarget);
        end
    end

    if self.parent and self.parent.OnMouseWheelCallback then
        self.parent:OnMouseWheelCallback(delta);
    end
end

function ScrollViewMixin:UpdateView(forceUpdate)
    local offset = self:GetScrollOffset();
    local viewSize = self:GetViewSize();
    local viewEnd = offset + viewSize;
    local oldIndexBegin, oldIndexEnd = self:GetDataRange();
    local extent = self:GetExtent();
    local maxDataIndex = self:GetMaxDataIndex();

    local newIndexBegin = oldIndexBegin;
    local newIndexEnd;

    if oldIndexBegin > 0 and offset < extent[oldIndexBegin] then
        while newIndexBegin > 1 and offset < extent[newIndexBegin] do
            newIndexBegin = newIndexBegin - 1;
        end
    else
        while newIndexBegin < maxDataIndex and offset > extent[newIndexBegin + 1] do
            newIndexBegin = newIndexBegin + 1;
        end
    end

    newIndexEnd = newIndexBegin;
    while newIndexEnd < maxDataIndex and viewEnd > extent[newIndexEnd + 1] do
        newIndexEnd = newIndexEnd + 1;
    end

    newIndexBegin = Clamp(newIndexBegin, 0, maxDataIndex);
    newIndexEnd = Clamp(newIndexEnd, 0, maxDataIndex);

    if (newIndexBegin ~= oldIndexBegin) or (newIndexEnd ~= oldIndexEnd) or forceUpdate then
        --print("RANGE", newIndexBegin, newIndexEnd)
        self:SetDataRange(newIndexBegin, newIndexEnd);

        self.viewScrollBegin = extent[newIndexBegin + 1];
        self.viewScrollEnd = extent[newIndexEnd] - viewSize;
        self.hasContent = true;

        local recycledObjects = {};
        local numUnused = 0;
        local dataObjects = {};

        if not self.objectPool then
            self.objectPool = {};
            self.activeObjects = {};
        end

        for object, index in pairs(self.activeObjects) do
            dataObjects[index] = object;
            if not (index >= newIndexBegin and index <= newIndexEnd) then
                numUnused = numUnused + 1;
                recycledObjects[numUnused] = object;
                object:Hide();
                object:ClearAllPoints();
            end
        end

        local object;

        for index = newIndexBegin, newIndexEnd do
            if dataObjects[index] then
                object = dataObjects[index];
            elseif numUnused > 0 then
                object = recycledObjects[numUnused];
                numUnused = numUnused - 1;
            else
                object = self:CreateObject();
                tinsert(self.objectPool, object);
                --print("Created. Total:", #self.objectPool);
            end

            self.activeObjects[object] = index;
            if self:SetObjectData(object, index) then
                object:Show();
            end
            object:ClearAllPoints();
            object.fromOffset = extent[index];
            self:SetObjectPositionByScrollOffset(object, offset);
        end
    end
end

function ScrollViewMixin:OnShow()
    if self.dataProvider then
        self.dataProvider:OnShow(self);
    end
end

function ScrollViewMixin:OnHide()
    if self.dataProvider then
        self.dataProvider:OnHide(self);
    end
end

function ScrollViewMixin:IsDraggingThumb()
    return self.scrollBar and self.scrollBar:IsDraggingThumb()
end

function ScrollViewMixin:OnCullingComplete(numCulled)
    self:SetDataRange(-1, -1);
    if self.activeObjects then
        for object, index in pairs(self.activeObjects) do
            if object.dataIndex then
                self.activeObjects[object] = object.dataIndex - numCulled;
            end
            object:Hide();
            object:ClearAllPoints();
            object.dataIndex = nil;
        end
    end
    self:UpdateView(true);
end

local function CreateScrollView(parent)
    local f = CreateFrame("Frame", nil, parent);
    f.parent = parent;

    API.Mixin(f, ScrollViewMixin);

    f:SetScript("OnSizeChanged", f.OnSizeChanged);
    f:SetScript("OnMouseWheel", f.OnMouseWheel);
    f:SetScript("OnShow", f.OnShow);
    f:SetScript("OnHide", f.OnHide);

    f:SetClipsChildren(true);

    return f
end
addon.CreateScrollView = CreateScrollView;



--[[
local ScrollViewDataProvider = {};

function ScrollViewDataProvider:GetSpacing()

end

function ScrollViewDataProvider:CalculateExtent()

end

function ScrollViewDataProvider:GetExtent()

end

function ScrollViewDataProvider:GetMaxDataIndex()

end

function ScrollViewDataProvider:CreateObject()

end

function ScrollViewDataProvider:SetObjectData()

end

function ScrollViewDataProvider:OnShow(scrollView)

end

function ScrollViewDataProvider:OnHide(scrollView)

end

function ScrollViewDataProvider:OnViewUpdated()

end
-]]