-- Mostly for touchscreen devices:
-- Emulate Swipe on DialogueUI using GLOBAL_MOUSE_DOWN/UP


local _, addon = ...
local API = addon.API;

local GetCursorPosition = GetCursorPosition;
local EMULATE_SWIPE = true;


local SWIPE_SPEED_SAMPLE_T = 2/60;
local SWIPE_START_THRESHOLD = 25;   --Distance Square
local RUBBERBAND_MAX_OFFSET = 64;
local RUBBERBAND_STRENGH = 0.5;

local function CalculateOffset(offset, range)
    if offset > 0 and offset < range then
        return offset
    end

    if offset < 0 then
        return  0 -((1 - (1 / (((0 - offset) * RUBBERBAND_STRENGH / RUBBERBAND_MAX_OFFSET) + 1))) * RUBBERBAND_MAX_OFFSET)
    elseif offset > range then
        return  range + ((1 - (1 / (((offset - range) * RUBBERBAND_STRENGH / RUBBERBAND_MAX_OFFSET) + 1))) * RUBBERBAND_MAX_OFFSET)
    end
end

local SwipeEmulator = CreateFrame("Frame");
SwipeEmulator:Hide();
addon.SwipeEmulator = SwipeEmulator;

local ClickBlocker = CreateFrame("Frame");
do  --Consume the Click if we just finished Swiping
    --Shouldn't affect "Click" from pressing hotkey
    ClickBlocker.isLocked = false;

    function ClickBlocker:Enable()
        self.isLocked = true;
        self:SetScript("OnUpdate", nil);
    end

    function ClickBlocker:IsEnabled()
        return self.isLocked
    end

    function ClickBlocker:Release(instantly)
        if self.isLocked then
            self.t = 0;
            if instantly then
                self.isLocked = false;
            else
                self:SetScript("OnUpdate", self.OnUpdate_Release);
            end
        end
    end

    function ClickBlocker:OnUpdate_Release(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.03 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            self.isLocked = false;
        end
    end


    function SwipeEmulator:ShouldConsumeClick()
        return ClickBlocker.isLocked
    end
end

do
    function SwipeEmulator:StopWatching(caller)
        if caller and self.owner and caller ~= self.owner then
            return
        end

        self:SetScript("OnUpdate", nil);
        if not self.t then return end;

        self.t = nil;
        self._x = nil;
        self.y = nil;
        self.y0 = nil;
        self.newY = nil;
        self.delta = nil;
        ClickBlocker:Release();

        if self.isDragging then
            if self.owner:IsVisible() then
                self:PostDragging();
            end
        end

        self.isDragging = nil;
    end

    function SwipeEmulator:StartWatching()
        if not self.owner:IsVisible() then
            self:StopWatching();
            return
        end

        self._x, self.y0 = GetCursorPosition();
        self.t = 0;
        self.isDragging = false;
        self.sampleSpeed = nil;
        self:SetScript("OnUpdate", self.OnUpdate_PreDrag);
        self:Show();
    end

    function SwipeEmulator:StartDragging()
        self.isDragging = true;
        self.scale = self.owner:GetEffectiveScale();
        self._x, self.y0 = GetCursorPosition();
        self._x, self.y = GetCursorPosition();
        self.range = self.owner.range or 0;
        self.fromY = self.owner:GetVerticalScroll();
        self.sampleT = 0;
        self.lastSampledY = self.y0;
        self.sampleSpeed = 0;
        self:SetScript("OnUpdate", self.OnUpdate_OnDrag);
        ClickBlocker:Enable();
    end

    function SwipeEmulator:SetOwnerOffset(offset)
        --self.owner:SetOffset(offset);
        --self.owner.scrollTarget = offset;
        --self.owner.value = offset;
        self.owner:SnapTo(offset, true);
    end

    function SwipeEmulator:HandleDrag()
        self._x , self.newY = GetCursorPosition();
        self.dy = self.newY - self.y;
        self.y = self.newY;

        if self.sampleT > SWIPE_SPEED_SAMPLE_T then --SampleWindow 3 frames (60fps)
            self.sampleSpeed = (self.newY - (self.lastSampledY or self.newY)) / self.sampleT;
            self.lastSampledY = self.newY;
            self.sampleT = 0;
        end

        self.offset = self.owner:GetVerticalScroll() + self.dy;
        if self.offset < 0 then
            if self.dy > 0 then

            else
                self.offset = self.fromY + self.newY - self.y0;
                self.offset = CalculateOffset(self.offset, self.range);
            end
        elseif self.offset > self.range then
            if self.dy < 0 then

            else
                self.offset = self.fromY + self.newY - self.y0;
                self.offset = CalculateOffset(self.offset, self.range);
            end
        else
            self.fromY = self.offset;
            self.y0 = self.newY;
        end

        self:SetOwnerOffset(self.offset);
    end

    function SwipeEmulator:PostDragging()
        --Reset to scroll bound if needed
        if self.owner.value < 0 then
            self.owner:ScrollTo(0);
        elseif self.owner.range and self.owner.value > self.owner.range then
            self.owner:ScrollTo(self.owner.range);
        elseif self.sampleSpeed and self.sampleSpeed ~= 0 then
            --Handle Inertia
            local effectiveSpeed = self.sampleSpeed / 4;
            if effectiveSpeed > 2 or effectiveSpeed < -2 then
                if self:IsVisible() then
                    --print(effectiveSpeed)
                    effectiveSpeed = API.Clamp(effectiveSpeed, -640, 640);
                    self.speed = effectiveSpeed;
                    self.accDirection = (effectiveSpeed > 0 and -1) or 1;
                    self.range = self.owner.range or 0;
                    self.supposedOffset = self.owner:GetVerticalScroll();
                    self:SetScript("OnUpdate", self.OnUpdate_Inertia);
                end
            end
        end
    end

    function SwipeEmulator:OnUpdate_OnDrag(elapsed)
        self.t = self.t + elapsed;
        self.sampleT = self.sampleT + elapsed;
        if self.t > 0.008 then
            self.t = 0;
            self:HandleDrag();
        end
    end

    function SwipeEmulator:OnUpdate_PreDrag(elapsed)
        self.t = self.t + elapsed;

        if self.t > 0.016 then
            self.t = 0;
            self._x , self.y = GetCursorPosition();
            self.delta = (self.y - self.y0)*(self.y - self.y0);
            if self.delta >= SWIPE_START_THRESHOLD then
                self:StartDragging();
            end
        end
    end

    function SwipeEmulator:OnUpdate_Inertia(elapsed)
        self.speed = self.speed + 320 * self.accDirection * elapsed;

        if self.accDirection < 0 and self.speed <= 0 then
            self:SetScript("OnUpdate", nil);
        elseif self.accDirection > 0 and self.speed >= 0 then
            self:SetScript("OnUpdate", nil);
        end

        local newOffset = self.owner:GetVerticalScroll() + self.speed * elapsed;
        self.supposedOffset = self.supposedOffset + self.speed * elapsed;

        local offet = self.supposedOffset;
        if offet < 0 then
            newOffset = CalculateOffset(offet, self.range);
            self.offsetDelta = newOffset  - self.owner:GetVerticalScroll();
            if (self.offsetDelta < 1 and self.offsetDelta > -1) then
                self:SetScript("OnUpdate", nil);
                self.owner:ScrollTo(0);
                return
            end
        elseif offet > self.range then
            newOffset = CalculateOffset(offet, self.range);
            self.offsetDelta = newOffset  - self.owner:GetVerticalScroll();
            if (self.offsetDelta < 1 and self.offsetDelta > -1) then
                self:SetScript("OnUpdate", nil);
                self.owner:ScrollTo(self.owner.range);
                return
            end
        else
            newOffset = offet;
            self.offsetDelta = self.speed * elapsed;
        end

        self:SetOwnerOffset(newOffset);
    end

    function SwipeEmulator:OnEvent(event, button)
        if event == "GLOBAL_MOUSE_DOWN" then
            if button == "LeftButton" and self.owner:IsMouseOver() then
                self:StartWatching();
            end
        elseif event == "GLOBAL_MOUSE_UP" then
            self:StopWatching();
        end
    end
    SwipeEmulator:SetScript("OnEvent", SwipeEmulator.OnEvent);

    function SwipeEmulator:OnHide()
        self:Hide();
        self:StopWatching();
        if self.scrollable then
            self:SetScrollable(false);
        end
    end
    SwipeEmulator:SetScript("OnHide", SwipeEmulator.OnHide);

    function SwipeEmulator:SetOwner(owner)
        --In our case owner is DialogueUI.ScrollFrame
        self.owner = owner;
        self:SetParent(owner);
    end

    function SwipeEmulator:SetScrollable(scrollable, caller)
        self.scrollable = scrollable;
        if scrollable and EMULATE_SWIPE and caller == self.owner then
            self:RegisterEvent("GLOBAL_MOUSE_DOWN");
            self:RegisterEvent("GLOBAL_MOUSE_UP");
            self:SetScript("OnUpdate", nil);
        else
            self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
            self:UnregisterEvent("GLOBAL_MOUSE_UP");
            self:StopWatching();
            ClickBlocker:Release(true);
        end
    end

    local function Settings_EmulateSwipe(dbValue)
        EMULATE_SWIPE = dbValue == true;
        if EMULATE_SWIPE then
            if SwipeEmulator.owner and SwipeEmulator.owner:IsScrollable() then
                SwipeEmulator:SetScrollable(true, SwipeEmulator.owner)
            end
        else
            if SwipeEmulator.scrollable then
                SwipeEmulator:OnHide();
            end
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.EmulateSwipe", Settings_EmulateSwipe);
end