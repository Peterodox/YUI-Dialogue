local _, addon = ...
local API = addon.API;

local SWIPE_START_THRESHOLD = 16;   --Distance Square
local GetCursorPosition = GetCursorPosition;


local SwpieEmulator = CreateFrame("Frame");
SwpieEmulator:Hide();

function SwpieEmulator:StopWatching()
    self:SetParent(nil);
    self:SetScript("OnUpdate", nil);
    self.t = nil;
    self.x, self.y = nil, nil;
    self.x0, self.y0 = nil, nil;
    self.delta = nil;
    self:UnregisterEvent("GLOBAL_MOUSE_UP");

    if self.owner then
        self.isMoving = nil;
        self.owner = nil;
    end
end

function SwpieEmulator:StartWatching(owner)
    self:SetParent(owner);
    self.owner = owner;

    if not owner:IsVisible() then
        self:StopWatching();
        return
    end

    self.x0, self.y0 = GetCursorPosition();
    self.t = 0;
    self:SetScript("OnUpdate", self.OnUpdate_PreDrag);
    self:RegisterEvent("GLOBAL_MOUSE_UP");
end

function SwpieEmulator:SetOwnerPosition()
    self.x , self.y = GetCursorPosition();
    self.x = (self.x - self.x0) / self.scale;
    self.y = (self.y - self.y0) / self.scale;
    self.owner:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.x + self.ownerX, self.y + self.ownerY);
end

function SwpieEmulator:OnUpdate_PreDrag(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.016 then
        self.t = 0;
        self.x , self.y = GetCursorPosition();
        self.delta = (self.x - self.x0)*(self.x - self.x0) + (self.y - self.y0)*(self.y - self.y0);
        if self.delta >= SWIPE_START_THRESHOLD then
            self.isMoving = true;
            self.scale = self.owner:GetEffectiveScale();
            self.x0, self.y0 = GetCursorPosition();
            self:SetScript("OnUpdate", self.OnUpdate_OnDrag);
        end
    end
end

function SwpieEmulator:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_UP" then
        self:StopWatching();
    end
end
SwpieEmulator:SetScript("OnEvent", SwpieEmulator.OnEvent);

function SwpieEmulator:OnHide()
    self:Hide();
    self:StopWatching();
end
SwpieEmulator:SetScript("OnHide", SwpieEmulator.OnHide);