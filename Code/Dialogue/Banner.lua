local _, addon = ...

local Banner = CreateFrame("Frame");
Banner:Hide();
addon.Banner = Banner;

local outQuart = addon.EasingFunctions.outQuart;

function Banner:Init()
    -- Banner theme is always brown
    -- 3-Slice Background
    local pieces = {};
    local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/Banner-H-Brown.png";

    for i = 1, 3 do
        pieces[i] = self:CreateTexture(nil, "BACKGROUND");
        pieces[i]:SetTexture(file);
        pieces[i]:ClearAllPoints();
    end

    pieces[1]:SetSize(80, 160);     --Left
    pieces[3]:SetSize(80, 160);     --Right
    pieces[2]:SetSize(352, 160);    --Center

    pieces[1]:SetTexCoord(0, 80/512, 0, 160/256);
    pieces[2]:SetTexCoord(80/512, 430/512, 0, 160/256);
    pieces[3]:SetTexCoord(430/512, 1, 0, 160/256);

    pieces[1]:SetPoint("CENTER", self, "LEFT", 0, 0);
    pieces[3]:SetPoint("CENTER", self, "RIGHT", 0, 0);
    pieces[2]:SetPoint("TOPLEFT", pieces[1], "TOPRIGHT", 0, 0);
    pieces[2]:SetPoint("BOTTOMRIGHT", pieces[3], "BOTTOMLEFT", 0, 0);

    self.pieces = pieces;

    self.Text = self:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Paragraph");
    self.Text:SetJustifyH("CENTER");
    self.Text:SetJustifyV("MIDDLE");
    self.Text:SetPoint("CENTER", self, "CENTER", 0, 0);
    self.Text:SetWidth(400);    --maxwidth
    self.Text:SetSpacing(4);

    addon.ThemeUtil:SetFontColor(self.Text, "DarkBrown");

    local cornerSize = 42;
    self:SetCornerSize(cornerSize);

    self:SetFrameStrata("FULLSCREEN_DIALOG");

    self:SetScript("OnShow", self.OnShow);
    self:SetScript("OnHide", self.OnHide);
    self:SetScript("OnMouseDown", self.OnMouseDown);
    self:SetScript("OnEnter", self.OnEnter);
    self:SetScript("OnLeave", self.OnLeave);

    self.Init = nil;
end

function Banner:SetCornerSize(cornerSize)
    local height = 2 * cornerSize;
    self.pieces[1]:SetSize(cornerSize, height);
    self.pieces[3]:SetSize(cornerSize, height);
    self.minWidth = 512 / 80 * cornerSize;
    self.sidePadding = 112 / 80 * cornerSize;
    self:SetHeight(height);

    local shirnkH = 0;
    local shrinkV = 24 / 80 * cornerSize;
    self:SetHitRectInsets(shirnkH, shirnkH, shrinkV, shrinkV);
end

function Banner:Layout()
    local width = self.Text:GetWrappedWidth() + 2 * self.sidePadding;
    self:SetWidth(math.max(width, self.minWidth));
    self.frameWidth = width;

    local offsetY = WorldFrame:GetHeight() * 0.1;
    self.frameOffsetY = -offsetY;
    self.fromOffsetY = self.frameOffsetY - 40;

    self:ClearAllPoints();
    self:SetPoint("TOP", nil, "TOP", 0, self.frameOffsetY);
end

function Banner:OnMouseDown(button)
    if button == "RightButton" then
        self:Hide();
    end
end

function Banner:OnEnter()
    self.isMouseOver = true;
end

function Banner:OnLeave()
    self.isMouseOver = nil;
end


function Banner:OnShow()
    if self.onShowFunc then
        self.onShowFunc(self);
    end
end

function Banner:OnHide()
    self:Hide();
    self:SetScript("OnUpdate", nil);
    self.t = nil;
    self.autoFade = nil;
    self.isMouseOver = nil;
end


local function FadeOut_OnUpdate(self, elapsed)
    if ((self.t <= 0) and (not self.isMouseOver)) or self.t > 0 then
        self.t = self.t + elapsed;
    end

    if self.t > 0 then
        local alpha = 1 - 4 * self.t;
        if alpha <= 0 then
            alpha = 0;
            self:SetScript("OnUpdate", nil);
            self:Hide();
        end
        self:SetAlpha(alpha);
    end
end

local ANIM_DURATION = 0.5;
local function AnimIntro_FlyUp_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t < 0 then return end;  --delay

    local offsetY = outQuart(self.t, self.fromOffsetY, self.frameOffsetY, ANIM_DURATION);
    local alpha = 4*self.t;

    if alpha > 1 then
        alpha = 1;
    end

    if self.t >= ANIM_DURATION then
        offsetY = self.frameOffsetY;
        self:SetScript("OnUpdate", nil);

        if self.autoFade then
            self.t = -5;    --AutoFadeDelay
            self:SetScript("OnUpdate", FadeOut_OnUpdate);
        end
    end

    self:SetPoint("TOP", nil, "TOP", 0, offsetY);
    self:SetAlpha(alpha);
end


function Banner:DisplayMessage(msg, delay, autoFade)
    if self.Init then
        self:Init();
    end

    self.Text:SetText(msg);
    self:Layout();

    self:Show();
    self.t = (delay and -delay) or 0;
    self.autoFade = autoFade and true;
    self:SetScript("OnUpdate", AnimIntro_FlyUp_OnUpdate);
    self:SetAlpha(0);
end

function Banner:DisplayAutoFadeMessage(msg, delay)
    self:DisplayMessage(msg, delay, true);
end